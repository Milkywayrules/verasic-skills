#!/usr/bin/env bash
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$SKILL_ROOT/hooks/commit-msg"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

assert() {
  local name="$1" cmd="$2"
  if ( eval "$cmd" ); then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name"
    fail=$((fail + 1))
  fi
}

assert_fail() {
  local name="$1" cmd="$2"
  if ( eval "$cmd" ); then
    echo "FAIL (expected error): $name"
    fail=$((fail + 1))
  else
    echo "PASS: $name"
    pass=$((pass + 1))
  fi
}

run_hook() {
  local msgfile="$1"
  bash "$HOOK" "$msgfile" 2>"$msgfile.stderr" || return $?
  return 0
}

run_hook_expect_fail() {
  local msgfile="$1"
  if bash "$HOOK" "$msgfile" 2>"$msgfile.stderr"; then
    return 0
  fi
  return 1
}

msgfile="$TMP/valid.msg"
printf '%s\n' 'feat: add widget loader' '' 'loads widgets on startup.' > "$msgfile"
assert "valid subject passes" "run_hook '$msgfile'"

msgfile="$TMP/bad-type.msg"
printf '%s\n' 'feature: add widget' > "$msgfile"
assert_fail "invalid type rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/uppercase.msg"
printf '%s\n' 'feat: Add widget loader' > "$msgfile"
assert_fail "uppercase first word rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/period.msg"
printf '%s\n' 'feat: add widget loader.' > "$msgfile"
assert_fail "trailing period rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/no-blank.msg"
printf '%s\n' 'feat: add widget loader' 'missing blank line before body.' > "$msgfile"
assert_fail "no blank line before body rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/docker.msg"
printf '%s\n' 'feat: Docker support' > "$msgfile"
assert_fail "feat: Docker support rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/empty-summary.msg"
printf '%s\n' 'feat:  ' > "$msgfile"
assert_fail "empty summary rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/empty-scope.msg"
printf '%s\n' 'feat(): add widget' > "$msgfile"
assert_fail "empty scope rejected" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/breaking.msg"
printf '%s\n' 'feat!: drop legacy config format' > "$msgfile"
assert "breaking-change marker passes" "run_hook '$msgfile'"

msgfile="$TMP/breaking-scope.msg"
printf '%s\n' 'feat(api)!: drop v1 endpoints' > "$msgfile"
assert "scoped breaking-change marker passes" "run_hook '$msgfile'"

msgfile="$TMP/only-attribution.msg"
printf '%s\n' 'Co-authored-by: Cursor <cursoragent@cursor.com>' > "$msgfile"
assert_fail "attribution-only message rejected after strip" "run_hook_expect_fail '$msgfile'"

msgfile="$TMP/api.msg"
printf '%s\n' 'feat: API rate limiter' > "$msgfile"
assert "feat: API rate limiter passes" "run_hook '$msgfile'"

msgfile="$TMP/tab.msg"
printf '%s\n' 'feat: TabOverview crash fix' > "$msgfile"
assert "feat: TabOverview crash fix passes" "run_hook '$msgfile'"

msgfile="$TMP/merge.msg"
printf '%s\n' 'Merge branch main into feature' > "$msgfile"
assert "Merge passthrough" "run_hook '$msgfile'"

msgfile="$TMP/revert.msg"
printf '%s\n' 'Revert "feat: add widget"' > "$msgfile"
assert "Revert passthrough" "run_hook '$msgfile'"

msgfile="$TMP/empty.msg"
: > "$msgfile"
assert "empty file passes" "run_hook '$msgfile'"

msgfile="$TMP/coauthor.msg"
printf '%s\n' 'feat: add widget' '' 'loads widgets.' 'Co-authored-by: Cursor <cursoragent@cursor.com>' > "$msgfile"
run_hook "$msgfile"
if grep -qiE '^co-authored-by:' "$msgfile"; then
  echo "FAIL: Co-authored-by line not stripped"
  fail=$((fail + 1))
else
  echo "PASS: Co-authored-by line stripped"
  pass=$((pass + 1))
fi

msgfile="$TMP/generated.msg"
printf '%s\n' 'feat: add widget' '' '🤖 Generated with [Claude Code](https://claude.com)' > "$msgfile"
run_hook "$msgfile"
if grep -qiE '^🤖|generated with \[' "$msgfile"; then
  echo "FAIL: Generated-with line not stripped"
  fail=$((fail + 1))
else
  echo "PASS: Generated-with line stripped"
  pass=$((pass + 1))
fi

msgfile="$TMP/signed-ai.msg"
printf '%s\n' 'feat: add widget' '' 'Signed-off-by: AI' > "$msgfile"
run_hook "$msgfile"
if grep -qiE '^signed-off-by:.*\bai\b' "$msgfile"; then
  echo "FAIL: Signed-off-by: AI not stripped"
  fail=$((fail + 1))
else
  echo "PASS: Signed-off-by: AI stripped"
  pass=$((pass + 1))
fi

msgfile="$TMP/signed-human.msg"
printf '%s\n' 'feat: add widget' '' 'Signed-off-by: Claude Martin <claude@example.fr>' > "$msgfile"
run_hook "$msgfile"
if grep -qiF 'Signed-off-by: Claude Martin <claude@example.fr>' "$msgfile"; then
  echo "PASS: human Signed-off-by preserved"
  pass=$((pass + 1))
else
  echo "FAIL: human Signed-off-by stripped"
  fail=$((fail + 1))
fi

msgfile="$TMP/ai-voice.msg"
printf '%s\n' 'feat: add settings panel' '' 'as requested, I added the settings panel.' > "$msgfile"
if run_hook "$msgfile" && grep -q 'warning' "$msgfile.stderr"; then
  echo "PASS: AI-language body warns on stderr but exits 0"
  pass=$((pass + 1))
else
  echo "FAIL: AI-language body should warn on stderr and exit 0"
  fail=$((fail + 1))
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
