ARG PYTHON_IMAGE=python:3.12-slim
ARG DBT_VERSION=1.10.15
ARG DBT_POSTGRES_VERSION=1.9.1
ARG APT_MIRROR=https://mirrors.tuna.tsinghua.edu.cn
ARG PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple
ARG PIP_EXTRA_INDEX_URL=https://pypi.org/simple
ARG PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn
ARG DBT_PACKAGE_HUB_URL=https://hub.getdbt.com/

FROM ${PYTHON_IMAGE} AS builder

ARG DBT_VERSION
ARG DBT_POSTGRES_VERSION
ARG APT_MIRROR
ARG PIP_INDEX_URL
ARG PIP_EXTRA_INDEX_URL
ARG PIP_TRUSTED_HOST
ARG DBT_PACKAGE_HUB_URL

ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=120 \
    PIP_INDEX_URL="${PIP_INDEX_URL}" \
    PIP_EXTRA_INDEX_URL="${PIP_EXTRA_INDEX_URL}" \
    PIP_RETRIES=10 \
    PIP_TRUSTED_HOST="${PIP_TRUSTED_HOST}" \
    DBT_PACKAGE_HUB_URL="${DBT_PACKAGE_HUB_URL}" \
    PYTHONDONTWRITEBYTECODE=1

RUN set -eux; \
  if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
    sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|https://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|http://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|http://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g" /etc/apt/sources.list.d/debian.sources; \
  fi; \
  if [ -f /etc/apt/sources.list ]; then \
    sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|https://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|http://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|http://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g" /etc/apt/sources.list; \
  fi; \
  apt-get update \
  && apt-get install -y --no-install-recommends build-essential git libpq-dev \
  && rm -rf /var/lib/apt/lists/*

RUN python -m venv "${VIRTUAL_ENV}" \
  && python -m pip install --upgrade pip setuptools wheel \
  && python -m pip install \
    --index-url "${PIP_INDEX_URL}" \
    --extra-index-url "${PIP_EXTRA_INDEX_URL}" \
    --trusted-host "${PIP_TRUSTED_HOST}" \
    --trusted-host pypi.org \
    --trusted-host files.pythonhosted.org \
    "dbt-core==${DBT_VERSION}" \
    "dbt-postgres==${DBT_POSTGRES_VERSION}"

WORKDIR /build/qrs

COPY dbt_project.yml packages.yml ./

RUN dbt deps --project-dir /build/qrs \
  && dbt --version

COPY analyses /build/qrs/analyses
COPY docs /build/qrs/docs
COPY macros /build/qrs/macros
COPY models /build/qrs/models
COPY seeds /build/qrs/seeds
COPY snapshots /build/qrs/snapshots
COPY tests /build/qrs/tests

FROM ${PYTHON_IMAGE} AS runtime

ARG APT_MIRROR
ARG DBT_PACKAGE_HUB_URL

ENV VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DBT_PACKAGE_HUB_URL="${DBT_PACKAGE_HUB_URL}"

RUN set -eux; \
  if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
    sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|https://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|http://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|http://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g" /etc/apt/sources.list.d/debian.sources; \
  fi; \
  if [ -f /etc/apt/sources.list ]; then \
    sed -i "s|http://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|https://deb.debian.org/debian|${APT_MIRROR}/debian|g; s|http://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://deb.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|http://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g; s|https://security.debian.org/debian-security|${APT_MIRROR}/debian-security|g" /etc/apt/sources.list; \
  fi; \
  apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates curl libpq5 tini \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd --system --gid 10001 dbt \
  && useradd --system --uid 10001 --gid dbt --create-home --home-dir /home/dbt --shell /usr/sbin/nologin dbt \
  && mkdir -p /app/profiles /var/log/dbt /home/dbt/.dbt

WORKDIR /app/qrs

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder --chown=dbt:dbt /build/qrs /app/qrs
COPY --chown=root:root docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

RUN chmod 0755 /usr/local/bin/docker-entrypoint \
  && chown -R dbt:dbt /app /var/log/dbt /home/dbt

USER dbt

ENV DBT_PROJECT_DIR=/app/qrs \
    DBT_PROFILES_DIR=/app/profiles \
    # DBT_TARGET=prod \
    DBT_TARGET=dev \
    DBT_LOG_PATH=/var/log/dbt \
    DBT_LOG_FORMAT=json \
    DBT_DOCS_HOST=0.0.0.0 \
    DBT_DOCS_PORT=8080 \
    DBT_SEND_ANONYMOUS_USAGE_STATS=false \
    PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD sh -ec 'port="${DBT_DOCS_PORT:-${PORT:-8080}}"; curl -fsS "http://127.0.0.1:${port}/index.html" >/dev/null'

ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint"]
CMD ["serve"]
