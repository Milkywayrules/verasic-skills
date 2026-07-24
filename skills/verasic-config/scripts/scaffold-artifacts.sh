#!/usr/bin/env bash
set -euo pipefail

# Wire verasic artifact dirs and optional config scaffold into this repository.
# Exit codes: 0 = wired (or already wired), 3 = manual step required, 1 = error.

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "scaffold: must run inside a git repository" >&2
  exit 1
fi

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

step_ran()     { echo "scaffold: step: ran $*"; }
step_skipped() { echo "scaffold: step: skipped $*"; }
step_cannot()  { echo "scaffold: step: cannot $*"; }

file_has_line() {
  local file="$1" pattern="$2"
  [[ -f "$file" ]] && grep -qE "$pattern" "$file"
}

repo_gitignored() {
  git check-ignore -q -- "$1" 2>/dev/null || return 1
  local src
  src="$(git check-ignore --verbose -- "$1" 2>/dev/null | head -n1 | cut -d: -f1)"
  [[ -n "$src" && "$src" != /* && "$src" == *.gitignore ]]
}

CONFIG_JSON="$(VERASIC_REPO_ROOT="$ROOT" bash "$SCRIPT_DIR/resolve-config.sh")"

read_config_field() {
  local jq_path="$1" default="$2"
  echo "$CONFIG_JSON" | python3 -c "
import json, sys
path = sys.argv[1].split('.')
default = sys.argv[2]
data = json.load(sys.stdin)
cur = data
for key in path:
    if not isinstance(cur, dict) or key not in cur:
        print(default)
        sys.exit(0)
    cur = cur[key]
if isinstance(cur, bool):
    print('true' if cur else 'false')
else:
    print(cur)
" "$jq_path" "$default"
}

LOCAL_DIR="$(read_config_field artifacts.localDir .verasic)"
TRACKED_DIR="$(read_config_field artifacts.trackedDir verasic)"
INDEX_LOCAL="$(read_config_field artifacts.indexLocal false)"

ensure_gitignore_local() {
  local pattern="${LOCAL_DIR%/}/"
  if [[ ! -f .gitignore ]]; then
    cat > .gitignore <<EOF
# verasic local artifacts (gitignored)
${pattern}
EOF
    step_ran "create .gitignore with ${pattern}"
    return
  fi
  if repo_gitignored "$LOCAL_DIR" || repo_gitignored "${LOCAL_DIR}/"; then
    step_skipped ".gitignore (${pattern} already ignored)"
    return
  fi
  if file_has_line .gitignore "^${pattern//\//\\/}\$" || file_has_line .gitignore "^${LOCAL_DIR//\//\\/}\$"; then
    step_skipped ".gitignore (${pattern} line present)"
    return
  fi
  printf '\n# verasic local artifacts (gitignored)\n%s\n' "$pattern" >> .gitignore
  step_ran "append .gitignore ${pattern}"
}

ensure_cursorignore_local() {
  local pattern="${LOCAL_DIR%/}/"
  local should_ignore=false

  if [[ "${VERASIC_INDEX_LOCAL:-}" == "false" || "$INDEX_LOCAL" == "false" ]]; then
    should_ignore=true
  fi

  if ! $should_ignore; then
    step_skipped ".cursorignore (${pattern}; indexLocal not false and VERASIC_INDEX_LOCAL not false)"
    return
  fi

  if [[ ! -f .cursorignore ]]; then
    cat > .cursorignore <<EOF
# verasic local artifacts — exclude from codebase index
${pattern}
EOF
    step_ran "create .cursorignore with ${pattern}"
    return
  fi

  if file_has_line .cursorignore "^${pattern//\//\\/}\$" || file_has_line .cursorignore "^${LOCAL_DIR//\//\\/}\$"; then
    step_skipped ".cursorignore (${pattern} line present)"
    return
  fi

  printf '\n# verasic local artifacts — exclude from codebase index\n%s\n' "$pattern" >> .cursorignore
  step_ran "append .cursorignore ${pattern}"
}

ensure_dir_gitkeep() {
  local dir="$1"
  local label="$2"
  mkdir -p "$dir"
  if [[ -f "$dir/.gitkeep" ]]; then
    step_skipped "$label (exists)"
  else
    : > "$dir/.gitkeep"
    step_ran "create $dir/.gitkeep"
  fi
}

ensure_config_scaffold() {
  if [[ -f verasic.config.ts || -f .verasicrc.json || -f .verasicrc.jsonc ]]; then
    step_skipped "verasic.config.ts (user config exists)"
    return
  fi
  cp "$SKILL_ROOT/templates/verasic.config.ts.example" verasic.config.ts
  step_ran "copy verasic.config.ts.example → verasic.config.ts"
}

ensure_gitignore_local
ensure_cursorignore_local
ensure_dir_gitkeep "$TRACKED_DIR" "tracked artifact root"
ensure_dir_gitkeep "$TRACKED_DIR/security-reviews" "tracked security-reviews"
ensure_dir_gitkeep "$LOCAL_DIR" "local artifact root"
ensure_dir_gitkeep "$LOCAL_DIR/security-reviews" "local security-reviews"
ensure_config_scaffold

SKILL_DISPLAY="$SKILL_ROOT"
if [[ "$SKILL_ROOT" == "$ROOT/"* ]]; then
  SKILL_DISPLAY="${SKILL_ROOT#"$ROOT"/}"
fi

cat <<EOF

Verasic config hub:
  trackedDir: ${TRACKED_DIR}/
  localDir:   ${LOCAL_DIR}/ (gitignored)
  indexLocal: ${INDEX_LOCAL}

Edit verasic.config.ts or .verasicrc.json at repo root.
Schema: ${SKILL_DISPLAY}/references/config-schema.md
Resolve (shell): bash ${SKILL_DISPLAY}/scripts/resolve-config.sh
EOF

exit 0
