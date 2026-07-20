#!/usr/bin/env bash
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "bootstrap: must run inside a git repository" >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# display path for messages — relative when installed inside the repo
SKILL_DISPLAY="$SKILL_ROOT"
if [[ "$SKILL_ROOT" == "$ROOT/"* ]]; then
  SKILL_DISPLAY="${SKILL_ROOT#"$ROOT"/}"
fi

# shellcheck disable=SC1091
source "$SCRIPT_DIR/parse-gh-repo.sh"

if ! origin_url="$(git remote get-url origin 2>/dev/null)"; then
  echo "bootstrap: no git origin — set GH_REPO manually in .github-agent.local" >&2
  GH_REPO="owner/repo"
else
  if ! GH_REPO="$(verasic_parse_gh_repo_from_remote "$origin_url")"; then
    echo "bootstrap: could not parse github.com owner/repo from origin — set GH_REPO manually" >&2
    GH_REPO="owner/repo"
  fi
fi

file_has_line() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] && grep -qE "$pattern" "$file"
}

ensure_envrc() {
  local marker='dotenv_if_exists .github-agent.local'
  if [[ ! -f .envrc ]]; then
    cp "$SKILL_ROOT/templates/.envrc" .envrc
    echo "bootstrap: wrote .envrc"
    return
  fi
  if grep -qF "$marker" .envrc; then
    echo "bootstrap: .envrc already loads .github-agent.local — skipped"
  else
    printf '\n%s\n' "$marker" >> .envrc
    echo "bootstrap: appended .github-agent.local loader to .envrc"
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
    echo "bootstrap: created .env.example with GitHub block"
    return
  fi

  local has_token has_repo
  has_token=false
  has_repo=false
  file_has_line .env.example '^GH_TOKEN=' && has_token=true
  file_has_line .env.example '^GH_REPO=' && has_repo=true

  if $has_token && $has_repo; then
    echo "bootstrap: .env.example already documents GH_TOKEN and GH_REPO — skipped"
    return
  fi

  if $has_token || $has_repo; then
    # append only the missing line — re-appending the whole block would duplicate the other var
    $has_token || printf 'GH_TOKEN=\n' >> .env.example
    $has_repo  || printf 'GH_REPO=%s\n' "$GH_REPO" >> .env.example
    echo "bootstrap: completed GH block in .env.example"
    return
  fi

  printf '\n%s\n' "$ENV_SNIPPET" >> .env.example
  echo "bootstrap: appended GitHub block to .env.example"
}

# true only when the file is actually ignored AND the deciding rule lives in a
# repo-committed .gitignore — a machine-local global excludesfile or
# .git/info/exclude does not protect other clones, and a negation rule
# (`!.env.local`) makes check-ignore --verbose match while the file stays
# committable, so the quiet ignored-status check must come first
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
    echo "bootstrap: created .gitignore with agent secret patterns"
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
    echo "bootstrap: updated .gitignore for agent secrets and committable templates"
  else
    echo "bootstrap: .gitignore already covers agent secrets — skipped"
  fi
}

ensure_github_agent_example() {
  local dest=".github-agent.local.example"
  if [[ -f "$dest" ]]; then
    echo "bootstrap: $dest already exists — skipped"
    return
  fi
  sed "s|owner/repo|${GH_REPO}|" "$SKILL_ROOT/templates/github-agent.local.example" > "$dest"
  echo "bootstrap: wrote $dest"
}

# returns 1 when secrets are tracked so bootstrap can exit 3 (action needed)
# instead of reporting a clean wire — a committed token is a rotation event
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

ensure_envrc
ensure_env_example
ensure_gitignore
ensure_github_agent_example
secrets_clean=true
check_tracked_secrets || secrets_clean=false
warn_committable_templates

cat <<EOF

Next steps:
  1. Create fine-grained PAT scoped to: ${GH_REPO}
  2. cp .github-agent.local.example .github-agent.local  # set GH_TOKEN (chmod 600)
  3. direnv allow  # optional, if using direnv
  4. bash ${SKILL_DISPLAY}/scripts/check-gh.sh

Full spec: ${SKILL_DISPLAY}/references/setup-protocol.md
EOF

# exit 3 = manual step required (verasic-init reports it as "action needed")
$secrets_clean || exit 3
