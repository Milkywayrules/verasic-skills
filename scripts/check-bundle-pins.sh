#!/usr/bin/env bash
set -euo pipefail

# Governance UX bundle pins (@vX.Y.Z) must match across SKILL.md files and cursor rule.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

PIN_FILES=(
  "$REPO_ROOT/skills/verasic-github-governance/SKILL.md"
  "$REPO_ROOT/skills/verasic-github-governance-init/SKILL.md"
  "$REPO_ROOT/cursor/rules/verasic-github-governance.mdc"
)

declare -A PIN_BY_FILE=()
pins=()

extract_pin() {
  local file="$1"
  local pin
  pin="$(grep -oE '@v[0-9]+\.[0-9]+\.[0-9]+' "$file" | head -1 || true)"
  echo "$pin"
}

echo "== check-bundle-pins =="
echo "repo: $REPO_ROOT"
echo

for file in "${PIN_FILES[@]}"; do
  rel="${file#"$REPO_ROOT"/}"
  if [[ ! -f "$file" ]]; then
    bad "missing file: $rel"
    continue
  fi
  pin="$(extract_pin "$file")"
  if [[ -z "$pin" ]]; then
    bad "no @vX.Y.Z pin in $rel"
    continue
  fi
  PIN_BY_FILE["$rel"]="$pin"
  pins+=("$pin")
  ok "$rel pins $pin"
done

if ((${#pins[@]} > 0)); then
  first="${pins[0]}"
  consistent=true
  for pin in "${pins[@]}"; do
    [[ "$pin" == "$first" ]] || consistent=false
  done
  if $consistent; then
    ok "all governance UX bundle pins match ($first)"
  else
    bad "governance UX bundle pin drift:"
    for rel in "${!PIN_BY_FILE[@]}"; do
      echo "  $rel → ${PIN_BY_FILE[$rel]}"
    done
  fi
fi

echo "---"
echo "check-bundle-pins: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
