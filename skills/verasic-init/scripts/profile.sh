#!/usr/bin/env bash
# Sourced by init.sh — profile detection, checklist, UX install, usage guide.

verasic_profile_normalize() {
  case "${1,,}" in
    cursor) echo cursor ;;
    agent|skills|skills-only|generic) echo agent ;;
    cursor-hybrid|hybrid) echo cursor-hybrid ;;
    auto|"") echo auto ;;
    *)
      echo "init: unknown profile: $1 (use cursor, agent, cursor-hybrid, or auto)" >&2
      return 1
      ;;
  esac
}

verasic_profile_pref_roots() {
  case "$1" in
    cursor) printf '%s\n' .cursor/skills .agents/skills ;;
    agent|cursor-hybrid) printf '%s\n' .agents/skills .cursor/skills ;;
    *) printf '%s\n' .agents/skills .cursor/skills ;;
  esac
}

verasic_profile_detect() {
  local cs=false as=false ux=false
  [[ -d "$REPO_ROOT/.cursor/skills/verasic-init" ]] && cs=true
  [[ -d "$REPO_ROOT/.agents/skills/verasic-init" ]] && as=true
  [[ -f "$REPO_ROOT/.cursor/commands/verasic-init.md" ]] && ux=true

  if $cs && $ux; then
    echo cursor
  elif $as && $ux && ! $cs; then
    echo cursor-hybrid
  elif $as && ! $cs; then
    echo agent
  elif $cs; then
    echo cursor
  elif $as; then
    echo agent
  elif [[ -n "${SKILLS_ROOT:-}" ]]; then
    if [[ "$SKILLS_ROOT" == *"/.cursor/skills" ]]; then
      echo cursor
    else
      echo agent
    fi
  else
    echo agent
  fi
}

verasic_profile_select_skills_root() {
  local profile="$1"
  shift
  local -a roots=("$@")
  local pref root

  if [[ "${INVOKED_SKILLS_ROOT:-}" == "$REPO_ROOT/"* ]]; then
    printf '%s' "$INVOKED_SKILLS_ROOT"
    return
  fi

  while IFS= read -r pref; do
    [[ -z "$pref" ]] && continue
    for root in "${roots[@]}"; do
      if [[ "$root" == "$REPO_ROOT/$pref" ]]; then
        printf '%s' "$root"
        return
      fi
    done
  done < <(verasic_profile_pref_roots "$profile")

  printf '%s' "${roots[0]}"
}

verasic_profile_check_path() {
  local label="$1" relpath="$2"
  if [[ -e "$REPO_ROOT/$relpath" ]]; then
    printf '   ok:   %-16s (%s)\n' "$label" "$relpath"
  else
    printf '   miss: %-16s (%s)\n' "$label" "$relpath"
  fi
}

verasic_profile_main_repo_base() {
  printf '%s' "https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main"
}

verasic_profile_remote_repo_base() {
  local skill_root="${1:-}"
  local ver=""

  if [[ -n "${VERASIC_INIT_REMOTE_REPO_BASE:-}" ]]; then
    printf '%s' "${VERASIC_INIT_REMOTE_REPO_BASE%/}"
    return
  fi
  if [[ -n "${VERASIC_INIT_REMOTE_VERSION_BASE:-}" ]]; then
    local base="${VERASIC_INIT_REMOTE_VERSION_BASE%/}"
    base="${base%/skills}"
    printf '%s' "${base%/}"
    return
  fi
  if [[ -n "$skill_root" && -f "$skill_root/VERSION" ]]; then
    ver="$(tr -d '[:space:]' < "$skill_root/VERSION")"
  fi
  if [[ -n "$ver" ]]; then
    printf '%s' "https://raw.githubusercontent.com/Milkywayrules/verasic-skills/v${ver}"
  else
    verasic_profile_main_repo_base
  fi
}

verasic_profile_cursor_manifest_paths() {
  local skill_root="$1"
  local manifest="$skill_root/references/cursor-ux-manifest.txt"
  local line stripped

  if [[ ! -f "$manifest" ]]; then
    echo "profile: cursor UX manifest missing — references/cursor-ux-manifest.txt" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped//$'\r'/}"
    stripped="${stripped//[[:space:]]/}"
    [[ -z "$stripped" ]] && continue
    printf '%s\n' "$stripped"
  done < "$manifest"
}

verasic_profile_fetch_cursor_from_base() {
  local base="$1"
  shift
  local -a paths=("$@")
  local relpath dest url fetched=0 failed=0

  for relpath in "${paths[@]}"; do
    dest="$REPO_ROOT/.cursor/$relpath"
    mkdir -p "$(dirname "$dest")"
    if [[ "$base" == http://* || "$base" == https://* ]]; then
      url="$base/cursor/$relpath"
      if curl -fsSL --connect-timeout 5 --max-time 20 "$url" -o "$dest"; then
        fetched=$((fetched + 1))
      else
        echo "profile: fetch failed: $url" >&2
        failed=$((failed + 1))
      fi
    elif [[ -f "$base/cursor/$relpath" ]]; then
      cp "$base/cursor/$relpath" "$dest"
      fetched=$((fetched + 1))
    else
      echo "profile: upstream file missing: $base/cursor/$relpath" >&2
      failed=$((failed + 1))
    fi
  done

  PROFILE_FETCHED=$fetched
  PROFILE_FAILED=$failed
  ((failed == 0))
}

verasic_profile_install_cursor_ux() {
  local profile="$1" skill_root="$2"
  local base fallback main_base
  local -a paths=()

  case "$profile" in
    cursor|cursor-hybrid) ;;
    *) return 0 ;;
  esac

  mapfile -t paths < <(verasic_profile_cursor_manifest_paths "$skill_root") || return 1
  ((${#paths[@]} > 0)) || {
    echo "profile: cursor UX manifest empty" >&2
    return 1
  }

  mkdir -p "$REPO_ROOT/.cursor/agents" "$REPO_ROOT/.cursor/commands" "$REPO_ROOT/.cursor/rules"

  base="$(verasic_profile_remote_repo_base "$skill_root")"
  main_base="$(verasic_profile_main_repo_base)"
  if verasic_profile_fetch_cursor_from_base "$base" "${paths[@]}"; then
    echo "profile: installed Cursor UX from upstream ($PROFILE_FETCHED files, base: $base)"
    return 0
  fi

  if [[ "$base" != "$main_base" && -z "${VERASIC_INIT_REMOTE_REPO_BASE:-}" ]]; then
    echo "profile: tag base unavailable — retrying from main" >&2
    if verasic_profile_fetch_cursor_from_base "$main_base" "${paths[@]}"; then
      echo "profile: installed Cursor UX from upstream ($PROFILE_FETCHED files, base: $main_base, fallback from tag)"
      return 0
    fi
  fi

  echo "profile: Cursor UX install failed ($PROFILE_FAILED file(s)) — check network or set VERASIC_INIT_REMOTE_REPO_BASE"
  return 1
}

verasic_profile_print_section() {
  local profile="$1" skills_root="$2" apply="$3"
  local rel_root="${skills_root#"$REPO_ROOT"/}"
  local init_skill="$skills_root/verasic-init"
  local remote_base
  remote_base="$(verasic_profile_remote_repo_base "$init_skill")"
  local cs=false as=false ux=false
  [[ -d "$REPO_ROOT/.cursor/skills/verasic-init" ]] && cs=true
  [[ -d "$REPO_ROOT/.agents/skills/verasic-init" ]] && as=true
  [[ -f "$REPO_ROOT/.cursor/commands/verasic-init.md" ]] && ux=true

  echo " install profile"
  echo " ---------------"
  if $apply; then
    printf ' %-18s %s (confirmed — applying)\n' "profile" "$profile"
  else
    printf ' %-18s %s (plan only — pass --yes to apply)\n' "profile" "$profile"
  fi
  printf ' %-18s %s\n' "skills root" "$rel_root"
  if [[ "$profile" == cursor || "$profile" == cursor-hybrid ]]; then
    printf ' %-18s %s\n' "ux upstream" "$remote_base/cursor/"
  fi
  echo

  echo " profile checklist"
  echo " -----------------"
  if [[ "$profile" == cursor ]]; then
    verasic_profile_check_path "skills" ".cursor/skills/verasic-init"
    verasic_profile_check_path "slash commands" ".cursor/commands/verasic-init.md"
    verasic_profile_check_path "rules" ".cursor/rules/verasic-git-commits.mdc"
    verasic_profile_check_path "subagents" ".cursor/agents/verasic-bugbot.md"
    if $as && ! $cs; then
      echo "   note: skills also in .agents/skills/ — use --profile cursor-hybrid if that is your only skills root"
    fi
    if ! $cs; then
      echo "   gap: cursor profile expects skills under .cursor/skills/ — run setup.sh or install skills there"
    fi
    if ! $apply; then
      echo "   on --yes: would fetch/sync .cursor/{commands,rules,agents}/ from upstream ($remote_base/cursor/)"
    fi
  elif [[ "$profile" == cursor-hybrid ]]; then
    verasic_profile_check_path "skills" ".agents/skills/verasic-init"
    verasic_profile_check_path "slash commands" ".cursor/commands/verasic-init.md"
    verasic_profile_check_path "rules" ".cursor/rules/verasic-git-commits.mdc"
    verasic_profile_check_path "subagents" ".cursor/agents/verasic-bugbot.md"
    if $cs; then
      echo "   note: skills also in .cursor/skills/ — hybrid profile wires .agents/skills/ first"
    fi
    if ! $as; then
      echo "   gap: cursor-hybrid expects skills under .agents/skills/ — run: npx skills add Milkywayrules/verasic-skills"
    fi
    if ! $apply; then
      echo "   on --yes: would fetch/sync .cursor/{commands,rules,agents}/ from upstream ($remote_base/cursor/)"
    fi
  else
    if [[ -d "$skills_root/verasic-init" ]]; then
      verasic_profile_check_path "skills" "$rel_root/verasic-init"
    else
      verasic_profile_check_path "skills" "$rel_root/verasic-init"
    fi
    if $ux; then
      echo "   note: Cursor UX present — optional for agent profile"
    else
      echo "   ok:   no Cursor UX required (invoke skills by name / SKILL.md)"
    fi
    if $cs && ! $as; then
      echo "   note: skills under .cursor/skills/ — for Cursor slash UX use --profile cursor --yes"
    fi
  fi
  echo

  echo " usage (${profile} profile)"
  echo " ---------------------------"
  case "$profile" in
    cursor)
      cat <<'EOF'
   • Slash commands: /verasic-init, /verasic-review, /verasic-fusion, /verasic-deep-research, /verasic-audit-commits, /verasic-setup-github
   • Commit + GitHub rules apply automatically under .cursor/rules/
   • Subagents: verasic-bugbot, verasic-commit-auditor
EOF
      ;;
    cursor-hybrid)
      cat <<'EOF'
   • Same slash commands as cursor; skills live under .agents/skills/ — adjust path prefix in commands when needed
   • Repo wiring (hooks, .envrc, credentials) uses .agents/skills/
EOF
      ;;
    agent)
      cat <<'EOF'
   • Invoke by skill name (e.g. verasic-bugbot, verasic-fusion) — no /verasic-* commands unless you add Cursor UX
   • Read each skill's SKILL.md and references/ under your skills root
   • Works with Claude Code, Codex, Kiro, Windsurf, skills.sh, and other agents that load project skills
EOF
      ;;
  esac
  echo "   • Full profile spec: $rel_root/verasic-init/references/install-profiles.md"
  echo
}

verasic_profile_plan_next() {
  local apply="$1" profile="$2"
  if ! $apply; then
    echo " next: review plan above; run with --yes --profile $profile to apply (or omit --profile to re-detect)"
  fi
}
