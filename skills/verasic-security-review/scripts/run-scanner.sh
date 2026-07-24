#!/usr/bin/env bash
set -euo pipefail

# Deterministic scanner pass for verasic-security-review.
# Usage: run-scanner.sh <scanner> -- <file1> [file2...]
#   scanner: off | opengrep | semgrep | auto
# Prints normalized findings to stdout; skip lines to stderr; exit 0 always.

usage() {
  echo "usage: run-scanner.sh <off|opengrep|semgrep|auto> -- [files...]" >&2
  exit 1
}

SCANNER="${1:-off}"
shift || usage
[[ "${1:-}" == "--" ]] || usage
shift

declare -a FILES=("$@")
TIMEOUT="${VERASIC_SCANNER_TIMEOUT:-120}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RULES_DIR="$SKILL_ROOT/rules/opengrep"

skip() {
  echo "Scanner: $*" >&2
  exit 0
}

if [[ "$SCANNER" == "off" ]]; then
  skip "off (config)"
fi

if ((${#FILES[@]} == 0)); then
  skip "skipped (no changed source files)"
fi

run_opengrep() {
  local -a args=(scan --json --quiet --)
  if [[ -d "$RULES_DIR" ]]; then
    args=(-f "$RULES_DIR" "${args[@]}")
  else
    args=(-f p/default "${args[@]}")
  fi
  # p/default may fetch registry rules — prefer shipping rules/opengrep/ for offline use
  timeout "$TIMEOUT" opengrep "${args[@]}" "${FILES[@]}" 2>/dev/null
}

run_semgrep() {
  if [[ -d "$SKILL_ROOT/rules/semgrep" ]]; then
    timeout "$TIMEOUT" semgrep scan --config "$SKILL_ROOT/rules/semgrep" --json --quiet -- "${FILES[@]}" 2>/dev/null
  else
    return 1
  fi
}

emit_from_json() {
  python3 - <<'PY'
import json, sys

raw = sys.stdin.read().strip()
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)

results = data.get("results") or data.get("matches") or []
for hit in results:
    path = hit.get("path") or hit.get("file") or "?"
    start = hit.get("start") or {}
    line = start.get("line") or hit.get("line") or "?"
    rule = hit.get("check_id") or hit.get("rule_id") or hit.get("rule") or "rule"
    msg = hit.get("extra", {}).get("message") or hit.get("message") or str(rule)
    print(f"Source: Deterministic")
    print(f"Category: {rule}")
    print(f"Location: {path}:{line}")
    print(f"Confidence: High (9/10)")
    print(f"Finding: {msg}")
    print("---")
PY
}

case "$SCANNER" in
  opengrep)
    command -v opengrep >/dev/null 2>&1 || skip "skipped (opengrep not installed)"
    run_opengrep | emit_from_json || skip "skipped (opengrep failed)"
    ;;
  semgrep)
    command -v semgrep >/dev/null 2>&1 || skip "skipped (semgrep not installed)"
    run_semgrep | emit_from_json || skip "skipped (semgrep failed)"
    ;;
  auto)
    if command -v opengrep >/dev/null 2>&1; then
      if out="$(run_opengrep)" && [[ -n "$out" ]]; then
        echo "$out" | emit_from_json
        exit 0
      fi
      if command -v semgrep >/dev/null 2>&1; then
        run_semgrep | emit_from_json || skip "skipped (auto: opengrep empty, semgrep failed)"
      else
        skip "skipped (auto: opengrep empty, semgrep not installed)"
      fi
    elif command -v semgrep >/dev/null 2>&1; then
      run_semgrep | emit_from_json || skip "skipped (semgrep failed)"
    else
      skip "skipped (no opengrep or semgrep on PATH)"
    fi
    ;;
  *)
    echo "run-scanner: unknown scanner: $SCANNER" >&2
    exit 1
    ;;
esac
