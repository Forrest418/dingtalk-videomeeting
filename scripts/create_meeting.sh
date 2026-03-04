#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER="$(${SCRIPT_DIR}/resolve_server.sh)"

TITLE=""
START=""
END=""

usage() {
  cat <<USAGE
用法:
  scripts/create_meeting.sh --title "项目周会" --start "2026-03-06T10:00:00+08:00" --end "2026-03-06T11:00:00+08:00"
说明:
  start/end 支持 ISO 时间，脚本会转换为毫秒时间戳。
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --start) START="${2:-}"; shift 2 ;;
    --end) END="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[create_meeting] unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "${TITLE}" || -z "${START}" || -z "${END}" ]]; then
  echo "[create_meeting] --title/--start/--end 必填。" >&2
  usage
  exit 1
fi

START_MS="$(python3 - <<PY
from datetime import datetime
print(int(datetime.fromisoformat('${START}'.replace('Z','+00:00')).timestamp()*1000))
PY
)"
END_MS="$(python3 - <<PY
from datetime import datetime
print(int(datetime.fromisoformat('${END}'.replace('Z','+00:00')).timestamp()*1000))
PY
)"

if [[ "${END_MS}" -le "${START_MS}" ]]; then
  echo "[create_meeting] 结束时间必须晚于开始时间。" >&2
  exit 1
fi

TITLE_JSON="$(jq -Rn --arg v "${TITLE}" '$v')"
START_JSON="$(jq -Rn --arg v "${START_MS}" '$v')"
END_JSON="$(jq -Rn --arg v "${END_MS}" '$v')"

"${SCRIPT_DIR}/mcp.sh" call "${SERVER}.create_meeting_reservation(startTime: ${START_JSON}, endTime: ${END_JSON}, title: ${TITLE_JSON})" --output json
