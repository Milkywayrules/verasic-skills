#!/usr/bin/env bash
set -euo pipefail

# Check soft-governance readiness for the current repo.
# Exit 0 = ready, 2 = missing items, 1 = error

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "doctor: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

missing=()
warn=()

check_file() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    echo "doctor: ok — $label"
  else
    echo "doctor: MISSING — $label ($path)"
    missing+=("$label")
  fi
}

check_file "CONTRIBUTING.md" "CONTRIBUTING.md"
check_file ".github/workflows/ci.yml" "CI workflow"
check_file ".github/verasic-governance/hooks/pre-push" "repo-local pre-push hook"
check_file ".github/verasic-governance/hooks/pre-commit" "repo-local pre-commit hook"

if [[ -f ".github/workflows/ci.yml" ]]; then
  if grep -qE '^[[:space:]]{2}ci:[[:space:]]*$' .github/workflows/ci.yml; then
    echo "doctor: ok — CI job named 'ci'"
  else
    echo "doctor: MISSING — CI job must be named 'ci' (jobs.ci)"
    missing+=("ci job name")
  fi
fi

# Hooks wired?
hooks_ok=0
lefthook_file=""
for f in lefthook.yml .lefthook.yml; do
  [[ -f "$f" ]] && lefthook_file="$f" && break
done
if [[ -n "$lefthook_file" ]]; then
  if grep -q '\.github/verasic-governance/hooks/pre-push' "$lefthook_file" \
     && grep -q '\.github/verasic-governance/hooks/pre-commit' "$lefthook_file"; then
    echo "doctor: ok — lefthook references repo-local governance hooks ($lefthook_file)"
    hooks_ok=1
  elif grep -q 'verasic-github-governance/hooks/' "$lefthook_file"; then
    echo "doctor: MISSING — lefthook still references skill-local governance hooks (re-run bootstrap-repo.sh --force)"
    missing+=("lefthook repo-local hooks")
  else
    echo "doctor: MISSING — lefthook missing repo-local governance hook commands"
    missing+=("lefthook governance hooks")
  fi
  if command -v lefthook >/dev/null 2>&1; then
    if [[ -f ".git/hooks/pre-push" || -f ".git/hooks/pre-commit" ]]; then
      echo "doctor: ok — lefthook install appears present"
    else
      echo "doctor: WARN — run 'lefthook install'"
      warn+=("lefthook install")
    fi
  fi
else
  hp="$(git config core.hooksPath 2>/dev/null || true)"
  if [[ "$hp" == *verasic-governance/hooks* || "$hp" == *verasic-github-governance/hooks* ]]; then
    echo "doctor: ok — core.hooksPath governance ($hp)"
    hooks_ok=1
  else
    echo "doctor: MISSING — hooks not wired (lefthook or core.hooksPath)"
    missing+=("hooks wired")
  fi
fi

# Plan-gated / hard apply (informational)
echo "doctor: --- plan-gated (hard apply) ---"
if command -v gh >/dev/null 2>&1; then
  remote="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$remote" ]]; then
    repo=""
    parse_script="$(dirname "$SKILL_ROOT")/verasic-github-env/scripts/parse-gh-repo.sh"
    if [[ -f "$parse_script" ]]; then
      # shellcheck source=/dev/null
      source "$parse_script"
      repo="$(verasic_parse_gh_repo_from_remote "$remote" 2>/dev/null || true)"
    fi
    if [[ -z "$repo" ]]; then
      repo="$(echo "$remote" | sed -nE 's#.*github\.com[:/]([^/]+/[^/.]+).*#\1#p')"
    fi
    if [[ -n "$repo" ]]; then
      vis="$(gh repo view "$repo" --json visibility -q .visibility 2>/dev/null || true)"
      if [[ "$vis" == "PRIVATE" ]]; then
        echo "doctor: info — private repo: GitHub branch protection requires Team/Pro or public repo (see plan-matrix.md)"
        warn+=("hard protection plan-gated")
      fi
    fi
  fi
else
  echo "doctor: info — gh not available; skip plan detection"
fi

echo "doctor: info — hard apply requires OpenTofu enable_hard_protection=true when plan allows"
echo "doctor: info — required check 'ci' must pass on default branch after first merged PR"

if ((${#warn[@]} > 0)); then
  echo "doctor: warnings: ${warn[*]}"
fi

if ((${#missing[@]} > 0)); then
  echo "doctor: FAIL — missing: ${missing[*]}"
  exit 2
fi

echo "doctor: PASS — soft governance ready"
exit 0
