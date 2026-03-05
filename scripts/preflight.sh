#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_PATH="$(${SCRIPT_DIR}/mcp.sh --print-config-path 2>/dev/null || true)"
SERVER="$(${SCRIPT_DIR}/resolve_server.sh "${1:-}")"

if ! command -v mcporter >/dev/null 2>&1; then
  echo "[preflight] missing binary: mcporter" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[preflight] missing binary: jq" >&2
  exit 2
fi

if [[ -z "${CONFIG_PATH}" || ! -f "${CONFIG_PATH}" ]]; then
  echo "[preflight] missing config file." >&2
  echo "[preflight] search order: ${OPENCLAW_HOME:-$HOME/.openclaw}/config/mcporter.json -> ${OPENCLAW_HOME:-$HOME/.openclaw}/workspace/config/mcporter.json -> ${SKILL_DIR}/mcporter.json" >&2
  exit 1
fi

TMP_JSON="$(mktemp)"
TMP_ERR="$(mktemp)"
trap 'rm -f "${TMP_JSON}" "${TMP_ERR}"' EXIT

echo "[preflight] mcporter version: $(mcporter --version)"
echo "[preflight] config path: ${CONFIG_PATH}"
echo "[preflight] checking server: ${SERVER}"

if ! "${SCRIPT_DIR}/mcp.sh" list "${SERVER}" --schema --json >"${TMP_JSON}" 2>"${TMP_ERR}"; then
  echo "[preflight] server check failed for '${SERVER}'" >&2
  cat "${TMP_ERR}" >&2 || true
  exit 1
fi

if ! jq -e '.status == "ok" and (.tools | type == "array")' "${TMP_JSON}" >/dev/null 2>&1; then
  echo "[preflight] invalid schema response for '${SERVER}'" >&2
  cat "${TMP_JSON}" >&2 || true
  exit 1
fi

echo "[preflight] ok: server=${SERVER}, tools=$(jq '.tools | length' "${TMP_JSON}")"
