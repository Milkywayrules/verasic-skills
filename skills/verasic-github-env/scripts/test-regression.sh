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
printf '%s\n' 'GH_TOKEN=' 'GH_REPO=Milkywayrules/usecharator' > .github-agent.local
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

# fresh repo: a negation rule (`!.env.local`) matches check-ignore --verbose while the
# file stays committable — bootstrap must still end with the file actually ignored
mkdir -p "$TMP/negation"
setup_repo "$TMP/negation"
printf '%s\n' '!.env.local' '!.github-agent.local' > .gitignore
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
if git check-ignore -q .env.local && git check-ignore -q .github-agent.local; then
  echo "PASS: secrets ignored despite pre-existing negation rules"
  pass=$((pass + 1))
else
  echo "FAIL: negation rule left a secret file committable"
  fail=$((fail + 1))
fi

# fresh repo: a git-tracked secret file must turn bootstrap into exit 3 (action needed)
mkdir -p "$TMP/tracked-secret"
setup_repo "$TMP/tracked-secret"
printf 'GH_TOKEN=oops\n' > .github-agent.local
git add .github-agent.local
git -c user.email=t@t -c user.name=t commit -qm 'chore: seed'
rc=0
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null 2>&1 || rc=$?
if [[ "$rc" -eq 3 ]]; then
  echo "PASS: tracked secret file makes bootstrap exit 3"
  pass=$((pass + 1))
else
  echo "FAIL: tracked secret file should exit 3 (got $rc)"
  fail=$((fail + 1))
fi

# fresh repo: .env.example with only GH_REPO must gain GH_TOKEN without duplicating GH_REPO
mkdir -p "$TMP/partial-example"
setup_repo "$TMP/partial-example"
printf 'GH_REPO=acme/other\n' > .env.example
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null
tok_count="$(grep -c '^GH_TOKEN=' .env.example || true)"
repo_count="$(grep -c '^GH_REPO=' .env.example || true)"
if [[ "$tok_count" -eq 1 && "$repo_count" -eq 1 ]]; then
  echo "PASS: partial .env.example completed without duplicates"
  pass=$((pass + 1))
else
  echo "FAIL: partial .env.example (GH_TOKEN=$tok_count GH_REPO=$repo_count)"
  fail=$((fail + 1))
fi

# export-prefixed lines must load (direnv accepts them)
mkdir -p "$TMP/export-prefix"
setup_repo "$TMP/export-prefix"
printf '%s\n' 'export GH_TOKEN=exported_token' 'export GH_REPO=acme/exported' > .github-agent.local
if ( set +eu; unset GH_TOKEN GH_REPO
     source .cursor/skills/verasic-github-env/scripts/load-gh-env.sh
     [[ "$GH_TOKEN" == exported_token && "$GH_REPO" == acme/exported ]] ); then
  echo "PASS: load-gh-env reads export-prefixed lines"
  pass=$((pass + 1))
else
  echo "FAIL: load-gh-env reads export-prefixed lines"
  fail=$((fail + 1))
fi

# loose credential-file permissions must warn (check still fails on fake token)
mkdir -p "$TMP/loose-perms"
setup_repo "$TMP/loose-perms"
printf '%s\n' 'GH_TOKEN=fake' 'GH_REPO=acme/x' > .github-agent.local
chmod 644 .github-agent.local
warn_out="$(bash .cursor/skills/verasic-github-env/scripts/check-gh.sh 2>&1 >/dev/null || true)"
if [[ "$warn_out" == *"chmod 600"* ]]; then
  echo "PASS: check-gh warns on loose credential permissions"
  pass=$((pass + 1))
else
  echo "FAIL: check-gh missing chmod warning for mode 644"
  fail=$((fail + 1))
fi

# bootstrap auto-chmod on loose credential file
mkdir -p "$TMP/auto-chmod"
setup_repo "$TMP/auto-chmod"
printf '%s\n' 'GH_TOKEN=' 'GH_REPO=acme/x' > .github-agent.local
chmod 644 .github-agent.local
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null 2>&1 || true
mode="$(stat -c '%a' .github-agent.local 2>/dev/null || stat -f '%Lp' .github-agent.local)"
if [[ "$mode" == 600 || "$mode" == 400 ]]; then
  echo "PASS: bootstrap auto-chmod credential file"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap auto-chmod (mode=$mode)"
  fail=$((fail + 1))
fi

# bootstrap --no-chmod preserves loose mode
mkdir -p "$TMP/no-chmod"
setup_repo "$TMP/no-chmod"
printf '%s\n' 'GH_TOKEN=' 'GH_REPO=acme/x' > .github-agent.local
chmod 644 .github-agent.local
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh --no-chmod >/dev/null 2>&1 || true
mode="$(stat -c '%a' .github-agent.local 2>/dev/null || stat -f '%Lp' .github-agent.local)"
if [[ "$mode" == 644 ]]; then
  echo "PASS: bootstrap --no-chmod skips chmod"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap --no-chmod should preserve 644 (mode=$mode)"
  fail=$((fail + 1))
fi

# bootstrap scaffolds .github-agent.local when missing
mkdir -p "$TMP/scaffold"
setup_repo "$TMP/scaffold"
bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh >/dev/null 2>&1 || true
if [[ -f .github-agent.local ]]; then
  echo "PASS: bootstrap scaffolds .github-agent.local"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap scaffolds .github-agent.local"
  fail=$((fail + 1))
fi

# bootstrap conditional verify skip without token
mkdir -p "$TMP/verify-skip"
setup_repo "$TMP/verify-skip"
out="$(bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh 2>&1 || true)"
if [[ "$out" == *"verify: skipped (no token)"* ]]; then
  echo "PASS: bootstrap verify skipped without token"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap verify skip message missing"
  fail=$((fail + 1))
fi

# bootstrap conditional verify run with fake token exits 3
mkdir -p "$TMP/verify-fail"
setup_repo "$TMP/verify-fail"
printf '%s\n' 'GH_TOKEN=fake_token_for_test' 'GH_REPO=Milkywayrules/usecharator' > .github-agent.local
chmod 600 .github-agent.local
rc=0
out="$(bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh 2>&1)" || rc=$?
if [[ "$rc" -eq 3 && "$out" == *"verify: failed"* ]]; then
  echo "PASS: bootstrap verify fails on fake token (exit 3)"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap verify fake token (rc=$rc)"
  fail=$((fail + 1))
fi

# bootstrap reports credential source
mkdir -p "$TMP/cred-src"
setup_repo "$TMP/cred-src"
printf '%s\n' 'GH_TOKEN=abc' 'GH_REPO=acme/x' > .github-agent.local
chmod 600 .github-agent.local
out="$(bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh 2>&1 || true)"
if [[ "$out" == *"credential source: .github-agent.local"* ]]; then
  echo "PASS: bootstrap reports credential source"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap credential source line missing"
  fail=$((fail + 1))
fi

# migration nudge when GH_* only in .env.local
mkdir -p "$TMP/migrate"
setup_repo "$TMP/migrate"
printf '%s\n' 'GH_TOKEN=legacy' 'GH_REPO=acme/x' > .env.local
chmod 600 .env.local
out="$(bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh 2>&1 || true)"
if [[ "$out" == *"migration nudge"* && "$out" == *"credential source: .env.local"* ]]; then
  echo "PASS: bootstrap migration nudge for .env.local"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap migration nudge missing"
  fail=$((fail + 1))
fi

# bootstrap prints step lines
mkdir -p "$TMP/steps"
setup_repo "$TMP/steps"
out="$(bash .cursor/skills/verasic-github-env/scripts/bootstrap.sh 2>&1 || true)"
if [[ "$out" == *"bootstrap: step:"* ]]; then
  echo "PASS: bootstrap prints step lines"
  pass=$((pass + 1))
else
  echo "FAIL: bootstrap step lines missing"
  fail=$((fail + 1))
fi

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
