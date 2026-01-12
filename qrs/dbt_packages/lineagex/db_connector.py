"""
数据库连接器模块 - 替代已废弃的 FalDbt

该模块提供 DbtPostgresConnector 类，用于：
1. 解析 dbt profiles.yml 获取数据库连接信息
2. 执行 SQL 查询并返回 Pandas DataFrame
3. 与原 FalDbt.execute_sql() 行为保持一致
"""

import os
import yaml
import pandas as pd
import psycopg2
from psycopg2.extras import RealDictCursor
from typing import Optional


class DbtPostgresConnector:
    """
    替代 FalDbt 的 PostgreSQL 连接器
    
    用于从 dbt profiles.yml 读取连接配置并执行 SQL 查询
    """
    
    def __init__(
        self,
        profiles_dir: str = "~/.dbt",
        project_dir: str = None,
        target: Optional[str] = None
    ):
        """
        初始化连接器
        
        :param profiles_dir: dbt profiles.yml 所在目录
        :param project_dir: dbt 项目目录 (用于读取 dbt_project.yml 获取 profile 名称)
        :param target: 目标环境 (如 dev, prod)，如不指定则使用默认 target
        """
        self.profiles_dir = os.path.expanduser(profiles_dir)
        self.project_dir = project_dir
        self.target = target
        self.connection = None
        self._connect()
    
    def _get_profile_name(self) -> str:
        """从 dbt_project.yml 获取 profile 名称"""
        if self.project_dir is None:
            return "qrs"  # 默认使用 qrs profile
        
        dbt_project_path = os.path.join(self.project_dir, "dbt_project.yml")
        if os.path.exists(dbt_project_path):
            with open(dbt_project_path, "r", encoding="utf-8") as f:
                project_config = yaml.safe_load(f)
                return project_config.get("profile", "qrs")
        return "qrs"
    
    def _load_profile(self) -> dict:
        """加载 dbt profiles.yml 配置"""
        profiles_path = os.path.join(self.profiles_dir, "profiles.yml")
        
        if not os.path.exists(profiles_path):
            raise FileNotFoundError(f"profiles.yml not found at {profiles_path}")
        
        with open(profiles_path, "r", encoding="utf-8") as f:
            profiles = yaml.safe_load(f)
        
        profile_name = self._get_profile_name()
        if profile_name not in profiles:
            raise ValueError(f"Profile '{profile_name}' not found in profiles.yml")
        
        profile = profiles[profile_name]
        target_name = self.target or profile.get("target", "dev")
        
        if "outputs" not in profile:
            raise ValueError(f"No outputs found in profile '{profile_name}'")
        
        if target_name not in profile["outputs"]:
            raise ValueError(f"Target '{target_name}' not found in profile '{profile_name}'")
        
        return profile["outputs"][target_name]
    
    def _connect(self) -> None:
        """建立数据库连接"""
        config = self._load_profile()
        
        # 验证是 PostgreSQL 类型
        db_type = config.get("type", "")
        if db_type != "postgres":
            raise ValueError(f"Only PostgreSQL is supported, got: {db_type}")
        
        # 构建连接参数
        conn_params = {
            "host": config.get("host", "localhost"),
            "port": config.get("port", 5432),
            "dbname": config.get("dbname", config.get("database", "postgres")),
            "user": config.get("user", "postgres"),
            "password": config.get("pass", config.get("password", "")),
        }
        
        # 可选的 schema (用于 search_path)
        self.schema = config.get("schema", "public")
        
        self.connection = psycopg2.connect(**conn_params)
        self.connection.autocommit = True
    
    def execute_sql(self, sql: str) -> pd.DataFrame:
        """
        执行 SQL 查询并返回 DataFrame
        
        :param sql: 要执行的 SQL 语句
        :return: 查询结果的 Pandas DataFrame
        """
        if self.connection is None:
            self._connect()
        
        try:
            with self.connection.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute(sql)
                if cursor.description is not None:
                    columns = [desc[0] for desc in cursor.description]
                    rows = cursor.fetchall()
                    return pd.DataFrame(rows, columns=columns)
                return pd.DataFrame()
        except Exception as e:
            # 如果连接断开，尝试重连
            if self.connection.closed:
                self._connect()
                return self.execute_sql(sql)
            raise e
    
    def close(self) -> None:
        """关闭数据库连接"""
        if self.connection is not None and not self.connection.closed:
            self.connection.close()
            self.connection = None
    
    def __del__(self):
        """析构函数，确保连接被关闭"""
        self.close()
    
    def __enter__(self):
        """支持 with 语句"""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """支持 with 语句"""
        self.close()
        return False

