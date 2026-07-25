#!/usr/bin/env bash
set -euo pipefail

NO_CHMOD=false
while (($#)); do
  case "$1" in
    --no-chmod) NO_CHMOD=true; shift ;;
    --help|-h)
      cat <<'EOF'
bootstrap — wire GitHub agent harness files into this repository

Usage:
  bootstrap.sh           scaffold env files, gitignore, optional verify
  bootstrap.sh --no-chmod  skip auto chmod on credential files
EOF
      exit 0
      ;;
    *) echo "bootstrap: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "bootstrap: must run inside a git repository" >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CHECK_GH="$SCRIPT_DIR/check-gh.sh"
LOAD_GH="$SCRIPT_DIR/load-gh-env.sh"

SKILL_DISPLAY="$SKILL_ROOT"
if [[ "$SKILL_ROOT" == "$ROOT/"* ]]; then
  SKILL_DISPLAY="${SKILL_ROOT#"$ROOT"/}"
fi

step_ran()    { echo "bootstrap: step: ran $*"; }
step_skipped(){ echo "bootstrap: step: skipped $*"; }
step_cannot() { echo "bootstrap: step: cannot $*"; }

# shellcheck disable=SC1091
source "$SCRIPT_DIR/parse-gh-repo.sh"

origin_ok=true
if ! origin_url="$(git remote get-url origin 2>/dev/null)"; then
  echo "bootstrap: warning — no git origin; set GH_REPO manually in .github-agent.local" >&2
  origin_ok=false
  GH_REPO="owner/repo"
else
  if ! GH_REPO="$(verasic_parse_gh_repo_from_remote "$origin_url")"; then
    echo "bootstrap: warning — could not parse github.com owner/repo from origin — set GH_REPO manually" >&2
    origin_ok=false
    GH_REPO="owner/repo"
  fi
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "bootstrap: warning — gh CLI not on PATH — install from https://cli.github.com" >&2
fi

file_has_line() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] && grep -qE "$pattern" "$file"
}

secure_credential_file() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local mode
  mode="$(stat -c '%a' "$f" 2>/dev/null || stat -f '%Lp' "$f" 2>/dev/null || true)"
  [[ -z "$mode" || "$mode" == 600 || "$mode" == 400 ]] && return 0
  if $NO_CHMOD; then
    step_skipped "chmod 600 $f (--no-chmod)"
  else
    chmod 600 "$f"
    step_ran "chmod 600 $f"
  fi
}

ensure_envrc() {
  local marker='dotenv_if_exists .github-agent.local'
  if [[ ! -f .envrc ]]; then
    cp "$SKILL_ROOT/templates/.envrc" .envrc
    step_ran "write .envrc"
    return
  fi
  if grep -qF "$marker" .envrc; then
    step_skipped ".envrc loader (already present)"
  else
    printf '\n%s\n' "$marker" >> .envrc
    step_ran "append .envrc loader"
  fi
}

ENV_SNIPPET="# GitHub CLI — local agent harness (fine-grained PAT scoped to this repo)
# Prefer .github-agent.local for GH_* only — keeps app secrets separate from the PAT
# Create at: https://github.com/settings/tokens?type=beta
GH_TOKEN=
GH_REPO=${GH_REPO}"

ensure_env_example() {
  if [[ ! -f .env.example ]]; then
    printf '%s\n' "$ENV_SNIPPET" > .env.example
    step_ran "create .env.example with GH block"
    return
  fi

  local has_token has_repo
  has_token=false
  has_repo=false
  file_has_line .env.example '^GH_TOKEN=' && has_token=true
  file_has_line .env.example '^GH_REPO=' && has_repo=true

  if $has_token && $has_repo; then
    step_skipped ".env.example GH block (complete)"
    return
  fi

  if $has_token || $has_repo; then
    $has_token || printf 'GH_TOKEN=\n' >> .env.example
    $has_repo  || printf 'GH_REPO=%s\n' "$GH_REPO" >> .env.example
    step_ran "complete .env.example GH block"
    return
  fi

  printf '\n%s\n' "$ENV_SNIPPET" >> .env.example
  step_ran "append .env.example GH block"
}

repo_gitignored() {
  git check-ignore -q -- "$1" 2>/dev/null || return 1
  local src
  src="$(git check-ignore --verbose -- "$1" 2>/dev/null | head -n1 | cut -d: -f1)"
  [[ -n "$src" && "$src" != /* && "$src" == *.gitignore ]]
}

ensure_gitignore() {
  if [[ ! -f .gitignore ]]; then
    cat > .gitignore <<'EOF'
# agent harness secrets
.github-agent.local
.env.local
!.env.example
!.envrc
EOF
    step_ran "create .gitignore"
    return
  fi

  local changed=false
  if ! repo_gitignored .github-agent.local; then
    printf '\n# agent harness secrets\n.github-agent.local\n' >> .gitignore
    changed=true
  fi
  if ! repo_gitignored .env.local; then
    printf '.env.local\n' >> .gitignore
    changed=true
  fi
  if git check-ignore -q .env.example 2>/dev/null; then
    if ! file_has_line .gitignore '^!\.env\.example$'; then
      printf '!.env.example\n' >> .gitignore
      changed=true
    fi
  fi
  if git check-ignore -q .envrc 2>/dev/null; then
    if ! file_has_line .gitignore '^!\.envrc$'; then
      printf '!.envrc\n' >> .gitignore
      changed=true
    fi
  fi

  if $changed; then
    step_ran "update .gitignore for agent secrets"
  else
    step_skipped ".gitignore (already covers secrets)"
  fi
}

ensure_github_agent_example() {
  local dest=".github-agent.local.example"
  if [[ -f "$dest" ]]; then
    step_skipped "$dest (exists)"
    return
  fi
  sed "s|owner/repo|${GH_REPO}|" "$SKILL_ROOT/templates/github-agent.local.example" > "$dest"
  step_ran "write $dest"
}

ensure_github_agent_local() {
  if [[ -f .github-agent.local ]]; then
    step_skipped ".github-agent.local (exists)"
    return
  fi
  if [[ -f .github-agent.local.example ]]; then
    cp .github-agent.local.example .github-agent.local
  else
    sed "s|owner/repo|${GH_REPO}|" "$SKILL_ROOT/templates/github-agent.local.example" > .github-agent.local
  fi
  chmod 600 .github-agent.local 2>/dev/null || true
  step_ran "scaffold .github-agent.local (empty GH_TOKEN)"
}

check_tracked_secrets() {
  local tracked=()
  while IFS= read -r path; do
    tracked+=("$path")
  done < <(git ls-files .env.local .github-agent.local 2>/dev/null || true)
  if ((${#tracked[@]} > 0)); then
    echo "bootstrap: ACTION NEEDED — secret file(s) tracked by git: ${tracked[*]}" >&2
    echo "bootstrap: 1. git rm --cached ${tracked[*]}" >&2
    echo "bootstrap: 2. commit the removal; if any commit with the file was pushed, ROTATE the token now" >&2
    return 1
  fi
  return 0
}

warn_committable_templates() {
  local blocked=()
  if git check-ignore -q .env.example 2>/dev/null; then
    blocked+=(".env.example")
  fi
  if git check-ignore -q .envrc 2>/dev/null; then
    blocked+=(".envrc")
  fi
  if ((${#blocked[@]} > 0)); then
    echo "bootstrap: WARNING — still gitignored (add negation rules): ${blocked[*]}" >&2
  fi
}

report_credential_source() {
  local agent_has=false env_has=false src="(none)"
  if [[ -f .github-agent.local ]] && grep -qE '^[[:space:]]*(export[[:space:]]+)?GH_TOKEN=.+$' .github-agent.local 2>/dev/null; then
    agent_has=true
    src=".github-agent.local"
  fi
  if [[ -f .env.local ]] && grep -qE '^[[:space:]]*(export[[:space:]]+)?GH_TOKEN=.+$' .env.local 2>/dev/null; then
    env_has=true
    if ! $agent_has; then
      src=".env.local"
      echo "bootstrap: migration nudge — GH_* found only in .env.local; prefer .github-agent.local for the PAT" >&2
    fi
  fi
  if [[ -f .github-agent.local ]] && grep -qE '^[[:space:]]*(export[[:space:]]+)?GH_REPO=' .github-agent.local 2>/dev/null; then
    [[ "$src" == "(none)" ]] && src=".github-agent.local"
  elif [[ -f .env.local ]] && grep -qE '^[[:space:]]*(export[[:space:]]+)?GH_REPO=' .env.local 2>/dev/null; then
    [[ "$src" == "(none)" ]] && src=".env.local"
  fi
  echo "bootstrap: credential source: $src"
}

run_verify() {
  if [[ ! -f "$CHECK_GH" ]]; then
    echo "bootstrap: verify: skipped (check-gh missing)"
    step_cannot "verify (check-gh.sh missing)"
    return 0
  fi
  # shellcheck disable=SC1091
  source "$LOAD_GH"
  if [[ -z "${GH_TOKEN:-}" ]]; then
    echo "bootstrap: verify: skipped (no token)"
    step_skipped "verify (GH_TOKEN unset)"
    return 0
  fi
  step_ran "verify (check-gh.sh)"
  if bash "$CHECK_GH" >&2; then
    echo "bootstrap: verify: ok"
    return 0
  fi
  echo "bootstrap: verify: failed"
  return 1
}

ensure_envrc
ensure_env_example
ensure_gitignore
ensure_github_agent_example
ensure_github_agent_local
secure_credential_file .github-agent.local
secure_credential_file .env.local

secrets_clean=true
check_tracked_secrets || secrets_clean=false
warn_committable_templates
report_credential_source

PAT_URL="https://github.com/settings/tokens?type=beta"
VERIFY_STEP="  3. bash ${SKILL_DISPLAY}/scripts/check-gh.sh"
if command -v direnv >/dev/null 2>&1; then
  DIRENV_STEP="  3. direnv allow  # loads .github-agent.local via .envrc"
  VERIFY_STEP="  4. bash ${SKILL_DISPLAY}/scripts/check-gh.sh"
else
  step_skipped "direnv hint (direnv not on PATH)"
  DIRENV_STEP=""
fi

cat <<EOF

Next steps:
  1. Create fine-grained PAT scoped to: ${GH_REPO}
     ${PAT_URL}
  2. Set GH_TOKEN in .github-agent.local (chmod 600) — template already scaffolded if missing
${DIRENV_STEP:+$DIRENV_STEP$'\n'}${VERIFY_STEP}

Full spec: ${SKILL_DISPLAY}/references/setup-protocol.md
EOF

verify_rc=0
run_verify || verify_rc=$?

if ! $secrets_clean; then
  exit 3
fi
if ((verify_rc != 0)); then
  exit 3
fi
exit 0
