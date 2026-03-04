#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="$(${SCRIPT_DIR}/resolve_server.sh "${1:-}")"
SCHEMA_JSON="$(${SCRIPT_DIR}/mcp.sh list "${SERVER}" --schema --json)"

echo "${SCHEMA_JSON}" | jq -e '.status == "ok" and (.tools | type == "array")' >/dev/null

echo "${SCHEMA_JSON}" | jq -r '.tools[]? | [.name, (.description // "")] | @tsv'
