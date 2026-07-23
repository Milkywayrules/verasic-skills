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

# Resolve effective scope: comma string or VERASIC_INIT_SCOPE env
verasic_profile_scope_csv() {
  local csv="${1:-${VERASIC_INIT_SCOPE:-}}"
  csv="${csv//[[:space:]]/}"
  printf '%s' "$csv"
}

verasic_profile_scope_contains() {
  local skill="$1" csv="$2"
  [[ -z "$csv" ]] && return 1
  [[ ",$csv," == *",$skill,"* ]]
}

verasic_profile_skill_ux_map() {
  local skill_root="$1"
  local map="$skill_root/references/skill-ux-map.txt"
  local line stripped skill relpath kind

  if [[ ! -f "$map" ]]; then
    echo "profile: skill UX map missing — references/skill-ux-map.txt" >&2
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped//$'\r'/}"
    stripped="${stripped#"${stripped%%[![:space:]]*}"}"
    stripped="${stripped%"${stripped##*[![:space:]]}"}"
    [[ -z "$stripped" ]] && continue
    IFS='|' read -r skill relpath kind <<< "$stripped"
    skill="${skill//[[:space:]]/}"
    relpath="${relpath//[[:space:]]/}"
    kind="${kind//[[:space:]]/}"
    [[ -z "$skill" || -z "$relpath" ]] && continue
    printf '%s|%s|%s\n' "$skill" "$relpath" "$kind"
  done < "$map"
}

verasic_profile_scoped_ux_paths() {
  local skill_root="$1" scope_csv="$2"
  local -a paths=()
  local line skill relpath kind

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    IFS='|' read -r skill relpath kind <<< "$line"
    verasic_profile_scope_contains "$skill" "$scope_csv" || continue
    paths+=("$relpath")
  done < <(verasic_profile_skill_ux_map "$skill_root")

  if ((${#paths[@]} > 0)); then
    printf '%s\n' "${paths[@]}"
  fi
}

verasic_profile_count_scoped_ux_paths() {
  local skill_root="$1" scope_csv="$2"
  local n=0 line skill relpath kind

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    IFS='|' read -r skill relpath kind <<< "$line"
    verasic_profile_scope_contains "$skill" "$scope_csv" || continue
    n=$((n + 1))
  done < <(verasic_profile_skill_ux_map "$skill_root")

  echo "$n"
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
  local profile="$1" skill_root="$2" scope_csv="${3:-}"
  local base fallback main_base
  local -a paths=()

  case "$profile" in
    cursor|cursor-hybrid) ;;
    *) return 0 ;;
  esac

  scope_csv="$(verasic_profile_scope_csv "$scope_csv")"
  mapfile -t paths < <(verasic_profile_scoped_ux_paths "$skill_root" "$scope_csv") || return 1

  if ((${#paths[@]} == 0)); then
    echo "profile: no Cursor UX files for effective scope"
    PROFILE_FETCHED=0
    PROFILE_FAILED=0
    return 0
  fi

  mkdir -p "$REPO_ROOT/.cursor/agents" "$REPO_ROOT/.cursor/commands" "$REPO_ROOT/.cursor/rules"

  base="$(verasic_profile_remote_repo_base "$skill_root")"
  main_base="$(verasic_profile_main_repo_base)"
  if verasic_profile_fetch_cursor_from_base "$base" "${paths[@]}"; then
    echo "profile: installed Cursor UX from upstream ($PROFILE_FETCHED file(s) for scope, base: $base)"
    return 0
  fi

  if [[ "$base" != "$main_base" && -z "${VERASIC_INIT_REMOTE_REPO_BASE:-}" ]]; then
    echo "profile: tag base unavailable — retrying from main" >&2
    if verasic_profile_fetch_cursor_from_base "$main_base" "${paths[@]}"; then
      echo "profile: installed Cursor UX from upstream ($PROFILE_FETCHED file(s) for scope, base: $main_base, fallback from tag)"
      return 0
    fi
  fi

  echo "profile: Cursor UX install failed ($PROFILE_FAILED file(s)) — check network or set VERASIC_INIT_REMOTE_REPO_BASE"
  return 1
}

verasic_profile_scope_has_repo_wiring() {
  local scope_csv="$1"
  shift
  local -a manifest_lines=("$@")
  local line name wire f3 f4

  for line in "${manifest_lines[@]}"; do
    IFS='|' read -r name wire f3 f4 <<< "$line"
    name="${name//[[:space:]]/}"
    wire="${wire//[[:space:]]/}"
    [[ -z "$name" || "$name" == \#* ]] && continue
    verasic_profile_scope_contains "$name" "$scope_csv" || continue
    [[ "$wire" != "-" && -n "$wire" ]] && return 0
  done
  return 1
}

verasic_profile_print_scope_section() {
  local scope_csv="$1" scope_source="$2"
  echo " scope"
  echo " -----"
  if [[ -z "$scope_csv" ]]; then
    echo "   (empty — no installed manifest skills in repo)"
  else
    IFS=',' read -ra scoped <<< "$scope_csv"
    local s
    for s in "${scoped[@]}"; do
      [[ -z "$s" ]] && continue
      printf '   • %s\n' "$s"
    done
  fi
  printf '   source: %s\n' "$scope_source"
  echo
}

verasic_profile_print_checklist_ux() {
  local profile="$1" skill_root="$2" scope_csv="$3"
  local line skill relpath kind label

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    IFS='|' read -r skill relpath kind <<< "$line"
    verasic_profile_scope_contains "$skill" "$scope_csv" || continue
    case "$kind" in
      rule) label="rules" ;;
      command) label="slash commands" ;;
      agent) label="subagents" ;;
      *) label="$kind" ;;
    esac
    verasic_profile_check_path "$label" ".cursor/$relpath"
  done < <(verasic_profile_skill_ux_map "$skill_root")
}

verasic_profile_print_usage_scoped() {
  local profile="$1" scope_csv="$2"
  local has_cmd=false has_rule=false has_agent=false

  verasic_profile_scope_contains verasic-init "$scope_csv" && has_cmd=true
  verasic_profile_scope_contains verasic-bugbot "$scope_csv" && { has_cmd=true; has_agent=true; }
  verasic_profile_scope_contains verasic-git-commits "$scope_csv" && { has_cmd=true; has_rule=true; has_agent=true; }
  verasic_profile_scope_contains verasic-github-env "$scope_csv" && { has_cmd=true; has_rule=true; }
  verasic_profile_scope_contains verasic-fusion "$scope_csv" && has_cmd=true
  verasic_profile_scope_contains verasic-deep-research "$scope_csv" && has_cmd=true

  if [[ "$profile" == agent ]]; then
    echo "   • Invoke by skill name for skills in scope — no /verasic-* commands unless you add Cursor UX"
    verasic_profile_scope_contains verasic-bugbot "$scope_csv" && echo "   • verasic-bugbot — local bugbot-style code review (read SKILL.md)"
    verasic_profile_scope_contains verasic-fusion "$scope_csv" && echo "   • verasic-fusion — multi-model fusion for exploration and decision support"
    verasic_profile_scope_contains verasic-deep-research "$scope_csv" && echo "   • verasic-deep-research — ledger-backed research with confidence scoring"
    verasic_profile_scope_contains verasic-git-commits "$scope_csv" && echo "   • verasic-git-commits — commit convention + deterministic commit-msg hook"
    verasic_profile_scope_contains verasic-github-env "$scope_csv" && echo "   • verasic-github-env — GitHub CLI auth for local agent harnesses"
    verasic_profile_scope_contains verasic-init "$scope_csv" && echo "   • verasic-init — re-run this setup orchestrator"
    echo "   • Works with Claude Code, Codex, Kiro, Windsurf, skills.sh, and other agents that load project skills"
  else
    local cmds=()
    verasic_profile_scope_contains verasic-init "$scope_csv" && cmds+=("/verasic-init")
    verasic_profile_scope_contains verasic-bugbot "$scope_csv" && cmds+=("/verasic-review")
    verasic_profile_scope_contains verasic-fusion "$scope_csv" && cmds+=("/verasic-fusion")
    verasic_profile_scope_contains verasic-deep-research "$scope_csv" && cmds+=("/verasic-deep-research")
    verasic_profile_scope_contains verasic-git-commits "$scope_csv" && cmds+=("/verasic-audit-commits")
    verasic_profile_scope_contains verasic-github-env "$scope_csv" && cmds+=("/verasic-setup-github")
    if ((${#cmds[@]} > 0)); then
      local joined="${cmds[0]}"
      local c
      for c in "${cmds[@]:1}"; do joined+=", $c"; done
      echo "   • Slash commands (scope): $joined"
    else
      echo "   • No slash commands in effective scope"
    fi
    if $has_rule; then
      echo "   • Always-on rules in scope under .cursor/rules/"
    fi
    if $has_agent; then
      local agents=()
      verasic_profile_scope_contains verasic-bugbot "$scope_csv" && agents+=("verasic-bugbot")
      verasic_profile_scope_contains verasic-git-commits "$scope_csv" && agents+=("verasic-commit-auditor")
      if ((${#agents[@]} > 0)); then
        local ajoined="${agents[0]}"
        local a
        for a in "${agents[@]:1}"; do ajoined+=", $a"; done
        echo "   • Subagents (scope): $ajoined"
      fi
    fi
    if [[ "$profile" == cursor-hybrid ]]; then
      echo "   • Skills live under .agents/skills/ — adjust path prefix in commands when needed"
      echo "   • Repo wiring (hooks, .envrc, credentials) uses .agents/skills/"
    fi
  fi
}

verasic_profile_print_section() {
  local profile="$1" skills_root="$2" apply="$3" scope_csv="$4" scope_source="$5"
  local rel_root="${skills_root#"$REPO_ROOT"/}"
  local init_skill="$skills_root/verasic-init"
  local remote_base ux_count=0
  remote_base="$(verasic_profile_remote_repo_base "$init_skill")"
  scope_csv="$(verasic_profile_scope_csv "$scope_csv")"
  ux_count="$(verasic_profile_count_scoped_ux_paths "$init_skill" "$scope_csv")"
  local cs=false as=false ux=false
  [[ -d "$REPO_ROOT/.cursor/skills/verasic-init" ]] && cs=true
  [[ -d "$REPO_ROOT/.agents/skills/verasic-init" ]] && as=true
  [[ -f "$REPO_ROOT/.cursor/commands/verasic-init.md" ]] && ux=true

  echo " install profile"
  echo " ---------------"
  if $apply; then
    if [[ "$profile" == cursor || "$profile" == cursor-hybrid ]]; then
      if ((ux_count > 0)); then
        printf ' %-18s %s (confirmed — fetching %d Cursor UX file(s) for scope)\n' "profile" "$profile" "$ux_count"
      elif verasic_profile_scope_has_repo_wiring "$scope_csv" "${MANIFEST_LINES[@]}"; then
        printf ' %-18s %s (confirmed — applying)\n' "profile" "$profile"
      else
        printf ' %-18s %s (confirmed — scope has no repo wiring)\n' "profile" "$profile"
      fi
    elif verasic_profile_scope_has_repo_wiring "$scope_csv" "${MANIFEST_LINES[@]}"; then
      printf ' %-18s %s (confirmed — applying)\n' "profile" "$profile"
    else
      printf ' %-18s %s (confirmed — scope has no repo wiring)\n' "profile" "$profile"
    fi
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
    if verasic_profile_scope_contains verasic-init "$scope_csv"; then
      verasic_profile_check_path "skills" ".cursor/skills/verasic-init"
    fi
    verasic_profile_print_checklist_ux "$profile" "$init_skill" "$scope_csv"
    if $as && ! $cs; then
      echo "   note: skills also in .agents/skills/ — use --profile cursor-hybrid if that is your only skills root"
    fi
    if verasic_profile_scope_contains verasic-init "$scope_csv" && ! $cs; then
      echo "   gap: cursor profile expects skills under .cursor/skills/ — run setup.sh or install skills there"
    fi
    if ! $apply; then
      if ((ux_count > 0)); then
        echo "   on --yes: would fetch $ux_count Cursor UX file(s) for scope: $scope_csv"
      else
        echo "   on --yes: no Cursor UX files for effective scope (skill-only selection)"
      fi
    fi
  elif [[ "$profile" == cursor-hybrid ]]; then
    if verasic_profile_scope_contains verasic-init "$scope_csv"; then
      verasic_profile_check_path "skills" ".agents/skills/verasic-init"
    fi
    verasic_profile_print_checklist_ux "$profile" "$init_skill" "$scope_csv"
    if $cs; then
      echo "   note: skills also in .cursor/skills/ — hybrid profile wires .agents/skills/ first"
    fi
    if verasic_profile_scope_contains verasic-init "$scope_csv" && ! $as; then
      echo "   gap: cursor-hybrid expects skills under .agents/skills/ — run: npx skills add Milkywayrules/verasic-skills"
    fi
    if ! $apply; then
      if ((ux_count > 0)); then
        echo "   on --yes: would fetch $ux_count Cursor UX file(s) for scope: $scope_csv"
      else
        echo "   on --yes: no Cursor UX files for effective scope (skill-only selection)"
      fi
    fi
  else
    if verasic_profile_scope_contains verasic-init "$scope_csv"; then
      if [[ -d "$skills_root/verasic-init" ]]; then
        verasic_profile_check_path "skills" "$rel_root/verasic-init"
      else
        verasic_profile_check_path "skills" "$rel_root/verasic-init"
      fi
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

  echo " usage (${profile} profile, effective scope)"
  echo " --------------------------------------------"
  verasic_profile_print_usage_scoped "$profile" "$scope_csv"
  echo "   • Full profile spec: $rel_root/verasic-init/references/install-profiles.md"
  echo
}

verasic_profile_plan_next() {
  local apply="$1" profile="$2"
  if ! $apply; then
    echo " next: review plan above; run with --yes --profile $profile to apply (or omit --profile to re-detect)"
  fi
}
