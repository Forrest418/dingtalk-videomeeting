#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_PATH="${SKILL_DIR}/mcporter.json"

if ! command -v mcporter >/dev/null 2>&1; then
  echo "[mcp] missing binary: mcporter" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[mcp] missing binary: jq" >&2
  exit 2
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "[mcp] missing config file: ${CONFIG_PATH}" >&2
  echo "[mcp] 请将用户提供的 mcporter.json 复制到技能目录。" >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  exec mcporter --config "${CONFIG_PATH}"
fi

COMMAND="$1"
shift || true

default_server() {
  jq -r '.mcpServers | keys[0] // empty' "${CONFIG_PATH}"
}

server_exists() {
  local server_name="$1"
  jq -e --arg n "${server_name}" '.mcpServers | has($n)' "${CONFIG_PATH}" >/dev/null 2>&1
}

fix_selector_server() {
  local selector="$1"
  local first_dot
  local server
  local rest
  local fallback

  first_dot="${selector%%.*}"
  if [[ "${first_dot}" == "${selector}" ]]; then
    echo "${selector}"
    return 0
  fi

  server="${first_dot}"
  rest="${selector#*.}"

  if server_exists "${server}"; then
    echo "${selector}"
    return 0
  fi

  fallback="$(default_server)"
  if [[ -n "${fallback}" ]]; then
    echo "[mcp] server '${server}' 不在技能配置中，自动改用 '${fallback}'。" >&2
    echo "${fallback}.${rest}"
    return 0
  fi

  echo "${selector}"
}

case "${COMMAND}" in
  list)
    if [[ $# -gt 0 ]]; then
      target="$1"
      if [[ "${target}" != -* && "${target}" != http://* && "${target}" != https://* ]]; then
        if ! server_exists "${target}"; then
          fallback="$(default_server)"
          if [[ -n "${fallback}" ]]; then
            echo "[mcp] server '${target}' 不在技能配置中，自动改用 '${fallback}'。" >&2
            set -- "${fallback}" "${@:2}"
          fi
        fi
      fi
    fi
    exec mcporter --config "${CONFIG_PATH}" list "$@"
    ;;
  call)
    if [[ $# -gt 0 ]]; then
      selector="$1"
      if [[ "${selector}" != -* && "${selector}" != http://* && "${selector}" != https://* ]]; then
        set -- "$(fix_selector_server "${selector}")" "${@:2}"
      fi
    fi
    exec mcporter --config "${CONFIG_PATH}" call "$@"
    ;;
  *)
    exec mcporter --config "${CONFIG_PATH}" "${COMMAND}" "$@"
    ;;
esac
