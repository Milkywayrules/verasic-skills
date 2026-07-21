#!/usr/bin/env bash
set -euo pipefail

# Structural regression for verasic-deep-research. No AI harness required.

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

assert_yaml_field() {
  local file="$1" field="$2" name="$3"
  if [[ -f "$file" ]] && grep -qE "^${field}:" "$file" 2>/dev/null; then ok "$name"; else bad "$name"; fi
}

COMMAND_FILE=""
if [[ -f "$INSTALL_ROOT/cursor/commands/verasic-deep-research.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/cursor/commands/verasic-deep-research.md"
elif [[ -f "$INSTALL_ROOT/commands/verasic-deep-research.md" ]]; then
  COMMAND_FILE="$INSTALL_ROOT/commands/verasic-deep-research.md"
fi

EXPECTED_DOMAIN_PACKS=(
  technical
  ai-content-design
  health-fitness
  market-competitive
  claims-investigation
  creative-technical
  ecommerce-id
  small-business-id
  small-business-generic
  historical
  career-education
  creator-monetization
  generic
)

EXPECTED_WORKFLOWS=(
  quick-scan
  standard-research
  adversarial-deep
  custom
)

EXPECTED_PERSONAS=(
  hunter
  skeptic
  practitioner-generic
)

# --- SKILL router ---
assert_grep "$SKILL_ROOT/SKILL.md" '^name: verasic-deep-research' 'SKILL.md name frontmatter'
assert_grep "$SKILL_ROOT/SKILL.md" 'research-protocol\.md' 'SKILL.md points to protocol'
assert_grep "$SKILL_ROOT/SKILL.md" 'verify-before-cite' 'SKILL.md verify-before-cite rule'

# --- Core references (created by core agent) ---
assert_file "$SKILL_ROOT/references/research-protocol.md" 'research-protocol.md exists'
assert_file "$SKILL_ROOT/references/helper.md" 'helper.md exists'
assert_file "$SKILL_ROOT/references/citation-protocol.md" 'citation-protocol.md exists'
assert_file "$SKILL_ROOT/references/confidence-rubric.md" 'confidence-rubric.md exists'
assert_file "$SKILL_ROOT/references/drill-protocol.md" 'drill-protocol.md exists'
assert_file "$SKILL_ROOT/references/source-tiers.md" 'source-tiers.md exists'
assert_file "$SKILL_ROOT/references/fusion-handoff.md" 'fusion-handoff.md exists'
assert_file "$SKILL_ROOT/references/example-prompts.md" 'example-prompts.md exists'
assert_file "$SKILL_ROOT/README.md" 'README.md exists'
assert_file "$SKILL_ROOT/VERSION" 'VERSION exists'

assert_grep "$SKILL_ROOT/references/research-protocol.md" 'Pre-flight gate' 'protocol pre-flight gate'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'Verify-before-cite' 'protocol verify-before-cite'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'quick-scan' 'protocol quick-scan tier'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'standard-research' 'protocol standard-research tier'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'adversarial-deep' 'protocol adversarial-deep tier'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'Degraded path' 'protocol degraded path'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'No default output format' 'protocol no default output'

# --- Helper honesty ---
assert_grep "$SKILL_ROOT/references/helper.md" 'Honesty \(read this\)' 'helper honesty section'
assert_grep "$SKILL_ROOT/references/helper.md" 'Scores are estimates' 'helper scores are estimates'
assert_grep "$SKILL_ROOT/references/helper.md" 'Ask mode' 'helper ask mode notice'
assert_grep "$SKILL_ROOT/references/helper.md" 'quick-scan' 'helper lists quick-scan'
assert_grep "$SKILL_ROOT/references/helper.md" 'chat-only' 'helper lists chat-only output'

# --- 5-axis confidence rubric ---
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" '\*\*SQ\*\*' 'rubric SQ axis'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" '\*\*EC\*\*' 'rubric EC axis'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" '\*\*CG\*\*' 'rubric CG axis'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" '\*\*CO\*\*' 'rubric CO axis'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" '\*\*VR\*\*' 'rubric VR axis'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" 'Claim Grounding' 'rubric CG Claim Grounding'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" 'Evidence Convergence' 'rubric EC Evidence Convergence'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" 'Verification Rigor' 'rubric VR Verification Rigor'
assert_grep "$SKILL_ROOT/references/confidence-rubric.md" 'snippet-only.*hard cap 40' 'rubric snippet-only hard cap 40'

assert_grep "$SKILL_ROOT/references/research-protocol.md" 'fetch-url' 'protocol T3 fetch-url job'
assert_grep "$SKILL_ROOT/references/research-protocol.md" 'Skeptic.*sequential' 'protocol standard Skeptic sequential'

assert_grep "$SKILL_ROOT/references/drill-protocol.md" 'Auto-execute' 'drill auto-execute round 1'

assert_grep "$SKILL_ROOT/workflows/standard-research.md" 'Skeptic pass \(7a' 'standard-research mandatory Skeptic'

# --- Domain packs ---
for slug in "${EXPECTED_DOMAIN_PACKS[@]}"; do
  pf="$SKILL_ROOT/references/domain-packs/${slug}.yaml"
  if [[ -f "$pf" ]]; then
    ok "domain pack $slug"
    assert_yaml_field "$pf" 'id' "pack $slug has id"
    assert_yaml_field "$pf" 'parent' "pack $slug has parent"
    assert_yaml_field "$pf" 'persona' "pack $slug has persona"
    assert_yaml_field "$pf" 'axis_weights' "pack $slug has axis_weights"
    assert_yaml_field "$pf" 'floor' "pack $slug has floor"
    assert_yaml_field "$pf" 'ceiling' "pack $slug has ceiling"
    assert_yaml_field "$pf" 'recency_months' "pack $slug has recency_months"
    assert_yaml_field "$pf" 'source_hints' "pack $slug has source_hints"
    assert_yaml_field "$pf" 'example_prompts' "pack $slug has example_prompts"
    assert_yaml_field "$pf" 'warnings' "pack $slug has warnings"
    assert_grep "$pf" 'SQ:' "pack $slug axis_weights SQ"
    assert_grep "$pf" 'EC:' "pack $slug axis_weights EC"
    assert_grep "$pf" 'CG:' "pack $slug axis_weights CG"
    assert_grep "$pf" 'CO:' "pack $slug axis_weights CO"
    assert_grep "$pf" 'VR:' "pack $slug axis_weights VR"
  else
    bad "domain pack $slug (missing: $pf)"
  fi
done

# health-fitness floor 60
assert_grep "$SKILL_ROOT/references/domain-packs/health-fitness.yaml" '^floor: 60' 'health-fitness floor 60'

# small-business-generic fallback
assert_grep "$SKILL_ROOT/references/domain-packs/small-business-generic.yaml" '^parent: null' 'small-business-generic parent null'

# generic fallback
assert_grep "$SKILL_ROOT/references/domain-packs/generic.yaml" '^parent: null' 'generic parent null'

# exact example prompt spot checks
assert_grep "$SKILL_ROOT/references/domain-packs/technical.yaml" 'how does the elevator work\?' 'technical example elevator'
assert_grep "$SKILL_ROOT/references/domain-packs/claims-investigation.yaml" 'is World Cup 2026 rigged' 'claims-investigation example WC'
assert_grep "$SKILL_ROOT/references/example-prompts.md" 'how does the elevator work\?' 'example-prompts index elevator'

# --- Personas ---
for slug in "${EXPECTED_PERSONAS[@]}"; do
  pf="$SKILL_ROOT/references/personas/${slug}.md"
  if [[ -f "$pf" ]]; then
    ok "persona $slug"
    assert_grep "$pf" 'must_do' "persona $slug must_do"
    assert_grep "$pf" 'must_not' "persona $slug must_not"
    assert_grep "$pf" 'completion_criterion' "persona $slug completion_criterion"
  else
    bad "persona $slug (missing: $pf)"
  fi
done

# --- Workflows ---
for slug in "${EXPECTED_WORKFLOWS[@]}"; do
  wf="$SKILL_ROOT/workflows/${slug}.md"
  if [[ -f "$wf" ]]; then
    ok "workflow $slug"
    assert_grep "$wf" 'research-protocol\.md' "workflow $slug references protocol"
  else
    bad "workflow $slug (missing: $wf)"
  fi
done

# --- Templates ---
assert_file "$SKILL_ROOT/templates/deep-research-brief.md" 'template deep-research-brief.md'
assert_file "$SKILL_ROOT/templates/source-ledger.yaml" 'template source-ledger.yaml'

assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## answer' 'brief template answer section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## reasoning' 'brief template reasoning section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## confidence' 'brief template confidence section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## conflicts' 'brief template conflicts section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## claim ledger' 'brief template claim ledger section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## unverified' 'brief template unverified section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## references' 'brief template references section'
assert_grep "$SKILL_ROOT/templates/deep-research-brief.md" '## recommendation' 'brief template recommendation section'

assert_grep "$SKILL_ROOT/templates/source-ledger.yaml" 'fetch_status' 'source-ledger fetch_status field'
assert_grep "$SKILL_ROOT/templates/source-ledger.yaml" 'tier:' 'source-ledger tier field'
assert_grep "$SKILL_ROOT/templates/source-ledger.yaml" 'excerpt' 'source-ledger excerpt field'
assert_grep "$SKILL_ROOT/templates/source-ledger.yaml" 'claim_ids' 'source-ledger claim_ids field'

# --- Publish gate ---
assert_file "$SKILL_ROOT/integrity.txt" 'integrity.txt exists'
assert_file "$SKILL_ROOT/integrity.sha256" 'integrity.sha256 exists'
assert_file "$SKILL_ROOT/references/use-cases.md" 'use-cases.md exists'
assert_file "$SKILL_ROOT/scripts/test-exhaustive.sh" 'test-exhaustive.sh exists'
assert_file "$SKILL_ROOT/scripts/test-exhaustive-protocol.sh" 'test-exhaustive-protocol.sh exists'

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

assert_grep "$SKILL_ROOT/references/use-cases.md" 'UC-0' 'use-cases UC-0 help'
assert_grep "$SKILL_ROOT/references/use-cases.md" 'UC-7' 'use-cases UC-7 degraded'
assert_grep "$SKILL_ROOT/references/use-cases.md" 'Publish gate' 'use-cases publish gate checklist'


# --- Cursor command ---
if [[ -n "$COMMAND_FILE" ]]; then
  assert_file "$COMMAND_FILE" 'cursor command verasic-deep-research.md'
  assert_grep "$COMMAND_FILE" 'research-protocol\.md' 'command points to protocol'
  assert_grep "$COMMAND_FILE" 'helper\.md' 'command points to helper'
  assert_grep "$COMMAND_FILE" 'Pre-flight' 'command pre-flight rules'
  assert_grep "$COMMAND_FILE" 'Ask mode' 'command ask mode rule'
else
  bad 'cursor command verasic-deep-research.md (not found in source or install layout)'
fi

# --- Manifest (source tree) ---
if $IS_SOURCE_TREE; then
  MANIFEST="$INSTALL_ROOT/skills/verasic-init/manifest.txt"
  if grep -qE '^verasic-deep-research\|' "$MANIFEST" 2>/dev/null; then
    ok 'manifest lists verasic-deep-research'
  else
    bad 'manifest lists verasic-deep-research'
  fi
  if grep -q 'verasic-deep-research' "$INSTALL_ROOT/README.md" 2>/dev/null; then
    ok 'root README mentions verasic-deep-research'
  else
    bad 'root README mentions verasic-deep-research'
  fi
else
  ok 'manifest check skipped (installed layout)'
  ok 'root README check skipped (installed layout)'
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
