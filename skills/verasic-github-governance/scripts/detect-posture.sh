#!/usr/bin/env bash
set -euo pipefail

# detect-posture — read-only governance tier detection (informational only).
# Exit 0 always. First stdout line: posture: <tier>
# Tiers: soft-incomplete | soft-ready | hard-eligible | hard-applied | unknown
#
# Tests: VERASIC_GOVERNANCE_POSTURE_FIXTURE=hard-eligible|soft-ready|...

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "posture: unknown"
  echo "posture_reason: not inside a git repository"
  exit 0
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

POSTURE="unknown"
POSTURE_REASON=""
POSTURE_RECOMMENDATION=""
VISIBILITY="unknown"
BRANCH_PROTECTION="unknown"
CI_ON_DEFAULT="unknown"
DEFAULT_BRANCH="main"

emit() {
  echo "posture: $POSTURE"
  [[ -n "$VISIBILITY" && "$VISIBILITY" != unknown ]] && echo "visibility: $VISIBILITY"
  [[ -n "$DEFAULT_BRANCH" ]] && echo "default_branch: $DEFAULT_BRANCH"
  echo "branch_protection: $BRANCH_PROTECTION"
  echo "ci_on_default: $CI_ON_DEFAULT"
  [[ -n "$POSTURE_REASON" ]] && echo "posture_reason: $POSTURE_REASON"
  [[ -n "$POSTURE_RECOMMENDATION" ]] && echo "posture_recommendation: $POSTURE_RECOMMENDATION"
  echo "note: recommendation only — init and factory never auto-apply hard protection"
  exit 0
}

fixture="${VERASIC_GOVERNANCE_POSTURE_FIXTURE:-}"
if [[ -n "$fixture" ]]; then
  case "$fixture" in
    soft-incomplete)
      POSTURE="soft-incomplete"
      POSTURE_REASON="fixture — complete soft governance first (CONTRIBUTING, ci job, hooks)"
      emit
      ;;
    soft-ready)
      POSTURE="soft-ready"
      VISIBILITY="PRIVATE"
      BRANCH_PROTECTION="none"
      CI_ON_DEFAULT="unknown"
      POSTURE_REASON="fixture — soft floor complete; hard not recommended (private Free or plan unknown)"
      emit
      ;;
    hard-eligible)
      POSTURE="hard-eligible"
      VISIBILITY="PUBLIC"
      BRANCH_PROTECTION="none"
      CI_ON_DEFAULT="success"
      POSTURE_REASON="fixture — public repo; soft ready; ci green on default; branch not protected"
      POSTURE_RECOMMENDATION="apply hard protection via OpenTofu (user confirm required) — Milkywayrules/verasic-github-governance-public-free → enable_hard_protection=true"
      emit
      ;;
    hard-applied)
      POSTURE="hard-applied"
      VISIBILITY="PUBLIC"
      BRANCH_PROTECTION="applied"
      CI_ON_DEFAULT="success"
      POSTURE_REASON="fixture — branch protection active with required check ci"
      emit
      ;;
    unknown)
      POSTURE="unknown"
      POSTURE_REASON="fixture — plan detection unavailable"
      emit
      ;;
    *)
      echo "detect-posture: invalid VERASIC_GOVERNANCE_POSTURE_FIXTURE: $fixture" >&2
      POSTURE="unknown"
      POSTURE_REASON="invalid fixture"
      emit
      ;;
  esac
fi

soft_missing=()

check_file() {
  local path="$1" label="$2"
  if [[ ! -f "$path" ]]; then
    soft_missing+=("$label")
  fi
}

check_file "CONTRIBUTING.md" "CONTRIBUTING.md"
check_file ".github/workflows/ci.yml" "CI workflow"
check_file ".github/verasic-governance/hooks/pre-push" "repo-local pre-push hook"
check_file ".github/verasic-governance/hooks/pre-commit" "repo-local pre-commit hook"

if [[ -f ".github/workflows/ci.yml" ]]; then
  grep -qE '^[[:space:]]{2}ci:[[:space:]]*$' .github/workflows/ci.yml || soft_missing+=("ci job name")
fi

hooks_ok=0
lefthook_file=""
for f in lefthook.yml .lefthook.yml; do
  [[ -f "$f" ]] && lefthook_file="$f" && break
done
if [[ -n "$lefthook_file" ]]; then
  if grep -q '\.github/verasic-governance/hooks/pre-push' "$lefthook_file" \
     && grep -q '\.github/verasic-governance/hooks/pre-commit' "$lefthook_file"; then
    hooks_ok=1
  else
    soft_missing+=("lefthook governance hooks")
  fi
else
  hp="$(git config core.hooksPath 2>/dev/null || true)"
  if [[ "$hp" == *verasic-governance/hooks* || "$hp" == *verasic-github-governance/hooks* ]]; then
    hooks_ok=1
  else
    soft_missing+=("hooks wired")
  fi
fi

if ((${#soft_missing[@]} > 0)); then
  POSTURE="soft-incomplete"
  POSTURE_REASON="missing soft governance: ${soft_missing[*]}"
  emit
fi

if ! command -v gh >/dev/null 2>&1; then
  POSTURE="unknown"
  POSTURE_REASON="soft ready — gh not available; cannot detect plan eligibility or branch protection"
  emit
fi

remote="$(git remote get-url origin 2>/dev/null || true)"
repo=""
if [[ -n "$remote" ]]; then
  parse_script="$(dirname "$SKILL_ROOT")/verasic-github-cli-init/scripts/parse-gh-repo.sh"
  if [[ -f "$parse_script" ]]; then
    # shellcheck source=/dev/null
    source "$parse_script"
    repo="$(verasic_parse_gh_repo_from_remote "$remote" 2>/dev/null || true)"
  fi
  if [[ -z "$repo" ]]; then
    repo="$(echo "$remote" | sed -nE 's#.*github\.com[:/]([^/]+/[^/.]+).*#\1#p')"
  fi
fi

if [[ -z "$repo" ]]; then
  POSTURE="unknown"
  POSTURE_REASON="soft ready — no GitHub origin; cannot detect visibility or branch protection"
  emit
fi

repo_json="$(gh repo view "$repo" --json visibility,isPrivate,defaultBranchRef 2>/dev/null || true)"
if [[ -z "$repo_json" ]]; then
  POSTURE="unknown"
  POSTURE_REASON="soft ready — gh repo view failed (auth or network); cannot detect eligibility"
  emit
fi

VISIBILITY="$(gh repo view "$repo" --json visibility -q .visibility 2>/dev/null || true)"
DEFAULT_BRANCH="$(gh repo view "$repo" --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
[[ -z "$DEFAULT_BRANCH" ]] && DEFAULT_BRANCH="main"

protection_json=""
protection_rc=0
protection_json="$(gh api "repos/$repo/branches/$DEFAULT_BRANCH/protection" 2>/dev/null)" || protection_rc=$?

if [[ "$protection_rc" -eq 0 && -n "$protection_json" ]]; then
  BRANCH_PROTECTION="applied"
  has_ci=0
  has_pr=0
  if grep -q '"contexts"' <<<"$protection_json" && grep -q '"ci"' <<<"$protection_json"; then
    has_ci=1
  fi
  if grep -q 'required_pull_request_reviews' <<<"$protection_json"; then
    has_pr=1
  fi
  if [[ "$has_ci" -eq 1 && "$has_pr" -eq 1 ]]; then
    POSTURE="hard-applied"
    POSTURE_REASON="branch protection active with PR reviews and required check ci"
    emit
  fi
  BRANCH_PROTECTION="partial"
  POSTURE="hard-eligible"
  POSTURE_REASON="branch protection present but missing Verasic floor (PR review + required check ci)"
  POSTURE_RECOMMENDATION="align branch protection via OpenTofu (user confirm required) — Milkywayrules/verasic-github-governance-public-free → enable_hard_protection=true"
  emit
fi

BRANCH_PROTECTION="none"

ci_json="$(gh api "repos/$repo/commits/$DEFAULT_BRANCH/check-runs" 2>/dev/null || true)"
if [[ -n "$ci_json" ]]; then
  ci_conclusion="$(printf '%s' "$ci_json" | grep -o '"name"[[:space:]]*:[[:space:]]*"ci"[^}]*"conclusion"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -n 's/.*"conclusion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  if [[ -n "$ci_conclusion" ]]; then
    CI_ON_DEFAULT="$ci_conclusion"
  else
    CI_ON_DEFAULT="missing"
  fi
else
  CI_ON_DEFAULT="unknown"
fi

if [[ "$VISIBILITY" == "PRIVATE" ]]; then
  POSTURE="soft-ready"
  POSTURE_REASON="private repo — GitHub branch protection requires Team/Pro or public visibility (see plan-matrix.md)"
  emit
fi

if [[ "$VISIBILITY" == "PUBLIC" ]]; then
  if [[ "$CI_ON_DEFAULT" == "success" ]]; then
    POSTURE="hard-eligible"
    POSTURE_REASON="public repo; soft ready; ci green on $DEFAULT_BRANCH; branch protection not applied"
    POSTURE_RECOMMENDATION="apply hard protection via OpenTofu (user confirm required) — Milkywayrules/verasic-github-governance-public-free → enable_hard_protection=true"
    emit
  fi
  if [[ "$CI_ON_DEFAULT" == "missing" || "$CI_ON_DEFAULT" == "unknown" ]]; then
    POSTURE="soft-ready"
    POSTURE_REASON="public repo eligible for hard protection — merge a PR with green ci on $DEFAULT_BRANCH first"
    emit
  fi
  POSTURE="soft-ready"
  POSTURE_REASON="public repo — ci not green on $DEFAULT_BRANCH (latest: $CI_ON_DEFAULT); complete first green ci before hard apply"
  emit
fi

POSTURE="unknown"
POSTURE_REASON="soft ready — visibility '$VISIBILITY' not classified"
emit
