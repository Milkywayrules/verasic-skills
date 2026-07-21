#!/usr/bin/env bash
set -euo pipefail

# Protocol-level exhaustive checks (no AI harness). Validates pre-flight rules
# documented in references/use-cases.md UC-1, UC-6, UC-7.

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROTO="$SKILL_ROOT/references/research-protocol.md"
RUBRIC="$SKILL_ROOT/references/confidence-rubric.md"
DRILL="$SKILL_ROOT/references/drill-protocol.md"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

assert_grep() {
  local file="$1" pattern="$2" name="$3"
  if grep -qE "$pattern" "$file" 2>/dev/null; then ok "$name"; else bad "$name"; fi
}

# UC-1: pre-flight required fields documented
for field in Question depth output source-boundary Languages; do
  assert_grep "$PROTO" "$field" "UC-1 protocol lists pre-flight field $field"
done
assert_grep "$PROTO" 'If any required field is missing' 'UC-1 protocol blocks on missing fields'
assert_grep "$PROTO" 'No default output format' 'UC-1 protocol no default output'

# T3 four leaf jobs
assert_grep "$PROTO" '`fetch-url`' 'T3 job fetch-url'
assert_grep "$PROTO" '`extract-excerpt`' 'T3 job extract-excerpt'
assert_grep "$PROTO" '`single-query-search`' 'T3 job single-query-search'
assert_grep "$PROTO" '`verify-one-claim`' 'T3 job verify-one-claim'

# standard-research Skeptic sequential
assert_grep "$PROTO" 'Skeptic.*sequential' 'standard Skeptic sequential'
assert_grep "$PROTO" 'parallel merge \(step 7a\)' 'Skeptic after parallel merge'

# drill auto round 1
assert_grep "$DRILL" 'Auto-execute' 'drill auto-execute round 1'
assert_grep "$PROTO" 'auto-at-threshold.*auto-executes round 1' 'protocol drill auto round 1'

# snippet cap 40
assert_grep "$PROTO" '40-word' 'protocol excerpt cap 40 words'
assert_grep "$RUBRIC" 'snippet-only.*hard cap 40' 'rubric snippet-only hard cap 40'

# 5-axis names (SQ EC CG CO VR + long names)
for axis in 'SQ' 'EC' 'CG' 'CO' 'VR'; do
  assert_grep "$RUBRIC" "\\*\\*${axis}\\*\\*" "rubric axis $axis"
done
assert_grep "$RUBRIC" 'Claim Grounding' 'rubric Claim Grounding'
assert_grep "$RUBRIC" 'Evidence Convergence' 'rubric Evidence Convergence'
assert_grep "$RUBRIC" 'Verification Rigor' 'rubric Verification Rigor'

# UC-6 Ask mode
assert_grep "$PROTO" 'Ask mode' 'UC-6 protocol Ask mode'
assert_grep "$PROTO" 'never write files' 'UC-6 protocol never write files in Ask mode'

# UC-7 degraded path
assert_grep "$PROTO" 'Degraded path' 'UC-7 protocol degraded path'

assert_grep "$SKILL_ROOT/references/helper.md" 'Honesty \(read this\)' 'UC-0 helper honesty'

echo "---"
echo "exhaustive-protocol: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
