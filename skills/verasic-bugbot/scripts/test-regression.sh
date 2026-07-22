#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-bugbot. No AI harness required.

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

COMMAND_FILE=""
if [[ -f "$INSTALL_ROOT/cursor/commands/verasic-review.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/cursor/commands/verasic-review.md"
elif [[ -f "$INSTALL_ROOT/commands/verasic-review.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/commands/verasic-review.md"
fi

AGENT_FILE=""
if [[ -f "$INSTALL_ROOT/cursor/agents/verasic-bugbot.md" ]]; then
  AGENT_FILE="$INSTALL_ROOT/cursor/agents/verasic-bugbot.md"
elif [[ -f "$INSTALL_ROOT/agents/verasic-bugbot.md" ]]; then
  AGENT_FILE="$INSTALL_ROOT/agents/verasic-bugbot.md"
fi

assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-bugbot' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'review-protocol\.md' 'SKILL.md points to protocol'

assert_file "$SKILL_ROOT/references/review-protocol.md" 'review-protocol.md exists'
assert_file "$SKILL_ROOT/README.md" 'README.md exists'
assert_file "$SKILL_ROOT/VERSION" 'VERSION exists'

assert_grep "$SKILL_ROOT/references/review-protocol.md" '## Review scope' 'protocol review scope section'
assert_grep "$SKILL_ROOT/references/review-protocol.md" '## Process' 'protocol process section'
assert_grep "$SKILL_ROOT/references/review-protocol.md" '## Untrusted input' 'protocol untrusted input section'
assert_grep "$SKILL_ROOT/references/review-protocol.md" '## Filtering' 'protocol filtering section'
assert_grep "$SKILL_ROOT/references/review-protocol.md" '## Output format' 'protocol output format section'

assert_file "$SKILL_ROOT/checklists/correctness.md" 'checklist correctness.md exists'
assert_file "$SKILL_ROOT/checklists/security.md" 'checklist security.md exists'
assert_file "$SKILL_ROOT/checklists/performance.md" 'checklist performance.md exists'
assert_file "$SKILL_ROOT/checklists/infra.md" 'checklist infra.md exists'

assert_grep "$SKILL_ROOT/checklists/correctness.md" 'Logic inversion' 'correctness checklist logic inversion'
assert_grep "$SKILL_ROOT/checklists/security.md" 'Injection' 'security checklist injection'
assert_grep "$SKILL_ROOT/checklists/performance.md" 'N\+1' 'performance checklist N+1'
assert_grep "$SKILL_ROOT/checklists/infra.md" 'Publicly exposed' 'infra checklist exposed services'

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

if [[ -n "$COMMAND_FILE" ]]; then
  assert_file "$COMMAND_FILE" 'cursor command verasic-review.md'
  assert_grep "$COMMAND_FILE" 'verasic-bugbot' 'command launches verasic-bugbot subagent'
  assert_grep "$COMMAND_FILE" 'checklists/' 'command references checklists'
else
  bad 'cursor command verasic-review.md (not found in source or install layout)'
fi

if [[ -n "$AGENT_FILE" ]]; then
  assert_file "$AGENT_FILE" 'cursor agent verasic-bugbot.md'
  assert_grep "$AGENT_FILE" '^name: verasic-bugbot' 'agent name frontmatter'
  assert_grep "$AGENT_FILE" 'review-protocol\.md' 'agent points to protocol'
else
  bad 'cursor agent verasic-bugbot.md (not found in source or install layout)'
fi

if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-bugbot\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-bugbot'
  else
    bad 'manifest lists verasic-bugbot'
  fi
  if grep -q 'verasic-bugbot' "$INSTALL_ROOT/README.md" 2>/dev/null; then
    ok 'root README mentions verasic-bugbot'
  else
    bad 'root README mentions verasic-bugbot'
  fi
else
  ok 'manifest check skipped (installed layout)'
  ok 'root README check skipped (installed layout)'
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
