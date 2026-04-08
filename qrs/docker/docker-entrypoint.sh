#!/usr/bin/env bash
set -euo pipefail

ts() {
  date -u +'%Y-%m-%dT%H:%M:%SZ'
}

log() {
  printf '%s %s\n' "$(ts)" "$*" >&2
}

project_dir="${DBT_PROJECT_DIR:-/app/qrs}"
profiles_dir="${DBT_PROFILES_DIR:-/app/profiles}"
# target="${DBT_TARGET:-prod}"
target="${DBT_TARGET:-dev}"
host="${DBT_DOCS_HOST:-0.0.0.0}"
port="${DBT_DOCS_PORT:-${PORT:-8080}}"
log_path="${DBT_LOG_PATH:-/var/log/dbt}"
log_format="${DBT_LOG_FORMAT:-json}"
deps_on_startup="${DBT_DEPS_ON_STARTUP:-false}"

cmd="${1:-serve}"
if [[ $# -gt 0 ]]; then
  shift
fi

if [[ ! -d "${project_dir}" ]]; then
  log "ERROR: DBT_PROJECT_DIR not found: ${project_dir}"
  exit 2
fi

if [[ ! -f "${profiles_dir}/profiles.yml" ]]; then
  log "ERROR: profiles.yml not found: ${profiles_dir}/profiles.yml"
  exit 3
fi

mkdir -p "${log_path}"

dbt_global_args=(--log-format "${log_format}" --log-path "${log_path}")

cd "${project_dir}"

if [[ "${deps_on_startup}" == "true" || ! -d "dbt_packages" ]]; then
  log "dbt_packages not found; running dbt deps"
  dbt "${dbt_global_args[@]}" deps --project-dir "${project_dir}" --profiles-dir "${profiles_dir}"
fi

case "${cmd}" in
  generate)
    log "Generating docs (target=${target})"
    exec dbt "${dbt_global_args[@]}" docs generate --project-dir "${project_dir}" --profiles-dir "${profiles_dir}" --target "${target}" "$@"
    ;;
  serve)
    log "Generating docs (target=${target})"
    dbt "${dbt_global_args[@]}" docs generate --project-dir "${project_dir}" --profiles-dir "${profiles_dir}" --target "${target}"
    log "Serving docs on ${host}:${port}"
    exec dbt "${dbt_global_args[@]}" docs serve --project-dir "${project_dir}" --profiles-dir "${profiles_dir}" --target "${target}" --host "${host}" --port "${port}" --no-browser "$@"
    ;;
  *)
    exec "${cmd}" "$@"
    ;;
esac
