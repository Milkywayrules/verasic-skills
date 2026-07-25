#!/usr/bin/env bash
set -euo pipefail

# Root bundle.tag must match generated @vX.Y.Z pins in governance UX files.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BUNDLE_FILE="$REPO_ROOT/bundle.tag"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

PIN_FILES=(
  "$REPO_ROOT/skills/verasic-github-governance/SKILL.md"
  "$REPO_ROOT/skills/verasic-github-governance-init/SKILL.md"
  "$REPO_ROOT/cursor/rules/verasic-github-governance.mdc"
)

extract_pin() {
  local file="$1"
  grep -oE '@v[0-9]+\.[0-9]+\.[0-9]+' "$file" | head -1 || true
}

echo "== check-bundle-pins =="
echo "repo: $REPO_ROOT"
echo

expected_tag=""
expected_pin=""
if [[ -f "$BUNDLE_FILE" ]]; then
  expected_tag="$(tr -d '[:space:]' < "$BUNDLE_FILE")"
  [[ -n "$expected_tag" && "$expected_tag" != v* ]] && expected_tag="v${expected_tag}"
  expected_pin="@${expected_tag}"
  ok "bundle.tag is $expected_tag"
else
  bad "missing bundle.tag at repo root"
fi

if [[ -f "$REPO_ROOT/skills/verasic-init/references/bundle-tag.txt" ]]; then
  bad "retired skills/verasic-init/references/bundle-tag.txt still present — remove it"
fi

declare -A PIN_BY_FILE=()
pins=()

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
  if [[ -n "$expected_pin" && "$pin" == "$expected_pin" ]]; then
    ok "$rel pins $pin"
  elif [[ -n "$expected_pin" ]]; then
    bad "$rel pins $pin (expected $expected_pin) — run: bash scripts/sync-bundle-tag.sh"
  else
    ok "$rel pins $pin"
  fi
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

MAP="$REPO_ROOT/references/verasic-cursor-map.md"
if [[ -f "$MAP" && -n "$expected_tag" ]]; then
  if grep -q "Bundle \*\*${expected_tag}\*\*" "$MAP"; then
    ok "verasic-cursor-map.md bundle line matches bundle.tag"
  else
    bad "verasic-cursor-map.md bundle line drift — run: bash scripts/sync-bundle-tag.sh"
  fi
fi

echo "---"
echo "check-bundle-pins: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
