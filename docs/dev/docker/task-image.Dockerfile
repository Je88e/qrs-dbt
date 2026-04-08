FROM python:3.13-slim

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends git gcc libpq-dev \
  && rm -rf /var/lib/apt/lists/*

ARG DBT_VERSION=1.10.15

RUN pip install --no-cache-dir "dbt-core==${DBT_VERSION}" "dbt-postgres==${DBT_VERSION}"

COPY qrs/ ./qrs/

RUN cd /app/qrs && dbt deps

ENV DBT_PROFILES_DIR=/app/profiles
ENV DBT_SEND_ANONYMOUS_USAGE_STATS=false

CMD ["bash", "-lc", "cd /app/qrs && dbt --version"]
