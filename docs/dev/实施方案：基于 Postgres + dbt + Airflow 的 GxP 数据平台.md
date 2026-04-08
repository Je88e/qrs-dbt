本文档为早期草案，示例中包含明文密钥、host network、直接暴露 docker.sock、以及 snapshot 增量口径混用等不适合直接生产落地的内容。

生产可落地版本请参考：

- [实施方案：基于 Postgres + dbt + Airflow 的 GxP 数据平台（优化版）.md](file:///mnt/d/Work/NovaTech/QRS/dbt/docs/dev/实施方案：基于%20Postgres%20+%20dbt%20+%20Airflow%20的%20GxP%20数据平台（优化版）.md)

## 1. 系统架构与流程图 (Mermaid)

该图表明确了 **CI/CD 构建域**（左侧）与 **生产运行域**（右侧）的边界，以及 Airflow 内部的子工作流逻辑。

```mermaid
graph TD
    %% ================= CI/CD 域 =================
    subgraph CI_CD_Pipeline [CI/CD Pipeline Build & Validate]
        direction TB
        Code_Commit[Git Commit / Tag] --> Unit_Test{Unit Tests<br/> pytest + dbt test}
        Unit_Test -- Pass --> Build_Image[Build Task Image<br/>Contains dbt + Python]
        Build_Image --> Sign_Image[Sign Image GxP]
        Sign_Image --> Push_Reg[Push to Registry<br/>Tag: v1.0.1]
    end

    %% ================= 生产运行域 =================
    subgraph Production_Environment [Production Host Docker Compose]
        
        %% 组件层
        subgraph Services
            AF[Airflow Scheduler]
            AB[Airbyte Server]
            PG[(Postgres DWH)]
        end

        %% Airflow 工作流逻辑
        subgraph Airflow_DAG [Airflow DAG: Daily_ETL]
            direction TB
            
            %% Step 1: Ingestion
            Start((Start)) --> Trigger_AB[Op: Trigger Airbyte Job]
            Trigger_AB --> Wait_AB{Sensor: Wait for Completion}
            
            %% Step 2: Transformation (DockerOperator)
            Wait_AB --> Run_dbt[Op: dbt Build<br/>Task Image v1.0.1]
            
            %% Step 3: Science Compute (DockerOperator)
            Run_dbt --> Run_Py[Op: Python Calc<br/>Task Image v1.0.1]
            
            %% 子流程细节
            subgraph Py_Logic [Python Execution Logic]
                P1[Read Audit Log<br/>Get High Watermark] --> P2[Fetch Incremental Data]
                P2 --> P3[Scientific Compute]
                P3 --> P4[Write Result + Audit Log]
            end
            
            Run_Py -.-> Py_Logic
        end
    end

    %% 交互连线
    Push_Reg -->|Pull Image| Run_dbt
    Push_Reg -->|Pull Image| Run_Py
    Trigger_AB -.->|API Call / HTTP| AB
    AB ==>|Write Raw Data| PG
    Run_dbt ==>|SQL Transform| PG
    Run_Py ==>|Read/Write| PG
```

---

## 2. 核心组件交互与对接方式

### 2.1. Airflow 与 Airbyte 的对接 (主动触发模式)

使用 Airflow 的 **`AirbyteTriggerSyncOperator`** 通过 API 主动触发 Airbyte。

- **交互机制**：Airflow 通过 HTTP API (`POST /v1/connections/sync`) 调用 Airbyte Server。
    
- **连接方式**：在 Airflow Connection UI 中配置 `airbyte_conn_id`，填入 Airbyte Server 的地址（如 `http://airbyte-server:8001`）。
    

### 2.2. Airflow 与 业务逻辑（dbt/Python）的对接

采用 **Docker-in-Docker (DinD)** 或 **Docker Socket Binding** 模式。

- **交互机制**：Airflow Worker 节点调用宿主机的 Docker Engine，启动我们在 CI/CD 阶段构建好的 **Task Image**。
    
- **优势**：Airflow 仅仅是调度器，不包含任何业务依赖。业务环境完全隔离在 Task Image 中。
    

---

## 3. 关键软件步骤与代码实现

### 3.1. 统一任务镜像 (Task Image) 构建

这是 GxP 合规的核心——**“不可变镜像”**。所有的 dbt 模型和 Python 算法都打包在此。

**文件结构：**

Plaintext

```
/repo
  ├── dbt_project/       # dbt 代码
  ├── python_app/        # Python 算法代码
  ├── requirements.txt   # Python 依赖
  └── Dockerfile         # 构建文件
```

**Dockerfile 实现：**

```Dockerfile
# 基础镜像：官方 Python 3.9 Slim
FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 1. 安装系统依赖 (如 git, libpq)
RUN apt-get update && apt-get install -y libpq-dev git && rm -rf /var/lib/apt/lists/*

# 2. 安装 Python 依赖 (dbt-postgres, pandas, sqlalchemy)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 3. 复制 dbt 项目
COPY dbt_project/ ./dbt_project/
# 预安装 dbt 依赖 (避免运行时联网)
RUN cd dbt_project && dbt deps

# 4. 复制 Python 算法代码
COPY python_app/ ./python_app/

# 设置环境变量 (关闭 dbt 匿名统计)
ENV DBT_PROFILES_DIR=/app/dbt_project
ENV DBT_SEND_ANONYMOUS_USAGE_STATS=false

# 默认入口 (可被 Airflow 覆盖)
CMD ["bash"]
```

### 3.2. Airflow DAG 实现 (调度逻辑)

此代码展示了如何串联 Airbyte、dbt 和 Python。

```python
from airflow import DAG
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.docker.operators.docker import DockerOperator
from airflow.utils.dates import days_ago

# 配置常量
AIRBYTE_CONNECTION_ID = "your-uuid-string-here"
# 注意：在 Docker Compose 网络中，Airflow 需访问宿主机 Docker Socket
TASK_IMAGE = "my-registry/gxp-task-image:v1.0.1" 

default_args = {
    'owner': 'data-team',
    'retries': 1,
}

with DAG(
    dag_id='gxp_daily_pipeline',
    default_args=default_args,
    schedule_interval='@daily',
    start_date=days_ago(1),
    catchup=False
) as dag:

    # Step 1: 触发 Airbyte Sync (通过 API)
    trigger_airbyte = AirbyteTriggerSyncOperator(
        task_id='trigger_airbyte_sync',
        airbyte_conn_id='airbyte_default', # 在 Airflow UI 中配置
        connection_id=AIRBYTE_CONNECTION_ID,
        asynchronous=False, # True=异步, False=等待同步完成
        timeout=3600,
        wait_seconds=3
    )

    # Step 2: 运行 dbt (运行在 Task Container 中)
    run_dbt = DockerOperator(
        task_id='dbt_build',
        image=TASK_IMAGE,
        api_version='auto',
        auto_remove=True,
        command="bash -c 'cd dbt_project && dbt build --target prod'",
        docker_url="unix://var/run/docker.sock",
        network_mode="host", # 或使用 docker-compose 网络名
        environment={
            "DBT_HOST": "postgres-db", # 传入 DB 连接信息
            "DBT_USER": "dbt_user",
            "DBT_PASSWORD": "secure_password"
        },
        mount_tmp_dir=False
    )

    # Step 3: 运行 Python 科学计算 (运行在 Task Container 中)
    run_python_science = DockerOperator(
        task_id='python_science_compute',
        image=TASK_IMAGE,
        api_version='auto',
        auto_remove=True,
        # 传入 Airflow 的 execution_date 作为运行 ID 
        command="python /app/python_app/main.py --run_id {{ run_id }}", 
        docker_url="unix://var/run/docker.sock",
        network_mode="host",
        environment={
            "DB_CONN_STR": "postgresql://user:pass@postgres-db:5432/dwh"
        },
        mount_tmp_dir=False
    )

    # 依赖关系
    trigger_airbyte >> run_dbt >> run_python_science
```

### 3.3. Python 增量计算与审计实现 (main.py)

这是实现 **Audit Log** 和 **增量识别** 的关键代码。

```python
import pandas as pd
import sqlalchemy
from datetime import datetime
import argparse

# 数据库连接
engine = sqlalchemy.create_engine("postgresql://user:pass@postgres-db:5432/dwh")

def get_high_watermark():
    """获取上一次成功运行处理到的最大时间戳"""
    query = """
    SELECT MAX(high_watermark_ts) 
    FROM audit.science_execution_log 
    WHERE status = 'SUCCESS'
    """
    with engine.connect() as conn:
        result = conn.execute(sqlalchemy.text(query)).scalar()
    # 如果是第一次运行，返回一个很久以前的时间
    return result if result else datetime(1970, 1, 1)

def run_science_calculation(run_id):
    # 1. 获取水位线
    last_processed_ts = get_high_watermark()
    print(f"Starting run {run_id}. Incremental mode since: {last_processed_ts}")

    # 2. 读取增量数据 (利用 dbt snapshot 产生的 dbt_valid_from)
    # 假设 dbt 模型表为 marts.clean_data
    extract_sql = f"""
    SELECT * FROM marts.clean_data 
    WHERE dbt_valid_from > '{last_processed_ts}'
    """
    df = pd.read_sql(extract_sql, engine)

    if df.empty:
        print("No new data to process.")
        return

    # 3. 科学计算逻辑
    df['result_metric'] = df['value'] * 1.5 # 示例算法
    current_max_ts = df['dbt_valid_from'].max()

    # 4. 事务写入：结果表 + 审计表 (保证一致性)
    with engine.begin() as conn:
        # A. 写入结果
        df.to_sql('science_results', conn, if_exists='append', index=False, schema='analytics')
        
        # B. 写入审计日志 (GxP 关键)
        audit_entry = {
            'run_id': run_id,
            'execution_ts': datetime.now(),
            'rows_processed': len(df),
            'high_watermark_ts': current_max_ts,
            'status': 'SUCCESS',
            'image_version': 'v1.0.1' # 最好从 ENV 获取
        }
        pd.DataFrame([audit_entry]).to_sql('science_execution_log', conn, if_exists='append', index=False, schema='audit')

    print(f"Successfully processed {len(df)} rows.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--run_id', required=True)
    args = parser.parse_args()
    
    run_science_calculation(args.run_id)
```

---

## 4. 部署与运维清单

### 4.1. CI/CD 流水线 (GitLab CI 伪代码示例)

确保每次 Tag 推送自动产出镜像。

```yaml
stages:
  - test
  - build

unit_test:
  stage: test
  image: python:3.9
  script:
    - pip install -r requirements.txt
    - pytest python_app/
    - dbt deps && dbt test

build_and_push:
  stage: build
  only:
    - tags  # 仅在打 Tag 时运行 (如 v1.0.1)
  script:
    - docker build -t my-registry/gxp-task-image:$CI_COMMIT_TAG .
    - docker push my-registry/gxp-task-image:$CI_COMMIT_TAG
```

### 4.2. 环境初始化 (Bootstrap)

在 Docker Compose 启动前，你需要手动或通过脚本在 Postgres 中初始化 Audit 表结构：

```sql
CREATE SCHEMA IF NOT EXISTS audit;
CREATE TABLE audit.science_execution_log (
    id SERIAL PRIMARY KEY,
    run_id VARCHAR(255),
    execution_ts TIMESTAMP,
    rows_processed INTEGER,
    high_watermark_ts TIMESTAMP,
    status VARCHAR(50),
    image_version VARCHAR(50)
);
```

这个方案通过**代码固化**（Docker Image）、**主动调度**（Airflow Operator）和**事务级审计**（Python SQL Transaction），完整满足了你对自动化对接和 GxP 合规的需求。
