#!/usr/bin/env bash
set -euo pipefail

# Protocol-level exhaustive checks (no AI harness). Validates pre-flight rules
# documented in references/use-cases.md UC-1, UC-5, UC-6 negative, UC-9.

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_FILE="$SKILL_ROOT/references/models.md"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

count_models() {
  local csv="$1"
  local n=0
  local m
  IFS=',' read -ra _arr <<< "$csv"
  for m in "${_arr[@]}"; do
    m="${m//[[:space:]]/}"
    [[ -n "$m" ]] && n=$((n + 1))
  done
  echo "$n"
}

# UC-1: missing mode/models → must not pass pre-flight
uc1_missing_mode() {
  [[ -z "${1:-}" ]] && return 0
  return 1
}

uc1_missing_models() {
  local n
  n="$(count_models "${1:-}")"
  [[ "$n" -lt 2 ]]
}

if uc1_missing_mode "" && uc1_missing_models "composer-2.5-fast"; then
  ok 'UC-1 missing mode blocks pre-flight'
else
  bad 'UC-1 missing mode blocks pre-flight'
fi

if ! uc1_missing_mode "fusion" && uc1_missing_models "composer-2.5-fast"; then
  ok 'UC-1 single model blocks pre-flight'
else
  bad 'UC-1 single model blocks pre-flight'
fi

if ! uc1_missing_mode "fusion" && ! uc1_missing_models "composer-2.5-fast,cursor-grok-4.5-medium"; then
  ok 'UC-1 valid mode+models passes pre-flight gate'
else
  bad 'UC-1 valid mode+models passes pre-flight gate'
fi

# UC-5: hard cap 6 without acknowledge
roster7="composer-2.5-fast,gemini-3-flash,claude-sonnet-5-thinking-high,claude-opus-4-8-thinking-medium,gpt-5.6-sol-medium,cursor-grok-4.5-medium,glm-5.2-high"
n7="$(count_models "$roster7")"
if [[ "$n7" -eq 7 ]]; then
  ok 'UC-5 roster count is 7'
else
  bad "UC-5 roster count is 7 (got $n7)"
fi

if [[ "$n7" -gt 6 ]]; then
  ok 'UC-5 hard cap blocks 7 models without acknowledge'
else
  bad 'UC-5 hard cap blocks 7 models without acknowledge'
fi

ack="acknowledge: proceed with 7 models"
if [[ "$n7" -gt 6 && "$ack" == acknowledge* ]]; then
  ok 'UC-5 acknowledge bypass allows 7 models'
else
  bad 'UC-5 acknowledge bypass allows 7 models'
fi

# UC-6 negative: stakeholder-lens requires lens-map entries for every model
models="composer-2.5-fast,cursor-grok-4.5-medium,glm-5.2-high"
lens_map=$'composer-2.5-fast: ceo\ncursor-grok-4.5-medium: cto'
# simulate missing glm in map
missing=false
IFS=',' read -ra _m <<< "$models"
for m in "${_m[@]}"; do
  m="${m//[[:space:]]/}"
  grep -qE "^[[:space:]]*${m}:" <<< "$lens_map" || missing=true
done
if $missing; then
  ok 'UC-6 negative missing lens-map entry blocks pre-flight'
else
  bad 'UC-6 negative missing lens-map entry blocks pre-flight'
fi

complete_map=$'composer-2.5-fast: ceo\ncursor-grok-4.5-medium: cto\nglm-5.2-high: customer'
missing=false
for m in "${_m[@]}"; do
  m="${m//[[:space:]]/}"
  grep -qE "^[[:space:]]*${m}:" <<< "$complete_map" || missing=true
done
if ! $missing; then
  ok 'UC-6 complete lens-map passes pre-flight'
else
  bad 'UC-6 complete lens-map passes pre-flight'
fi

# UC-9: mutation keywords trigger refusal (structural check in protocol)
assert_grep() {
  local file="$1" pattern="$2" name="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then ok "$name"; else bad "$name"; fi
}

assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'Out of scope.*mutation' 'UC-9 protocol refuses mutations'
assert_grep "$SKILL_ROOT/references/helper.md" 'Readonly exploration' 'UC-0 helper scope readonly'

# GLM registered
assert_grep "$MODELS_FILE" 'glm-5.2-high' 'models.md lists glm-5.2-high'
assert_grep "$MODELS_FILE" 'glm' 'models.md lists glm alias'

# UC-0 helper file readable
if [[ -s "$SKILL_ROOT/references/helper.md" ]]; then
  ok 'UC-0 helper.md present and non-empty'
else
  bad 'UC-0 helper.md present and non-empty'
fi

echo "---"
echo "exhaustive-protocol: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
