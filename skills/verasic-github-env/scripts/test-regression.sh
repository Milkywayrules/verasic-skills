#!/usr/bin/env bash
set -euo pipefail

# hermetic: ignore credentials inherited from the calling shell
unset GH_TOKEN GH_REPO GITHUB_TOKEN 2>/dev/null || true

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

assert_stderr_contains() {
  local name="$1" cmd="$2" needle="$3"
  local stderr
  if stderr="$( eval "cd \"$TMP/repo\" && $cmd" 2>&1 >/dev/null )"; then
    echo "FAIL (expected error): $name"
    fail=$((fail + 1))
  elif [[ "$stderr" == *"$needle"* ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name (stderr missing '$needle')"
    fail=$((fail + 1))
  fi
}

setup_repo() {
  local dir="$1"
  mkdir -p "$dir/.cursor/skills"
  cp -r "$SKILL_ROOT" "$dir/.cursor/skills/verasic-github-env"
  cd "$dir"
  git init -q -b main
  git remote add origin git@github.com:Milkywayrules/usecharator.git
}

mkdir -p "$TMP/repo"
setup_repo "$TMP/repo"

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
assert_stderr_contains \
  "check-gh prints diagnostic on fake token" \
  "bash .cursor/skills/verasic-github-env/scripts/check-gh.sh" \
  "check-gh:"

rm -f .github-agent.local
assert_fail "check-gh missing token" "bash .cursor/skills/verasic-github-env/scripts/check-gh.sh"

printf '%s\n' 'GH_TOKEN=fake_token_for_test' 'GH_REPO=Milkywayrules/usecharator' > .github-agent.local
chmod 600 .github-agent.local
mkdir -p sub
assert \
  "load-gh-env source-safe from subdir" \
  "bash -c 'set +eu; cd sub; source \"../.cursor/skills/verasic-github-env/scripts/load-gh-env.sh\"; [[ \"\$-\" != *e* && \"\$-\" != *u* ]] && [[ \"\$(pwd)\" == */sub ]] && [[ -n \"\$GH_TOKEN\" ]] && ! type _verasic_extract_var >/dev/null 2>&1'"
assert \
  "load-gh-env preset GH_TOKEN wins" \
  "bash -c 'set +eu; export GH_TOKEN=preset; source .cursor/skills/verasic-github-env/scripts/load-gh-env.sh; [[ \"\$GH_TOKEN\" == preset ]]'"

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

env_local_count="$(grep -c '^\.env\.local$' .gitignore || true)"
if [[ "$env_local_count" -le 1 ]]; then
  echo "PASS: bootstrap no duplicate .env.local with .env* ignore"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap duplicate .env.local lines (count=$env_local_count)"
  fail=$((fail + 1))
fi

# fresh repo: .gitignore with only `.env` does not ignore `.env.local` — bootstrap must append it
mkdir -p "$TMP/env-only"
setup_repo "$TMP/env-only"
printf '%s\n' '.env' > .gitignore
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
if ( cd "$TMP/env-only" && git check-ignore -q .env.local ); then
  echo "PASS: bootstrap adds .env.local when only .env ignored"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap adds .env.local when only .env ignored"
  fail=$((fail + 1))
fi

# fresh repo: `nested/.github-agent.local` in .gitignore must not count as covering the root file
mkdir -p "$TMP/nested-pat"
setup_repo "$TMP/nested-pat"
printf '%s\n' 'nested/.github-agent.local' > .gitignore
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
if ( cd "$TMP/nested-pat" && git check-ignore -q .github-agent.local ); then
  echo "PASS: root .github-agent.local ignored despite nested pattern"
  pass=$((pass + 1))
else
  echo "FAIL: root .github-agent.local not ignored (nested pattern fooled bootstrap)"
  fail=$((fail + 1))
fi

# fresh repo: a machine-global excludesfile must not stop bootstrap writing the repo .gitignore line
mkdir -p "$TMP/global-ignore"
setup_repo "$TMP/global-ignore"
printf '%s\n' 'node_modules' > .gitignore
printf '%s\n' '.env.local' '.github-agent.local' > "$TMP/global-excludes"
git config core.excludesFile "$TMP/global-excludes"
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
if grep -q '^\.env\.local$' .gitignore && grep -q '^\.github-agent\.local$' .gitignore; then
  echo "PASS: repo .gitignore written despite global excludesfile"
  pass=$((pass + 1))
else
  echo "FAIL: repo .gitignore missing secret lines when global excludesfile covers them"
  fail=$((fail + 1))
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
