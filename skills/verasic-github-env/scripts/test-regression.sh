#!/usr/bin/env bash
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

assert() {
  local name="$1" cmd="$2"
  if ( eval "cd \"$TMP/repo\" && $cmd" ); then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name"
    fail=$((fail + 1))
  fi
}

assert_fail() {
  local name="$1" cmd="$2"
  if ( eval "cd \"$TMP/repo\" && $cmd" ); then
    echo "FAIL (expected error): $name"
    fail=$((fail + 1))
  else
    echo "PASS: $name"
    pass=$((pass + 1))
  fi
}

mkdir -p "$TMP/repo/.cursor/skills"
cp -r "$SKILL_ROOT" "$TMP/repo/.cursor/skills/verasic-github-env"
cd "$TMP/repo"
git init -q -b main
git remote add origin git@github.com:Milkywayrules/usecharator.git

bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
assert "creates .envrc" "test -f .envrc"
assert "creates .env.example with GH_REPO" "grep -q '^GH_REPO=Milkywayrules/usecharator' .env.example"
assert "creates github-agent example" "test -f .github-agent.local.example"

bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
count="$(grep -c '^GH_TOKEN=' .env.example || true)"
if [[ "$count" -eq 1 ]]; then
  echo "PASS: bootstrap idempotent"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap idempotent (count=$count)"
  fail=$((fail + 1))
fi

printf '%s\n' 'GH_TOKEN=fake_token_for_test' 'GH_REPO=Milkywayrules/usecharator' > .github-agent.local
chmod 600 .github-agent.local
assert_fail "check-gh rejects fake token" "bash .cursor/skills/verasic-github-env/scripts/check-gh.sh"

rm -f .github-agent.local
assert_fail "check-gh missing token" "bash .cursor/skills/verasic-github-env/scripts/check-gh.sh"

printf '%s\n' '.env*' > .gitignore
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
if git check-ignore -q .env.example 2>/dev/null; then
  echo "FAIL: .env.example still ignored after .env* bootstrap"
  fail=$((fail + 1))
else
  echo "PASS: .env.example committable with .env* ignore"
  pass=$((pass + 1))
fi

source "$SKILL_ROOT/scripts/parse-gh-repo.sh"

assert_parse() {
  local name="$1" url="$2" expected="$3"
  local actual
  if actual="$(verasic_parse_gh_repo_from_remote "$url")" && [[ "$actual" == "$expected" ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name (got '${actual:-}', expected '$expected')"
    fail=$((fail + 1))
  fi
}

assert_parse_fail() {
  local name="$1" url="$2"
  if verasic_parse_gh_repo_from_remote "$url" >/dev/null 2>&1; then
    echo "FAIL (expected error): $name"
    fail=$((fail + 1))
  else
    echo "PASS: $name"
    pass=$((pass + 1))
  fi
}

assert_parse "parse scp form" 'git@github.com:owner/repo.git' 'owner/repo'
assert_parse "parse https+.git" 'https://github.com/owner/repo.git' 'owner/repo'
assert_parse "parse https" 'https://github.com/owner/repo' 'owner/repo'
assert_parse "parse http" 'http://github.com/owner/repo' 'owner/repo'
assert_parse "parse ssh+.git" 'ssh://git@github.com/owner/repo.git' 'owner/repo'
assert_parse "parse ssh" 'ssh://git@github.com/owner/repo' 'owner/repo'
assert_parse "parse ssh over https port" 'ssh://git@ssh.github.com:443/owner/repo.git' 'owner/repo'

assert_parse_fail "parse reject gitlab scp" 'git@gitlab.com:owner/repo.git'
assert_parse_fail "parse reject evil host" 'https://github.com.evil.com/owner/repo'
assert_parse_fail "parse reject missing repo" 'https://github.com/owner'
assert_parse_fail "parse reject extra path" 'https://github.com/owner/repo/extra'

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
