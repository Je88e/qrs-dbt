本目录提供“实施方案（优化版）”中提到的参考配置文件，用于在 Docker Compose 场景下落地：

- `task-image.Dockerfile`：构建 dbt Task Image（qrs 项目 + dbt 依赖），运行时挂载 profiles
- `profiles.sample.yml`：dbt profiles 示例（通过环境变量注入连接信息）
- `docker-compose.prod.sample.yml`：生产运行域 Compose 示例（含 docker-socket-proxy 思路，未包含 Airbyte 服务定义）
