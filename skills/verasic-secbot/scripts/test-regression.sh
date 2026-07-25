#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-secbot. No AI harness required.

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_ROOT="$(cd "$SKILL_ROOT/../.." && pwd)"
REPO_ROOT="$INSTALL_ROOT"
if git -C "$SKILL_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SKILL_ROOT" rev-parse --show-toplevel)"
fi
IS_SOURCE_TREE=false
if [[ -f "$INSTALL_ROOT/README.md" && -d "$INSTALL_ROOT/cursor/agents" && -d "$INSTALL_ROOT/skills/verasic-init" ]]; then
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

AGENT_FILE=""
if $IS_SOURCE_TREE; then
  AGENT_FILE="$INSTALL_ROOT/cursor/agents/verasic-secbot-reviewer.md"
elif [[ -f "$REPO_ROOT/.cursor/agents/verasic-secbot-reviewer.md" ]]; then
  AGENT_FILE="$REPO_ROOT/.cursor/agents/verasic-secbot-reviewer.md"
fi

PROTO="$SKILL_ROOT/references/security-review-protocol.md"

assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-secbot' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'security-review-protocol\.md' 'SKILL.md points to protocol'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-secbot-reviewer' 'SKILL.md spawns verasic-secbot-reviewer'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-agent-disclosure' 'SKILL.md strips internals per disclosure'
assert_grep "$SKILL_ROOT/SKILL.md" '/verasic-bugbot' 'SKILL.md cross-tip to verasic-bugbot'
if grep -qE 'resolve-config|verasic-config' "$SKILL_ROOT/SKILL.md" 2>/dev/null; then
  bad 'SKILL.md has no resolve-config dependency'
else
  ok 'SKILL.md has no resolve-config dependency'
fi

assert_file "$PROTO" 'security-review-protocol.md exists'
assert_file "$SKILL_ROOT/README.md" 'README.md exists'
assert_file "$SKILL_ROOT/VERSION" 'VERSION exists'
assert_grep "$SKILL_ROOT/VERSION" '^0\.2\.0' 'VERSION is 0.2.0'

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
assert_grep "$SKILL_ROOT/references/config-schema.md" 'secbot-local defaults' 'config-schema is secbot-local defaults'
if grep -qE 'verasic-config|resolve-config' "$SKILL_ROOT/references/config-schema.md" 2>/dev/null; then
  bad 'config-schema has no verasic-config dependency'
else
  ok 'config-schema has no verasic-config dependency'
fi

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

assert_grep "$SKILL_ROOT/SKILL.md" '## Orchestration \(Cursor\)' 'SKILL.md orchestration section'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-secbot-reviewer' 'SKILL.md spawns verasic-secbot-reviewer'
assert_grep "$SKILL_ROOT/SKILL.md" '[Rr]elay the subagent report verbatim' 'SKILL.md relay verbatim rule'
assert_grep "$SKILL_ROOT/SKILL.md" 'inlined defaults' 'SKILL.md uses inlined defaults not repo config'
assert_grep "$SKILL_ROOT/SKILL.md" 'disable-model-invocation: true' 'SKILL.md disable-model-invocation frontmatter'

if [[ -n "$AGENT_FILE" ]]; then
  assert_file "$AGENT_FILE" 'cursor agent verasic-secbot-reviewer.md'
  assert_grep "$AGENT_FILE" '^name: verasic-secbot-reviewer' 'agent name frontmatter'
  assert_grep "$AGENT_FILE" 'security-review-protocol\.md' 'agent points to protocol'
  assert_grep "$AGENT_FILE" 'verasic-secbot/' 'agent points to secbot skill folder'
else
  bad 'cursor agent verasic-secbot-reviewer.md (not found in source or install layout)'
fi

assert_grep "$SKILL_ROOT/README.md" '/verasic-secbot' 'README mentions secbot slash'
assert_grep "$SKILL_ROOT/README.md" 'verasic-secbot-reviewer' 'README mentions secbot agent'

if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-secbot\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-secbot'
  else
    bad 'manifest lists verasic-secbot'
  fi
else
  ok 'manifest check skipped (installed layout)'
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
