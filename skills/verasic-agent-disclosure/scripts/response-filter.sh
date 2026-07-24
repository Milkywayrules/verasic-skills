#!/usr/bin/env bash
# Fail-closed SaaS outbound response filter — deterministic denylist/allowlist scan.
# See references/saas-integration.md for operator contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=filter-lib.sh
source "$SCRIPT_DIR/filter-lib.sh"

usage() {
  cat <<'EOF'
response-filter — fail-closed outbound disclosure scan for SaaS tenant replies

Usage:
  response-filter.sh [--scope-lock] [FILE]
  echo "..." | response-filter.sh [--scope-lock]

Options:
  --scope-lock   Allow command-mandated /dio-refine-prompt shapes (Mode: light|rich|max, ## assuming)

Exit codes:
  0  safe to ship (no denylist hits)
  1  blocked (hits printed to stderr, one per line)
  2  usage / input error
EOF
}

SCOPE_LOCK=false
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope-lock)
      SCOPE_LOCK=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "response-filter: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -n "$INPUT_FILE" ]]; then
        echo "response-filter: too many arguments" >&2
        exit 2
      fi
      INPUT_FILE="$1"
      shift
      ;;
  esac
done

tmp=""
cleanup() {
  [[ -n "$tmp" && -f "$tmp" ]] && rm -f "$tmp"
}
trap cleanup EXIT

if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "response-filter: file not found: $INPUT_FILE" >&2
    exit 2
  fi
  tmp="$INPUT_FILE"
else
  tmp="$(mktemp)"
  cat >"$tmp"
fi

if [[ ! -s "$tmp" ]]; then
  echo "response-filter: empty input" >&2
  exit 2
fi

hits=()
while IFS= read -r line; do
  hits+=("$line")
done < <(scan_outbound "$tmp" "$SCOPE_LOCK" true true true || true)

if ((${#hits[@]} > 0)); then
  printf '%s\n' "${hits[@]}" >&2
  exit 1
fi

exit 0
