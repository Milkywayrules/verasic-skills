#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-agent-disclosure. No Cursor Agent CLI required.

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_ROOT="$(cd "$SKILL_ROOT/../.." && pwd)"
IS_SOURCE_TREE=false
if [[ -f "$INSTALL_ROOT/README.md" && -d "$INSTALL_ROOT/cursor/commands" && -d "$INSTALL_ROOT/skills/verasic-init" ]]; then
  IS_SOURCE_TREE=true
fi

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

assert_file() {
  local path="$1" name="$2"
  if [[ -f "$path" ]]; then ok "$name"; else bad "$name (missing: $path)"; fi
}

assert_grep() {
  local file="$1" pattern="$2" name="$3"
  if [[ -f "$file" ]] && grep -qE "$pattern" "$file" 2>/dev/null; then ok "$name"; else bad "$name"; fi
}

RULE_FILE=""
if [[ -f "$INSTALL_ROOT/cursor/rules/verasic-agent-disclosure.mdc" ]]; then
  RULE_FILE="$INSTALL_ROOT/cursor/rules/verasic-agent-disclosure.mdc"
fi

COMMAND_FILE=""
if [[ -f "$INSTALL_ROOT/cursor/commands/verasic-disclosure-red-team.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/cursor/commands/verasic-disclosure-red-team.md"
fi

assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-agent-disclosure' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'disclosure-policy\.md' 'SKILL.md points to disclosure policy'
assert_grep "$SKILL_ROOT/SKILL.md" 'red-team-protocol\.md' 'SKILL.md points to red-team protocol'

assert_file "$SKILL_ROOT/VERSION" 'VERSION exists'
assert_file "$SKILL_ROOT/README.md" 'README.md exists'
assert_file "$SKILL_ROOT/assets/verasic-agent-disclosure.mdc" 'assets/verasic-agent-disclosure.mdc exists'
assert_file "$SKILL_ROOT/references/disclosure-policy.md" 'disclosure-policy.md exists'
assert_file "$SKILL_ROOT/references/red-team-protocol.md" 'red-team-protocol.md exists'
assert_file "$SKILL_ROOT/references/red-team-prompts.md" 'red-team-prompts.md exists'
assert_file "$SKILL_ROOT/references/red-team-prompts-exhaustive.md" 'red-team-prompts-exhaustive.md exists'
assert_grep "$SKILL_ROOT/references/red-team-protocol.md" 'Tier 2' 'red-team-protocol.md mentions Tier 2'
assert_grep "$SKILL_ROOT/references/red-team-protocol.md" 'red-team-prompts-exhaustive\.md' 'red-team-protocol.md links exhaustive catalog'
assert_file "$SKILL_ROOT/references/saas-integration.md" 'saas-integration.md exists'
assert_file "$SKILL_ROOT/references/scanner-notes.md" 'scanner-notes.md exists'
assert_file "$SKILL_ROOT/scripts/wire-rule.sh" 'wire-rule.sh exists'
assert_file "$SKILL_ROOT/scripts/run-red-team.sh" 'run-red-team.sh exists'
assert_file "$SKILL_ROOT/scripts/run-red-team-tools.sh" 'run-red-team-tools.sh exists'
assert_grep "$SKILL_ROOT/scripts/run-red-team-tools.sh" '^PROMPTS=\(' 'run-red-team-tools.sh defines PROMPTS array'
assert_grep "$SKILL_ROOT/scripts/run-red-team-tools.sh" 'cursor agent --print --output-format text' 'run-red-team-tools.sh uses agent+tools CLI'
if grep -qE 'not implemented|exit 2' "$SKILL_ROOT/scripts/run-red-team-tools.sh" 2>/dev/null; then
  bad 'run-red-team-tools.sh ships harness (not stub exit 2)'
else
  ok 'run-red-team-tools.sh ships harness (not stub exit 2)'
fi
assert_file "$SKILL_ROOT/scripts/filter-lib.sh" 'filter-lib.sh exists'
assert_file "$SKILL_ROOT/scripts/response-filter.sh" 'response-filter.sh exists'
assert_file "$SKILL_ROOT/scripts/test-response-filter.sh" 'test-response-filter.sh exists'

if bash "$SKILL_ROOT/scripts/test-response-filter.sh" >/dev/null 2>&1; then
  ok 'test-response-filter.sh passes'
else
  bad 'test-response-filter.sh passes'
fi

prompt_count=$(
  awk '/^PROMPTS=\(/, /^\)/ {
    if ($0 ~ /^[[:space:]]*'\''[^|]+\|/) count++
  }
  END { print count + 0 }' "$SKILL_ROOT/scripts/run-red-team.sh"
)
if (( prompt_count == 18 )); then
  ok 'run-red-team.sh PROMPTS has 18 entries'
else
  bad "run-red-team.sh PROMPTS has 18 entries (found ${prompt_count})"
fi

tools_prompt_count=$(
  awk '/^PROMPTS=\(/, /^\)/ {
    if ($0 ~ /^[[:space:]]*'\''[^|]+\|/) count++
  }
  END { print count + 0 }' "$SKILL_ROOT/scripts/run-red-team-tools.sh"
)
if (( tools_prompt_count >= 4 && tools_prompt_count <= 6 )); then
  ok "run-red-team-tools.sh PROMPTS has ${tools_prompt_count} entries (4–6 expected)"
else
  bad "run-red-team-tools.sh PROMPTS has 4–6 entries (found ${tools_prompt_count})"
fi

assert_grep "$SKILL_ROOT/scripts/wire-rule.sh" 'verasic-agent-disclosure\.mdc' 'wire-rule.sh copies verasic-agent-disclosure.mdc'
assert_grep "$SKILL_ROOT/references/disclosure-policy.md" '## Absolute boundary' 'disclosure policy absolute boundary section'
assert_grep "$SKILL_ROOT/references/disclosure-policy.md" '## Response shape' 'disclosure policy response shape section'

assert_file "$SKILL_ROOT/integrity.txt" 'integrity.txt exists'
assert_file "$SKILL_ROOT/integrity.sha256" 'integrity.sha256 exists'

hash_tmp="$(mktemp)"
while IFS= read -r line || [[ -n "$line" ]]; do
  stripped="${line%%#*}"
  stripped="${stripped//[[:space:]]/}"
  [[ -z "$stripped" ]] && continue
  [[ "$stripped" == "integrity.sha256" ]] && continue
  (cd "$SKILL_ROOT" && sha256sum "$stripped") >> "$hash_tmp"
done < "$SKILL_ROOT/integrity.txt"
if cmp -s "$hash_tmp" "$SKILL_ROOT/integrity.sha256"; then
  ok 'integrity.sha256 matches integrity.txt entries'
else
  bad 'integrity.sha256 matches integrity.txt entries'
fi
rm -f "$hash_tmp"

if [[ -n "$RULE_FILE" ]]; then
  assert_file "$RULE_FILE" 'cursor rule verasic-agent-disclosure.mdc'
  assert_grep "$RULE_FILE" 'verasic-agent-disclosure' 'cursor rule title'
else
  bad 'cursor rule verasic-agent-disclosure.mdc (not found in source tree)'
fi

if [[ -n "$COMMAND_FILE" ]]; then
  assert_file "$COMMAND_FILE" 'cursor command verasic-disclosure-red-team.md'
  assert_grep "$COMMAND_FILE" 'run-red-team\.sh' 'command runs red-team script'
else
  bad 'cursor command verasic-disclosure-red-team.md (not found in source tree)'
fi

if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-agent-disclosure\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-agent-disclosure'
  else
    bad 'manifest lists verasic-agent-disclosure'
  fi
  if grep -q 'verasic-agent-disclosure' "$INSTALL_ROOT/README.md" 2>/dev/null; then
    ok 'root README mentions verasic-agent-disclosure'
  else
    bad 'root README mentions verasic-agent-disclosure'
  fi
else
  ok 'manifest check skipped (installed layout)'
  ok 'root README check skipped (installed layout)'
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
