#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-git-commits-audit (thin orchestration skill).

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
  AGENT_FILE="$INSTALL_ROOT/cursor/agents/verasic-git-commit-auditor.md"
elif [[ -f "$REPO_ROOT/.cursor/agents/verasic-git-commit-auditor.md" ]]; then
  AGENT_FILE="$REPO_ROOT/.cursor/agents/verasic-git-commit-auditor.md"
fi

assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-git-commits-audit' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'disable-model-invocation: true' 'SKILL.md disable-model-invocation frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-git-commit-auditor' 'SKILL.md spawns verasic-git-commit-auditor'
assert_grep "$SKILL_ROOT/SKILL.md" 'audit-protocol\.md' 'SKILL.md points to audit-protocol'
assert_grep "$SKILL_ROOT/SKILL.md" 'verasic-git-commits-convention' 'SKILL.md references convention skill'

assert_grep "$SKILL_ROOT/SKILL.md" '## Orchestration \(Cursor\)' 'SKILL.md orchestration section'
assert_grep "$SKILL_ROOT/SKILL.md" 'Full Repository Path:' 'SKILL.md spawn prompt has repository path'
assert_grep "$SKILL_ROOT/SKILL.md" 'Flags:' 'SKILL.md spawn prompt has flags line'
assert_grep "$SKILL_ROOT/SKILL.md" 'Follow your system prompt fully' 'SKILL.md spawn prompt matches audit-commits command'
assert_grep "$SKILL_ROOT/SKILL.md" 'relay its report verbatim' 'SKILL.md relay report verbatim'
assert_grep "$SKILL_ROOT/SKILL.md" '--help' 'SKILL.md --help gate'
assert_grep "$SKILL_ROOT/SKILL.md" 'read-only' 'SKILL.md audit read-only'
assert_grep "$SKILL_ROOT/SKILL.md" 'fix-trailers' 'SKILL.md fix-mode boundary'
assert_grep "$SKILL_ROOT/SKILL.md" '/verasic-git-commits-convention' 'SKILL.md cross-tip to convention skill'

assert_file "$SKILL_ROOT/README.md" 'README.md exists'
assert_file "$SKILL_ROOT/VERSION" 'VERSION exists'

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

if [[ -n "$AGENT_FILE" ]]; then
  assert_file "$AGENT_FILE" 'cursor agent verasic-git-commit-auditor.md'
  assert_grep "$AGENT_FILE" '^name: verasic-git-commit-auditor' 'agent name frontmatter'
  assert_grep "$AGENT_FILE" 'audit-protocol\.md' 'agent points to audit-protocol'
else
  bad 'cursor agent verasic-git-commit-auditor.md (not found in source or install layout)'
fi

if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-git-commits-audit\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-git-commits-audit'
  else
    bad 'manifest lists verasic-git-commits-audit'
  fi
else
  ok 'manifest check skipped (installed layout)'
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
