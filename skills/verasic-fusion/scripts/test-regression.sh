#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-fusion. No AI harness required.

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_ROOT="$(cd "$SKILL_ROOT/../.." && pwd)"
IS_SOURCE_TREE=false
[[ -d "$INSTALL_ROOT/skills/verasic-init" ]] && IS_SOURCE_TREE=true

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
if [[ -f "$INSTALL_ROOT/cursor/commands/verasic-fusion.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/cursor/commands/verasic-fusion.md"
elif [[ -f "$INSTALL_ROOT/commands/verasic-fusion.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/commands/verasic-fusion.md"
fi

EXPECTED_TEMPLATES=(
  board-verdict
  rfc-review
  tradeoff-matrix
  research-brief
  risk-register
  devils-advocate
  premortem
  stakeholder-lens
  compare-to-status-quo
)

assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-fusion' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'fusion-protocol\.md' 'SKILL.md points to protocol'

assert_file "$SKILL_ROOT/references/fusion-protocol.md" 'fusion-protocol.md exists'
assert_file "$SKILL_ROOT/references/helper.md" 'helper.md exists'
assert_file "$SKILL_ROOT/references/models.md" 'models.md exists'
assert_file "$SKILL_ROOT/references/use-cases.md" 'use-cases.md exists'
assert_file "$SKILL_ROOT/README.md" 'README.md exists'

assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'Soft cap \*\*4\*\*' 'protocol soft cap 4'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'Hard cap \*\*6\*\*' 'protocol hard cap 6'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" '`verbatim`' 'protocol verbatim mode'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" '`fusion`' 'protocol fusion mode'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'verbatim\+fusion' 'protocol verbatim+fusion mode'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'No default models' 'protocol no default models'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'never be silently flattened' 'protocol conflict rule'
assert_grep "$SKILL_ROOT/references/fusion-protocol.md" 'Degraded path' 'protocol degraded path'

assert_grep "$SKILL_ROOT/references/helper.md" 'mode: verbatim' 'helper lists modes'
assert_grep "$SKILL_ROOT/references/models.md" 'composer-2.5-fast' 'models includes composer-2.5-fast'

for slug in "${EXPECTED_TEMPLATES[@]}"; do
  assert_grep "$SKILL_ROOT/references/fusion-protocol.md" "\`${slug}\`" "protocol registry $slug"
  assert_grep "$SKILL_ROOT/references/helper.md" "\`${slug}\`" "helper lists $slug"
  assert_grep "$SKILL_ROOT/references/use-cases.md" "\`${slug}\`" "use-cases covers $slug"

  tf="$SKILL_ROOT/templates/${slug}.md"
  if [[ -f "$tf" ]]; then
    ok "template file $slug"
    assert_grep "$tf" 'Fusion mapping' "template $slug fusion mapping"
  else
    bad "template file $slug (missing)"
  fi
done

if [[ -n "$COMMAND_FILE" ]]; then
  assert_file "$COMMAND_FILE" 'cursor command verasic-fusion.md'
  assert_grep "$COMMAND_FILE" 'fusion-protocol\.md' 'command points to protocol'
  assert_grep "$COMMAND_FILE" 'No default models' 'command no default models'
else
  bad 'cursor command verasic-fusion.md (not found in source or install layout)'
fi

if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-fusion\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-fusion'
  else
    bad 'manifest lists verasic-fusion'
  fi
  if grep -q 'verasic-fusion' "$INSTALL_ROOT/README.md" 2>/dev/null; then
    ok 'root README mentions verasic-fusion'
  else
    bad 'root README mentions verasic-fusion'
  fi
else
  ok 'manifest check skipped (installed layout)'
  ok 'root README check skipped (installed layout)'
fi

assert_grep "$SKILL_ROOT/templates/stakeholder-lens.md" 'lens-map' 'stakeholder-lens requires lens-map'
assert_grep "$SKILL_ROOT/templates/stakeholder-lens.md" 'No round-robin' 'stakeholder-lens no round-robin'
assert_grep "$SKILL_ROOT/templates/tradeoff-matrix.md" 'Must-haves' 'tradeoff-matrix must-haves'
assert_grep "$SKILL_ROOT/templates/tradeoff-matrix.md" 'Sensitivity' 'tradeoff-matrix sensitivity'
assert_grep "$SKILL_ROOT/templates/devils-advocate.md" 'against' 'devils-advocate argues against'
assert_grep "$SKILL_ROOT/references/use-cases.md" 'UC-11' 'use-cases UC-11 rfc-review'
assert_grep "$SKILL_ROOT/references/use-cases.md" 'UC-14' 'use-cases UC-14 compare-to-status-quo'

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
