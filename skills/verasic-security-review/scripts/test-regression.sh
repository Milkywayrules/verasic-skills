#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-security-review. No AI harness required.

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_ROOT="$(cd "$SKILL_ROOT/../.." && pwd)"
REPO_ROOT="$INSTALL_ROOT"
if git -C "$SKILL_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SKILL_ROOT" rev-parse --show-toplevel)"
fi
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
for candidate in \
  "$REPO_ROOT/.cursor/commands/verasic-security-review.md" \
  "$INSTALL_ROOT/cursor/commands/verasic-security-review.md" \
  "$REPO_ROOT/.agents/cursor/commands/verasic-security-review.md" \
  "$INSTALL_ROOT/commands/verasic-security-review.md"; do
  if [[ -f "$candidate" ]]; then COMMAND_FILE="$candidate"; break; fi
done

AGENT_FILE=""
for candidate in \
  "$REPO_ROOT/.cursor/agents/verasic-security-reviewer.md" \
  "$INSTALL_ROOT/cursor/agents/verasic-security-reviewer.md" \
  "$REPO_ROOT/.agents/cursor/agents/verasic-security-reviewer.md"; do
  if [[ -f "$candidate" ]]; then AGENT_FILE="$candidate"; break; fi
done

PROTO="$SKILL_ROOT/references/security-review-protocol.md"

assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-security-review' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'security-review-protocol\.md' 'SKILL.md points to protocol'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-security-reviewer' 'SKILL.md spawns verasic-security-reviewer'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-agent-disclosure' 'SKILL.md strips internals per disclosure'
assert_grep "$SKILL_ROOT/SKILL.md" '/verasic-review' 'SKILL.md cross-tip to verasic-review'

assert_file "$PROTO" 'security-review-protocol.md exists'
assert_file "$SKILL_ROOT/README.md" 'README.md exists'
assert_file "$SKILL_ROOT/VERSION" 'VERSION exists'
assert_grep "$SKILL_ROOT/VERSION" '^0\.1\.1' 'VERSION is 0.1.1'

assert_grep "$PROTO" '## Review scope' 'protocol review scope section'
assert_grep "$PROTO" 'STRIDE' 'protocol mentions STRIDE'
assert_grep "$PROTO" 'OWASP' 'protocol mentions OWASP'
assert_grep "$PROTO" '## Untrusted input' 'protocol untrusted input section'
assert_grep "$PROTO" 'prompt injection' 'protocol prompt injection as HIGH'
assert_grep "$PROTO" 'Scales \(this run\)' 'protocol legend on every report'
assert_grep "$PROTO" 'Deterministic' 'protocol Deterministic findings'
assert_grep "$PROTO" 'Heuristic' 'protocol Heuristic findings'
assert_grep "$PROTO" 'Non-findings considered' 'protocol non-findings section'
assert_grep "$PROTO" 'Out of scope' 'protocol out of scope section'
assert_grep "$PROTO" 'Read-only' 'protocol read-only no fixes'

assert_file "$SKILL_ROOT/references/confidence-rubric.md" 'confidence-rubric.md exists'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" '0–10|0-10' 'confidence rubric 0-10 scale'

assert_file "$SKILL_ROOT/references/scanner-adapter.md" 'scanner-adapter.md exists'
assert_grep "$SKILL_ROOT/references/scanner-adapter.md" 'opengrep' 'scanner-adapter mentions opengrep'
assert_grep "$SKILL_ROOT/references/scanner-adapter.md" 'semgrep' 'scanner-adapter mentions semgrep'
assert_grep "$SKILL_ROOT/references/scanner-adapter.md" 'auto' 'scanner-adapter mentions auto mode'

assert_grep "$SKILL_ROOT/references/scanner-adapter.md" 'run-scanner\.sh' 'scanner-adapter references run-scanner.sh'

assert_exec() {
  local name="$1" path="$2"
  if [[ -x "$SKILL_ROOT/$path" ]]; then ok "$name"; else bad "$name (not executable: $path)"; fi
}
assert_exec 'run-scanner.sh executable' 'scripts/run-scanner.sh'
bash "$SKILL_ROOT/scripts/run-scanner.sh" off -- 2>/dev/null \
  && { ok 'run-scanner off exits 0'; } || bad 'run-scanner off exits 0'

assert_file "$SKILL_ROOT/references/config-schema.md" 'config-schema.md exists'
assert_grep "$SKILL_ROOT/references/config-schema.md" 'verasic-config' 'config-schema points to verasic-config'

assert_file "$SKILL_ROOT/references/scanner-notes.md" 'scanner-notes.md exists'

assert_file "$SKILL_ROOT/checklists/security.md" 'checklist security.md exists'
assert_grep "$SKILL_ROOT/checklists/security.md" 'Injection' 'security checklist injection'

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
  assert_file "$COMMAND_FILE" 'cursor command verasic-security-review.md'
  assert_grep "$COMMAND_FILE" 'verasic-security-reviewer' 'command launches verasic-security-reviewer subagent'
  assert_grep "$COMMAND_FILE" 'security-review-protocol\.md' 'command references protocol'
else
  bad 'cursor command verasic-security-review.md (not found in source or install layout)'
fi

if [[ -n "$AGENT_FILE" ]]; then
  assert_file "$AGENT_FILE" 'cursor agent verasic-security-reviewer.md'
  assert_grep "$AGENT_FILE" '^name: verasic-security-reviewer' 'agent name frontmatter'
  assert_grep "$AGENT_FILE" 'security-review-protocol\.md' 'agent points to protocol'
else
  bad 'cursor agent verasic-security-reviewer.md (not found in source or install layout)'
fi

assert_grep "$SKILL_ROOT/README.md" '/verasic-security-review' 'README mentions command'
assert_grep "$SKILL_ROOT/README.md" 'verasic-security-reviewer' 'README mentions agent'

if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-security-review\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-security-review'
  else
    bad 'manifest lists verasic-security-review'
  fi
else
  ok 'manifest check skipped (installed layout)'
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
