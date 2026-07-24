#!/usr/bin/env bash
set -euo pipefail

# SKILL.md manifest registration lines must match skills/verasic-init/manifest.txt wiring.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="$REPO_ROOT/skills/verasic-init/manifest.txt"
SKILLS_DIR="$REPO_ROOT/skills"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

script_label() {
  local script="$1"
  [[ "$script" == "-" ]] && return 0
  local base
  base="$(basename "$script" .sh)"
  echo "$base"
}

expected_registration() {
  local wire="$1"
  local verify="$2"

  if [[ "$wire" == "-" && "$verify" == "-" ]]; then
    echo 'as skill-only (`-|-`)'
    return 0
  fi

  local wire_label verify_label parts=()
  wire_label="$(script_label "$wire")"
  verify_label="$(script_label "$verify")"
  [[ -n "$wire_label" ]] && parts+=("$wire_label")
  [[ -n "$verify_label" && "$verify_label" != "$wire_label" ]] && parts+=("$verify_label")

  if ((${#parts[@]} == 0)); then
    echo ""
    return 1
  fi
  if ((${#parts[@]} == 1)); then
    echo "(${parts[0]})"
  else
    echo "(${parts[0]} + ${parts[1]})"
  fi
}

echo "== check-manifest-claims =="
echo "repo: $REPO_ROOT"
echo

[[ -f "$MANIFEST" ]] && ok 'manifest.txt exists' || bad 'manifest.txt missing'

declare -A WIRE VERIFY

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line//$'\r'/}"
  [[ -z "${line//[[:space:]]/}" ]] && continue
  IFS='|' read -r name wire verify _ <<<"$line"
  name="${name//[[:space:]]/}"
  wire="${wire//[[:space:]]/}"
  verify="${verify//[[:space:]]/}"
  WIRE["$name"]="$wire"
  VERIFY["$name"]="$verify"
done < "$MANIFEST"

REGISTRATION_SKILLS=(
  verasic-github-governance
  verasic-github-governance-init
)

for skill in "${REGISTRATION_SKILLS[@]}"; do
  skill_md="$SKILLS_DIR/$skill/SKILL.md"
  if [[ ! -f "$skill_md" ]]; then
    bad "$skill SKILL.md missing"
    continue
  fi

  if [[ -z "${WIRE[$skill]+x}" ]]; then
    bad "$skill missing from manifest.txt"
    continue
  fi

  expected="$(expected_registration "${WIRE[$skill]}" "${VERIFY[$skill]}")"
  if [[ -z "$expected" ]]; then
    bad "$skill could not derive expected registration from manifest"
    continue
  fi

  if grep -q "Registered in verasic-init manifest $expected" "$skill_md"; then
    ok "$skill manifest claim matches manifest.txt ($expected)"
  else
    bad "$skill manifest claim drift — expected substring: Registered in verasic-init manifest $expected"
    grep -n 'Registered in verasic-init manifest' "$skill_md" || true
  fi
done

echo "---"
echo "check-manifest-claims: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
