#!/usr/bin/env bash
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_HOOKS=".github/verasic-governance/hooks"
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

setup_repo() {
  local dir="$1"
  mkdir -p "$dir/.cursor/skills"
  cp -r "$SKILL_ROOT" "$dir/.cursor/skills/verasic-github-governance"
  cp -r "$(dirname "$SKILL_ROOT")/verasic-git-commits" "$dir/.cursor/skills/verasic-git-commits" 2>/dev/null || true
  cd "$dir"
  git init -q -b main
  git remote add origin git@github.com:Milkywayrules/governance-test.git
}

BOOT=".cursor/skills/verasic-github-governance/scripts/bootstrap-repo.sh"

mkdir -p "$TMP/repo"
setup_repo "$TMP/repo"

chmod +x .cursor/skills/verasic-github-governance/scripts/*.sh
chmod +x .cursor/skills/verasic-github-governance/hooks/*

assert "doctor fails before bootstrap" \
  "bash .cursor/skills/verasic-github-governance/scripts/doctor.sh >/dev/null 2>&1; rc=\$?; [[ \$rc -eq 2 ]]"

assert "bootstrap creates CONTRIBUTING" \
  "bash $BOOT >/dev/null && test -f CONTRIBUTING.md"

assert "bootstrap creates ci workflow" \
  "test -f .github/workflows/ci.yml"

assert "ci workflow has marker and jobs.ci" \
  "grep -q 'verasic-governance-ci: managed' .github/workflows/ci.yml && grep -qE '^[[:space:]]{2}ci:[[:space:]]*$' .github/workflows/ci.yml"

assert "bootstrap merges AGENTS.md block" \
  "test -f AGENTS.md && grep -q 'verasic-governance:start' AGENTS.md"

assert "bootstrap copies repo-local hooks" \
  "test -x $REPO_HOOKS/pre-push && test -x $REPO_HOOKS/pre-commit"

assert "bootstrap idempotent" \
  "bash $BOOT >/dev/null 2>&1; test \$(grep -c '^# Contributing' CONTRIBUTING.md) -eq 1"

assert "lefthook uses repo-local paths" \
  "grep -q '$REPO_HOOKS/pre-push' lefthook.yml && grep -q '$REPO_HOOKS/pre-commit' lefthook.yml"

assert "doctor passes with lefthook.yml" \
  "test -f lefthook.yml && bash .cursor/skills/verasic-github-governance/scripts/doctor.sh; rc=\$?; [[ \$rc -eq 0 ]]"

assert "wire-hooks wires commit-msg when skill present" \
  "bash .cursor/skills/verasic-github-governance/scripts/wire-hooks.sh >/dev/null && grep -q '.cursor/skills/verasic-git-commits/hooks/commit-msg' lefthook.yml"

# CI conflict exit 2
mkdir -p "$TMP/conflict"
setup_repo "$TMP/conflict"
mkdir -p .github/workflows
printf 'name: foreign\non: push\njobs:\n  x:\n    runs-on: ubuntu-latest\n    steps:\n      - run: true\n' > .github/workflows/foreign.yml
assert "foreign CI exits 2 without strategy" \
  "bash $BOOT >/dev/null 2>&1; rc=\$?; [[ \$rc -eq 2 ]]"

assert "ci-strategy skip leaves foreign workflow" \
  "bash $BOOT --ci-strategy=skip >/dev/null && grep -q 'name: foreign' .github/workflows/foreign.yml && ! test -f .github/workflows/ci.yml"

mkdir -p "$TMP/replace"
setup_repo "$TMP/replace"
mkdir -p .github/workflows
printf 'name: foreign\non: push\njobs:\n  x:\n    runs-on: ubuntu-latest\n    steps:\n      - run: true\n' > .github/workflows/foreign.yml
assert "ci-strategy replace writes ci.yml" \
  "bash $BOOT --ci-strategy=replace >/dev/null && test -f .github/workflows/ci.yml && grep -q 'verasic-governance-ci: managed' .github/workflows/ci.yml"

# Turborepo detection
mkdir -p "$TMP/turbo"
setup_repo "$TMP/turbo"
printf '{}\n' > turbo.json
assert "turbo.json selects turborepo CI template" \
  "bash $BOOT >/dev/null && grep -q 'bunx turbo run lint' .github/workflows/ci.yml && grep -qE '^[[:space:]]{2}ci:[[:space:]]*$' .github/workflows/ci.yml"

# pre-push blocks main
git config user.email t@t
git config user.name t
echo ok > README.md
git add README.md
git commit -qm 'chore: seed'
assert_fail "pre-push blocks main" \
  "printf '%s\n' 'refs/heads/main abc refs/heads/main def' | bash $REPO_HOOKS/pre-push origin git@github.com:x/y.git"

assert "pre-push bypass allows main" \
  "VERASIC_GOVERNANCE_BYPASS=1 bash $REPO_HOOKS/pre-push origin git@github.com:x/y.git </dev/null"

git checkout -q -b feat/ok
echo x >> README.md
git add README.md
git commit -qm 'feat: change'
assert "pre-push allows feature branch" \
  "printf '%s\n' 'refs/heads/feat/ok abc refs/heads/feat/ok def' | bash $REPO_HOOKS/pre-push origin git@github.com:x/y.git"

assert "pre-commit exits 0 on feature branch" \
  "bash $REPO_HOOKS/pre-commit"

git checkout -q main
assert "pre-commit warns on main" \
  "bash $REPO_HOOKS/pre-commit 2>&1 | grep -q 'prefer feature branches'"

assert "templates integrity" \
  "test -f .cursor/skills/verasic-github-governance/templates/.github/workflows/ci-turborepo.yml"

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
