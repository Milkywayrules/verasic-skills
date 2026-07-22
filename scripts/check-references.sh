#!/usr/bin/env bash
set -euo pipefail

# Validate concrete internal path references in markdown (.md, .mdc).
# Skips placeholders, globs, external URLs, init-protocol cross-skill docs,
# install-layout directory tokens, and non-path backtick strings.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
INIT_PROTOCOL="$REPO_ROOT/skills/verasic-init/references/init-protocol.md"
SKILLS_DIR="$REPO_ROOT/skills"

pass=0
fail=0
skip=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }
skip_ref() { skip=$((skip + 1)); }

looks_like_path() {
  local ref="$1"
  [[ "$ref" == */* ]] && return 0
  [[ "$ref" =~ \.(md|mdc|sh|txt|yaml|yml|json|canvas|lock|sha256|example|envrc|gitignore)$ ]] && return 0
  [[ "$ref" == "setup.sh" || "$ref" == "manifest.txt" || "$ref" == "integrity.txt" ]] && return 0
  return 1
}

normalize_ref() {
  local ref="$1"
  ref="${ref#bash }"
  ref="${ref#source }"
  if [[ "$ref" == *' '* ]]; then
    local part
    for part in $ref; do
      looks_like_path "$part" && { echo "$part"; return 0; }
    done
  fi
  echo "$ref"
}

map_install_path() {
  local ref="$1"
  case "$ref" in
    .cursor/skills/*) echo "skills/${ref#.cursor/skills/}" ;;
    .agents/skills/*) echo "skills/${ref#.agents/skills/}" ;;
    .cursor/agents/*) echo "cursor/agents/${ref#.cursor/agents/}" ;;
    .cursor/commands/*) echo "cursor/commands/${ref#.cursor/commands/}" ;;
    .cursor/rules/*) echo "cursor/rules/${ref#.cursor/rules/}" ;;
    verasic-init/scripts/*) echo "skills/verasic-init/${ref#verasic-init/}" ;;
    verasic-*/scripts/*|verasic-*/references/*|verasic-*/templates/*|verasic-*/checklists/*)
      echo "skills/$ref"
      ;;
    *) echo "$ref" ;;
  esac
}

skill_root_for() {
  local source_file="$1"
  if [[ "$source_file" == "$SKILLS_DIR"/* ]]; then
    local rel="${source_file#"$SKILLS_DIR"/}"
    echo "$SKILLS_DIR/${rel%%/*}"
    return 0
  fi
  if [[ "$source_file" == "$REPO_ROOT/cursor/"* ]]; then
    local base
    base="$(basename "$source_file")"
    base="${base%.md}"
    base="${base%.mdc}"
    case "$base" in
      verasic-bugbot|verasic-review) echo "$SKILLS_DIR/verasic-bugbot" ;;
      verasic-fusion) echo "$SKILLS_DIR/verasic-fusion" ;;
      verasic-deep-research) echo "$SKILLS_DIR/verasic-deep-research" ;;
      verasic-init) echo "$SKILLS_DIR/verasic-init" ;;
      verasic-setup-github) echo "$SKILLS_DIR/verasic-github-env" ;;
      verasic-audit-commits|verasic-commit-auditor|verasic-git-commits) echo "$SKILLS_DIR/verasic-git-commits" ;;
      verasic-github-env) echo "$SKILLS_DIR/verasic-github-env" ;;
    esac
  fi
}

in_init_protocol_table() {
  local line_no="$1"
  awk -v ln="$line_no" '
    BEGIN { in_table=0 }
    /^## Per-skill wiring/ { in_table=1 }
    /^## / && !/^## Per-skill wiring/ { if (in_table) in_table=0 }
    in_table && NR==ln { found=1 }
    END { exit !found }
  ' "$INIT_PROTOCOL"
}

should_skip_ref() {
  local ref="$1"
  local source_file="$2"
  local line_no="$3"

  [[ "$ref" =~ ^https?:// ]] && return 0
  [[ "$ref" =~ ^mailto: ]] && return 0
  [[ "$ref" =~ ^# ]] && return 0
  [[ "$ref" == '...' || "$ref" == *'...'* ]] && return 0
  [[ "$ref" == *'<'* || "$ref" == *'>'* ]] && return 0
  [[ "$ref" == *'*'* ]] && return 0
  [[ "$ref" == *'…'* ]] && return 0
  [[ "$ref" =~ ^/verasic ]] && return 0
  [[ "$ref" == */ ]] && return 0
  [[ "$ref" =~ ^!\. ]] && return 0
  [[ "$ref" =~ ^v[0-9]+(\.[0-9]+)*(\.[0-9]+)?$ ]] && return 0

  case "$ref" in
    .cursor/skills|.cursor/skills/|.agents/skills|.agents/skills/|skills/|skills)
      return 0
      ;;
    AGENTS.md|CLAUDE.md|.envrc|.env.example|.gitignore|.github-agent.local)
      return 0
      ;;
    blob/main|Milkywayrules/verasic-skills|actions/checkout)
      return 0
      ;;
    .md|.mdc|SKILL.md|integrity.sha256|integrity.txt|test-regression.sh)
      return 0
      ;;
    laravel.md|flutter.md|src/foo.ts|scripts/release.sh|refs/remotes/origin/HEAD)
      return 0
      ;;
    verasic-jsdoc-and-comments.mdc)
      return 0
      ;;
  esac
  [[ "$ref" =~ ^origin/ ]] && return 0
  [[ "$ref" =~ ^/var/ ]] && return 0
  [[ "$ref" =~ ^\./docs/research/ ]] && return 0

  if [[ "$source_file" == "$INIT_PROTOCOL" ]]; then
    if [[ "$ref" =~ ^scripts/ ]] && in_init_protocol_table "$line_no"; then
      return 0
    fi
    case "$ref" in
      scripts/check-gh.sh|scripts/bootstrap.sh|scripts/wire-hook.sh|check-gh.sh|bootstrap.sh|wire-hook.sh)
        return 0
        ;;
    esac
  fi

  if [[ "$source_file" == */references/scanner-notes.md ]]; then
    case "$ref" in
      bootstrap.sh|wire-hook.sh|check-gh.sh|load-gh-env.sh)
        return 0
        ;;
    esac
  fi

  return 1
}

first_existing() {
  local candidate
  for candidate in "$@"; do
    [[ -n "$candidate" && -f "$candidate" ]] && { echo "$candidate"; return 0; }
  done
  echo "${!#}"
}

find_in_skills() {
  local ref="$1"
  local -a hits=()
  mapfile -t hits < <(find "$SKILLS_DIR" -path "*/$ref" -type f 2>/dev/null | sort)
  [[ "${#hits[@]}" -eq 1 ]] && { echo "${hits[0]}"; return 0; }
  return 1
}

resolve_ref() {
  local ref="$1"
  local source_file="$2"
  local skill_root src_dir candidates=()

  ref="$(map_install_path "$ref")"

  case "$ref" in
    skills/*|cursor/*|.github/*|SECURITY.md|CHANGELOG.md|README.md|versions.lock|setup.sh)
      echo "$REPO_ROOT/$ref"
      return 0
      ;;
  esac

  # workflow shorthand in changelog/docs
  if [[ "$ref" =~ ^verasic-.*\.yml$ ]]; then
    echo "$REPO_ROOT/.github/workflows/$ref"
    return 0
  fi

  skill_root="$(skill_root_for "$source_file")"
  src_dir="$(dirname "$source_file")"

  if [[ "$ref" == ../* || "$ref" == */../* ]]; then
    echo "$(cd "$src_dir" && cd "$(dirname "$ref")" && pwd)/$(basename "$ref")"
    return 0
  fi

  # same-directory / relative markdown links
  if [[ "$ref" != */* && "$ref" == *.* ]]; then
    candidates+=("$src_dir/$ref")
  fi
  if [[ "$ref" == ./* ]]; then
    candidates+=("$(cd "$src_dir" && cd "$(dirname "$ref")" && pwd)/$(basename "$ref")")
  fi

  if [[ "$ref" == scripts/* ]]; then
    candidates+=("$REPO_ROOT/$ref")
    [[ -n "$skill_root" ]] && candidates+=("$skill_root/$ref")
  elif [[ "$ref" == references/* ]]; then
    [[ -n "$skill_root" ]] && candidates+=("$skill_root/$ref")
    candidates+=("$REPO_ROOT/$ref")
  elif [[ -n "$skill_root" ]]; then
    if [[ "$ref" == */* ]]; then
      candidates+=("$skill_root/$ref")
      candidates+=("$REPO_ROOT/$ref")
    else
      local sub
      for sub in references references/domain-packs scripts templates workflows checklists hooks .; do
        candidates+=("$skill_root/$sub/$ref")
      done
      if [[ "$ref" == .* ]]; then
        candidates+=("$skill_root/templates/${ref#.}")
        candidates+=("$skill_root/templates/$ref")
      fi
    fi
  fi

  candidates+=("$REPO_ROOT/scripts/$ref")
  [[ "$ref" == "manifest.txt" ]] && candidates+=("$SKILLS_DIR/verasic-init/manifest.txt")

  if [[ "$ref" == */* ]]; then
    local found=""
    found="$(find_in_skills "$ref" 2>/dev/null || true)"
    [[ -n "$found" ]] && candidates+=("$found")
  else
    local found=""
    found="$(find_in_skills "$ref" 2>/dev/null || true)"
    [[ -n "$found" ]] && candidates+=("$found")
  fi

  candidates+=("$REPO_ROOT/$ref")

  first_existing "${candidates[@]}"
}

extract_refs_from_file() {
  local file="$1"
  local line_no=0 line rest target token

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))

    rest="$line"
    while [[ "$rest" == *']('* ]]; do
      rest="${rest#*']('}"
      target="${rest%%)*}"
      [[ "$target" != "$rest" ]] && printf '%s\t%s\tlink\n' "$line_no" "$target"
      rest="${rest#*)}"
    done

    rest="$line"
    while [[ "$rest" == *'`'* ]]; do
      rest="${rest#*\`}"
      token="${rest%%\`*}"
      if [[ "$token" != "$rest" ]]; then
        token="$(normalize_ref "$token")"
        looks_like_path "$token" && printf '%s\t%s\tbacktick\n' "$line_no" "$token"
      fi
      rest="${rest#*\`}"
    done
  done < "$file"
}

validate_file() {
  local file="$1"
  local rel="${file#"$REPO_ROOT"/}"
  local line_no ref kind resolved

  while IFS=$'\t' read -r line_no ref kind; do
    [[ -z "$ref" ]] && continue
    ref="$(normalize_ref "$ref")"
    should_skip_ref "$ref" "$file" "$line_no" && { skip_ref; continue; }
    looks_like_path "$ref" || { skip_ref; continue; }

    resolved="$(resolve_ref "$ref" "$file")"
    if [[ -f "$resolved" ]]; then
      ok "$rel:$line_no ($kind) $ref"
    else
      bad "$rel:$line_no ($kind) missing: $ref → $resolved"
    fi
  done < <(extract_refs_from_file "$file")
}

echo "== check-references =="
echo "repo: $REPO_ROOT"
echo

mapfile -t MD_FILES < <(
  find "$REPO_ROOT" -type f \( -name '*.md' -o -name '*.mdc' \) \
    ! -path '*/.git/*' | sort
)

for file in "${MD_FILES[@]}"; do
  validate_file "$file"
done

echo "---"
echo "check-references: $pass passed, $fail failed, $skip skipped"
[[ "$fail" -eq 0 ]]
