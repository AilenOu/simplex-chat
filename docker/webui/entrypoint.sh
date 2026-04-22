#!/usr/bin/env bash
set -euo pipefail

SIMPLEX_WS_PORT="${SIMPLEX_WS_PORT:-5225}"
SIMPLEX_DB_PATH="${SIMPLEX_DB_PATH:-/var/lib/simplex/chat}"

mkdir -p "$(dirname "${SIMPLEX_DB_PATH}")"
mkdir -p /var/log/nginx

simplex-chat -p "${SIMPLEX_WS_PORT}" -d "${SIMPLEX_DB_PATH}" &
chat_pid=$!

nginx -g 'daemon off;' &
nginx_pid=$!

cleanup() {
  kill "${chat_pid}" "${nginx_pid}" 2>/dev/null || true
}

trap cleanup INT TERM

wait -n "${chat_pid}" "${nginx_pid}"
status=$?
cleanup
wait || true
exit "${status}"

