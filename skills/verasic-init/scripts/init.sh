#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVOKED_SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INVOKED_SKILLS_ROOT="$(cd "$INVOKED_SKILL_ROOT/.." && pwd)"
# shellcheck source=profile.sh
source "$SCRIPT_DIR/profile.sh"

REMOTE_VERSION_BASE="${VERASIC_INIT_REMOTE_VERSION_BASE:-https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/skills}"

usage() {
  cat <<'EOF'
verasic-init — plan and wire installed Verasic skills into this repository

Confirm-first: default prints a setup plan and changes nothing. Pass --yes to apply.

Usage:
  init.sh                          plan only (detect profile, show checklist + would-wire)
  init.sh --yes                    apply using auto-detected profile
  init.sh --yes --profile cursor   Cursor: wire + fetch .cursor/{commands,rules,agents} from upstream
  init.sh --yes --profile agent    Agent host (skills.sh, Claude Code, Codex, Kiro, …): wire only
  init.sh --yes --profile cursor-hybrid  skills in .agents/skills/ + Cursor slash UX
  init.sh --skills a,b             cherry-pick (with --yes to apply)
  init.sh --list                   manifest + integrity inspect, change nothing
  init.sh --verify                 with --yes: run manifest verify scripts after wire
  init.sh --no-strict-integrity    presence-only integrity (skip hash checks)
  init.sh --strict-integrity       hash checks on by default (backward compat, no-op)
  init.sh --check-updates          compare local VERSION to upstream (read-only)
  init.sh --help                   this help

Profile aliases: --cursor, --agent, --cursor-hybrid
Spec: references/install-profiles.md (bundled in this skill)

Idempotent: safe to re-run with --yes. Run from anywhere inside the repo.
Uses repo-local skills roots only — never wires from an external install path.
EOF
}

SELECT=""
SELECT_GIVEN=false
LIST_ONLY=false
VERIFY=false
STRICT_INTEGRITY=true
CHECK_UPDATES=false
CONFIRMED=false
PROFILE="auto"
while (($#)); do
  case "$1" in
    --skills) SELECT="${2:?init: --skills needs a comma-separated list}"; SELECT_GIVEN=true; shift 2 ;;
    --skills=*) SELECT="${1#*=}"; SELECT_GIVEN=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
    --verify) VERIFY=true; shift ;;
    --yes|--confirm) CONFIRMED=true; shift ;;
    --profile) PROFILE="${2:?init: --profile needs cursor, agent, cursor-hybrid, or auto}"; shift 2 ;;
    --profile=*) PROFILE="${1#*=}"; shift ;;
    --cursor) PROFILE=cursor; shift ;;
    --agent) PROFILE=agent; shift ;;
    --cursor-hybrid|--hybrid) PROFILE=cursor-hybrid; shift ;;
    --strict-integrity) shift ;;
    --no-strict-integrity|--loose-integrity) STRICT_INTEGRITY=false; shift ;;
    --check-updates) CHECK_UPDATES=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "init: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SELECT="${SELECT//[[:space:]]/}"
if $SELECT_GIVEN && [[ -z "$SELECT" ]]; then
  echo "init: --skills needs a comma-separated list (got empty)" >&2
  exit 2
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "init: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

is_selected() {
  [[ -z "$SELECT" ]] && return 0
  [[ ",$SELECT," == *",$1,"* ]]
}

# parse_manifest_line name wire f3 f4 -> sets MANIFEST_* globals
parse_manifest_line() {
  local name="$1" wire="$2" f3="$3" f4="${4:-}"
  MANIFEST_NAME="${name//[[:space:]]/}"
  MANIFEST_WIRE="${wire//[[:space:]]/}"
  MANIFEST_VERIFY="-"
  MANIFEST_DESC="${f3%$'\r'}"
  if [[ -n "$f4" ]]; then
    MANIFEST_VERIFY="${f3//[[:space:]]/}"
    MANIFEST_DESC="${f4%$'\r'}"
  fi
}

# check_integrity skill_dir -> prints missing/empty lines; returns 0 when ok
check_integrity() {
  local skill_dir="$1"
  local integrity_file="$skill_dir/integrity.txt"
  local rel missing=() empty=() line stripped

  if [[ ! -f "$integrity_file" ]]; then
    printf 'missing:integrity.txt\n'
    return 1
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped//[[:space:]]/}"
    [[ -z "$stripped" ]] && continue
    rel="$stripped"
    if [[ ! -f "$skill_dir/$rel" ]]; then
      missing+=("$rel")
    elif [[ ! -s "$skill_dir/$rel" ]]; then
      empty+=("$rel")
    fi
  done < "$integrity_file"

  local item
  for item in "${missing[@]}"; do
    printf 'missing:%s\n' "$item"
  done
  for item in "${empty[@]}"; do
    printf 'empty:%s\n' "$item"
  done
  ((${#missing[@]} + ${#empty[@]} == 0))
}

# check_hash_integrity skill_dir -> prints modified:path lines; returns 0 when ok
check_hash_integrity() {
  local skill_dir="$1"
  local hash_file="$skill_dir/integrity.sha256"
  local line stripped stored rel computed modified=()

  if [[ ! -f "$hash_file" ]]; then
    return 0
  fi

  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped#"${stripped%%[![:space:]]*}"}"
    stripped="${stripped%"${stripped##*[![:space:]]}"}"
    [[ -z "$stripped" ]] && continue
    stored="${stripped%% *}"
    rel="${stripped#"$stored"}"
    rel="${rel#"${rel%%[![:space:]]*}"}"
    [[ -z "$rel" ]] && continue
    if [[ ! -f "$skill_dir/$rel" ]]; then
      modified+=("$rel")
      continue
    fi
    computed="$(sha256sum "$skill_dir/$rel" | awk '{print $1}')"
    [[ "$computed" != "$stored" ]] && modified+=("$rel")
  done < "$hash_file"

  local item
  for item in "${modified[@]}"; do
    printf 'modified:%s\n' "$item"
  done
  ((${#modified[@]} == 0))
}

integrity_summary() {
  local skill_dir="$1"
  local issues miss=0 emp=0 mod=0 line
  if check_integrity "$skill_dir" >/dev/null 2>&1; then
    if ! $STRICT_INTEGRITY; then
      echo "presence-only"
      return
    fi
    if ! check_hash_integrity "$skill_dir" >/dev/null 2>&1; then
      issues="$(check_hash_integrity "$skill_dir" 2>/dev/null || true)"
      while IFS= read -r line; do
        [[ "$line" == modified:* ]] && mod=$((mod + 1))
      done <<<"$issues"
      echo "${mod} modified"
      return
    fi
    echo "ok"
    return
  fi
  issues="$(check_integrity "$skill_dir" 2>/dev/null || true)"
  while IFS= read -r line; do
    [[ "$line" == missing:* ]] && miss=$((miss + 1))
    [[ "$line" == empty:* ]] && emp=$((emp + 1))
  done <<<"$issues"
  if ((miss > 0 && emp > 0)); then
    echo "${miss} missing, ${emp} empty"
  elif ((miss > 0)); then
    echo "${miss} missing"
  else
    echo "${emp} empty"
  fi
}

hash_issues_summary() {
  local issues="$1"
  local mod=0 line
  while IFS= read -r line; do
    [[ "$line" == modified:* ]] && mod=$((mod + 1))
  done <<<"$issues"
  if ((mod > 0)); then
    echo "${mod} modified"
  else
    echo "ok"
  fi
}

integrity_action_ok() {
  if $STRICT_INTEGRITY; then
    echo "integrity: ok"
  else
    echo "integrity: presence-only (--no-strict-integrity)"
  fi
}

integrity_action_modified() {
  local issues="$1"
  echo "integrity: modified ($(hash_issues_summary "$issues")) — local patch detected; pass --no-strict-integrity if intentional fork"
}

read_skill_version() {
  local skill_dir="$1"
  local vfile="$skill_dir/VERSION"
  if [[ -f "$vfile" ]]; then
    tr -d '[:space:]' < "$vfile"
  else
    echo "(missing)"
  fi
}

fetch_remote_version() {
  local name="$1"
  local path="$REMOTE_VERSION_BASE/$name/VERSION"
  if [[ "$REMOTE_VERSION_BASE" == http://* || "$REMOTE_VERSION_BASE" == https://* ]]; then
    curl -fsSL --connect-timeout 5 --max-time 10 "$path" 2>/dev/null | tr -d '[:space:]' || true
  elif [[ -f "$path" ]]; then
    tr -d '[:space:]' < "$path"
  fi
}

discover_skill_roots() {
  local -a found=() path candidate
  for candidate in .agents/skills .cursor/skills; do
    path="$REPO_ROOT/$candidate"
    [[ -d "$path" ]] && found+=("$path")
  done
  shopt -s nullglob dotglob
  for path in "$REPO_ROOT"/.*/skills; do
    [[ -d "$path" ]] || continue
    found+=("$path")
  done
  shopt -u nullglob dotglob

  local -a unique=() item seen
  for item in "${found[@]}"; do
    seen=false
    for path in "${unique[@]}"; do
      [[ "$path" == "$item" ]] && seen=true && break
    done
    $seen || unique+=("$item")
  done
  printf '%s\n' "${unique[@]}"
}

resolve_skill_dir() {
  local name="$1"
  local root skill_path="$REPO_ROOT/$name"
  if [[ -d "$skill_path" && -f "$skill_path/SKILL.md" ]]; then
    printf '%s' "$skill_path"
    return 0
  fi
  for root in "${DISCOVERED_ROOTS[@]}"; do
    skill_path="$root/$name"
    if [[ -d "$skill_path" ]]; then
      printf '%s' "$skill_path"
      return 0
    fi
  done
  return 1
}

parse_github_env_status() {
  local out="$1" wire_rc="$2" integrity_ok="$3"
  if ! $integrity_ok; then
    echo "degraded|integrity incomplete after wire"
    return
  fi
  if grep -q 'bootstrap: verify: ok' <<<"$out"; then
    echo "verified|GitHub env verified"
    return
  fi
  if grep -q 'bootstrap: verify: skipped (check-gh missing)' <<<"$out"; then
    echo "degraded|verify skipped — check-gh.sh missing"
    return
  fi
  if grep -q 'bootstrap: verify: skipped' <<<"$out"; then
    echo "wired|wire ok — verify skipped (no token)"
    return
  fi
  echo "wired|wire ok"
}

run_manifest_verify() {
  local name="$1" skill_dir="$2" verify_script="$3" detail_out="$4"
  [[ "$verify_script" == "-" || -z "$verify_script" ]] && return 0
  [[ ! -f "$skill_dir/$verify_script" ]] && return 0

  local rc=0 verify_log="$TMP/${name}.verify"
  bash "$skill_dir/$verify_script" >"$verify_log" 2>&1 || rc=$?
  if [[ -s "$verify_log" ]]; then
    {
      echo
      echo " [manifest verify: $verify_script]"
      sed 's/^/   /' "$verify_log"
    } >>"$detail_out"
  fi
  return "$rc"
}

EXTERNAL_INVOKER=false
[[ "$INVOKED_SKILLS_ROOT" != "$REPO_ROOT/"* ]] && EXTERNAL_INVOKER=true

mapfile -t DISCOVERED_ROOTS < <(discover_skill_roots)

LOCAL_INIT_ROOTS=()
for root in "${DISCOVERED_ROOTS[@]}"; do
  [[ -f "$root/verasic-init/scripts/init.sh" ]] && LOCAL_INIT_ROOTS+=("$root")
done

if ((${#LOCAL_INIT_ROOTS[@]} == 0)); then
  echo "init: verasic-init not installed in this repository — install skills under .cursor/skills/ or .agents/skills/ first" >&2
  exit 1
fi

if ! PROFILE="$(verasic_profile_normalize "$PROFILE")"; then
  exit 2
fi

if [[ "$PROFILE" == auto ]]; then
  PROFILE="$(verasic_profile_detect)"
fi

SKILLS_ROOT="$(verasic_profile_select_skills_root "$PROFILE" "${LOCAL_INIT_ROOTS[@]}")"

PLAN_ONLY=false
if $LIST_ONLY; then
  PLAN_ONLY=true
elif ! $CONFIRMED; then
  PLAN_ONLY=true
fi

MANIFEST="$SKILLS_ROOT/verasic-init/manifest.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "init: manifest not found at $MANIFEST — broken install" >&2
  exit 1
fi

MANIFEST_LINES=()
manifest_entries=()
manifest_names=","
while IFS= read -r mline || [[ -n "$mline" ]]; do
  IFS='|' read -r raw_name raw_wire raw_f3 raw_f4 <<< "$mline"
  parse_manifest_line "$raw_name" "$raw_wire" "$raw_f3" "${raw_f4:-}"
  [[ -z "$MANIFEST_NAME" || "$MANIFEST_NAME" == \#* ]] && continue
  MANIFEST_LINES+=("$mline")
  manifest_entries+=("$MANIFEST_NAME")
  manifest_names+=",$MANIFEST_NAME,"
done < "$MANIFEST"

compute_effective_scope() {
  local -a scope=() name
  if $SELECT_GIVEN; then
    IFS=',' read -ra requested <<< "$SELECT"
    for req in "${requested[@]}"; do
      [[ -z "$req" ]] && continue
      scope+=("$req")
    done
    EFFECTIVE_SCOPE="$(IFS=,; echo "${scope[*]}")"
    SCOPE_SOURCE="--skills"
  else
    for name in "${manifest_entries[@]}"; do
      if resolve_skill_dir "$name" >/dev/null 2>&1; then
        scope+=("$name")
      fi
    done
    EFFECTIVE_SCOPE="$(IFS=,; echo "${scope[*]}")"
    SCOPE_SOURCE="installed subset"
  fi
}

in_effective_scope() {
  [[ -z "${EFFECTIVE_SCOPE:-}" ]] && return 1
  [[ ",$EFFECTIVE_SCOPE," == *",$1,"* ]]
}

compute_effective_scope
VERASIC_INIT_SCOPE="$EFFECTIVE_SCOPE"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PROFILE_INSTALL_LOG=""
PROFILE_UX_FAILED=false
PROFILE_UX_RC=0
if $CONFIRMED && ! $LIST_ONLY; then
  PROFILE_INSTALL_LOG="$TMP/profile-install.log"
  init_skill_dir="$SKILLS_ROOT/verasic-init"
  if [[ ! -d "$init_skill_dir" ]]; then
    init_skill_dir="$(resolve_skill_dir verasic-init)"
  fi
  if [[ "$PROFILE" == cursor || "$PROFILE" == cursor-hybrid ]]; then
    verasic_profile_install_cursor_ux "$PROFILE" "$init_skill_dir" "$EFFECTIVE_SCOPE" >"$PROFILE_INSTALL_LOG" 2>&1 || PROFILE_UX_RC=$?
    ((PROFILE_UX_RC == 0)) || PROFILE_UX_FAILED=true
  fi
fi

names=()
statuses=()
summaries=()
detail_files=()
actions_lines=()
wired=0; verified=0; degraded=0; ready=0; action_needed=0
not_installed=0; not_selected=0; unknown=0; failed=0; broken_install=0
verify_failed=0
list_ok=0
wire_ran=0

for mline in "${MANIFEST_LINES[@]}"; do
  IFS='|' read -r raw_name raw_wire raw_f3 raw_f4 <<< "$mline"
  parse_manifest_line "$raw_name" "$raw_wire" "$raw_f3" "${raw_f4:-}"
  name="$MANIFEST_NAME"
  wire="$MANIFEST_WIRE"
  verify="$MANIFEST_VERIFY"
  desc="$MANIFEST_DESC"

  if ! is_selected "$name"; then
    names+=("$name"); statuses+=("not selected"); summaries+=("skipped by --skills")
    detail_files+=(""); actions_lines+=("")
    not_selected=$((not_selected + 1))
    continue
  fi

  if ! skill_dir="$(resolve_skill_dir "$name")"; then
    summary="$desc"
    if ! $SELECT_GIVEN; then
      summary="$desc — optional; install via skills.sh if needed"
    fi
    names+=("$name"); statuses+=("not installed"); summaries+=("$summary")
    detail_files+=(""); actions_lines+=("")
    not_installed=$((not_installed + 1))
    continue
  fi

  integrity_issues=""
  integrity_ok=true
  if ! integrity_issues="$(check_integrity "$skill_dir" 2>/dev/null)"; then
    integrity_ok=false
  fi

  hash_issues=""
  hash_ok=true
  if $STRICT_INTEGRITY; then
    if ! hash_issues="$(check_hash_integrity "$skill_dir" 2>/dev/null)"; then
      hash_ok=false
    fi
  fi

  if [[ "$wire" == "-" ]]; then
    if $integrity_ok && $hash_ok; then
      names+=("$name"); statuses+=("ready"); summaries+=("no repo wiring needed")
      detail_files+=("")
      actions_lines+=("$(integrity_action_ok)")
      ready=$((ready + 1))
    elif ! $integrity_ok; then
      names+=("$name"); statuses+=("broken install")
      summaries+=("required files missing — re-run the skills install")
      detail_files+=("$TMP/${name}.integrity")
      printf '%s\n' "$integrity_issues" >"$TMP/${name}.integrity"
      actions_lines+=("integrity: failed ($(integrity_summary "$skill_dir"))")
      broken_install=$((broken_install + 1))
    else
      names+=("$name"); statuses+=("broken install")
      summaries+=("integrity hash mismatch — re-run the skills install")
      detail_files+=("$TMP/${name}.hash")
      printf '%s\n' "$hash_issues" >"$TMP/${name}.hash"
      actions_lines+=("$(integrity_action_modified "$hash_issues")")
      broken_install=$((broken_install + 1))
    fi
    continue
  fi

  if $PLAN_ONLY; then
    if $integrity_ok && $hash_ok; then
      names+=("$name"); statuses+=("ok"); summaries+=("would run $wire")
      detail_files+=(""); actions_lines+=("$(integrity_action_ok)")
      list_ok=$((list_ok + 1))
    elif ! $integrity_ok; then
      names+=("$name"); statuses+=("broken install")
      summaries+=("required files missing — would not wire")
      detail_files+=("$TMP/${name}.integrity")
      printf '%s\n' "$integrity_issues" >"$TMP/${name}.integrity"
      actions_lines+=("integrity: failed ($(integrity_summary "$skill_dir"))")
      broken_install=$((broken_install + 1))
    else
      names+=("$name"); statuses+=("broken install")
      summaries+=("integrity hash mismatch — would not wire")
      detail_files+=("$TMP/${name}.hash")
      printf '%s\n' "$hash_issues" >"$TMP/${name}.hash"
      actions_lines+=("$(integrity_action_modified "$hash_issues")")
      broken_install=$((broken_install + 1))
    fi
    continue
  fi

  if ! $integrity_ok; then
    names+=("$name"); statuses+=("broken install")
    summaries+=("required files missing before wire — re-run the skills install")
    detail_files+=("$TMP/${name}.integrity")
    printf '%s\n' "$integrity_issues" >"$TMP/${name}.integrity"
    actions_lines+=("wire: skipped (integrity); integrity: failed ($(integrity_summary "$skill_dir"))")
    broken_install=$((broken_install + 1))
    continue
  fi

  if ! $hash_ok; then
    names+=("$name"); statuses+=("broken install")
    summaries+=("integrity hash mismatch before wire — re-run the skills install")
    detail_files+=("$TMP/${name}.hash")
    printf '%s\n' "$hash_issues" >"$TMP/${name}.hash"
    actions_lines+=("wire: skipped (modified); $(integrity_action_modified "$hash_issues")")
    broken_install=$((broken_install + 1))
    continue
  fi

  if [[ ! -f "$skill_dir/$wire" ]]; then
    names+=("$name"); statuses+=("broken install")
    summaries+=("wire script $wire missing — re-run the skills install")
    detail_files+=(""); actions_lines+=("wire: cannot ($wire missing)")
    broken_install=$((broken_install + 1))
    continue
  fi

  out="$TMP/$name.out"
  rc=0
  bash "$skill_dir/$wire" >"$out" 2>&1 || rc=$?
  wire_ran=$((wire_ran + 1))
  detail_files+=("$out")

  post_integrity_ok=true
  post_issues=""
  if ! post_issues="$(check_integrity "$skill_dir" 2>/dev/null)"; then
    post_integrity_ok=false
  fi

  post_hash_ok=true
  post_hash_issues=""
  if $STRICT_INTEGRITY; then
    if ! post_hash_issues="$(check_hash_integrity "$skill_dir" 2>/dev/null)"; then
      post_hash_ok=false
    fi
  fi

  action_log=""
  if [[ -s "$out" ]]; then
    action_log="$(grep -E '^bootstrap: step:' "$out" 2>/dev/null || true)"
  fi
  [[ -z "$action_log" ]] && action_log="wire: ran $wire"

  verify_rc=0
  verify_note=""
  if $VERIFY && [[ "$rc" -eq 0 ]]; then
    if run_manifest_verify "$name" "$skill_dir" "$verify" "$out"; then
      verify_note="verify: ok"
    else
      verify_rc=$?
      verify_note="verify: failed"
      verify_failed=$((verify_failed + 1))
    fi
  fi

  case "$rc" in
    0)
      if [[ "$name" == verasic-github-env ]]; then
        IFS='|' read -r st sum <<< "$(parse_github_env_status "$(cat "$out")" "$rc" "$post_integrity_ok")"
        if $VERIFY && [[ "$verify_rc" -ne 0 ]]; then
          st="action needed"
          sum="manifest verify failed — see details"
        elif ! $post_hash_ok; then
          st="degraded"
          sum="wire ok but integrity hash mismatch"
        fi
        names+=("$name"); statuses+=("$st"); summaries+=("${sum:-$desc}")
        case "$st" in
          verified)
            verified=$((verified + 1))
            actions_lines+=("$action_log; $(integrity_action_ok)${verify_note:+; $verify_note}")
            ;;
          degraded)
            degraded=$((degraded + 1))
            if ! $post_hash_ok; then
              actions_lines+=("$action_log; $(integrity_action_modified "$post_hash_issues")${verify_note:+; $verify_note}")
              printf '%s\n' "$post_hash_issues" >>"$out"
            else
              actions_lines+=("$action_log; integrity: $([[ $post_integrity_ok == true ]] && echo ok || echo incomplete); verify: skipped${verify_note:+; $verify_note}")
            fi
            ;;
          wired)
            wired=$((wired + 1))
            actions_lines+=("$action_log; $(integrity_action_ok)${verify_note:+; $verify_note}")
            ;;
          action\ needed)
            action_needed=$((action_needed + 1))
            actions_lines+=("$action_log; $(integrity_action_ok); $verify_note")
            ;;
        esac
      elif ! $post_integrity_ok; then
        names+=("$name"); statuses+=("degraded"); summaries+=("wire ok but integrity incomplete")
        printf '%s\n' "$post_issues" >>"$out"
        actions_lines+=("$action_log; integrity: incomplete${verify_note:+; $verify_note}")
        degraded=$((degraded + 1))
      elif ! $post_hash_ok; then
        names+=("$name"); statuses+=("degraded"); summaries+=("wire ok but integrity hash mismatch")
        printf '%s\n' "$post_hash_issues" >>"$out"
        actions_lines+=("$action_log; $(integrity_action_modified "$post_hash_issues")${verify_note:+; $verify_note}")
        degraded=$((degraded + 1))
      elif $VERIFY && [[ "$verify_rc" -ne 0 ]]; then
        names+=("$name"); statuses+=("action needed"); summaries+=("manifest verify failed — see details")
        actions_lines+=("$action_log; $(integrity_action_ok); $verify_note")
        action_needed=$((action_needed + 1))
      else
        names+=("$name"); statuses+=("wired"); summaries+=("$desc")
        actions_lines+=("$action_log; $(integrity_action_ok)${verify_note:+; $verify_note}")
        wired=$((wired + 1))
      fi
      ;;
    3)
      names+=("$name"); statuses+=("action needed"); summaries+=("manual step required — see details")
      actions_lines+=("$action_log; $(integrity_action_ok)${verify_note:+; $verify_note}")
      action_needed=$((action_needed + 1))
      ;;
    *)
      names+=("$name"); statuses+=("FAILED"); summaries+=("exit $rc — see details")
      actions_lines+=("wire: failed (exit $rc)")
      failed=$((failed + 1))
      ;;
  esac
done

# Auto-run verasic-config scaffold when another skill is in scope but config was
# not cherry-picked (scaffold checklist §E).
if ! $PLAN_ONLY && $CONFIRMED && $SELECT_GIVEN && ! is_selected verasic-config; then
  config_wire="scripts/scaffold-artifacts.sh"
  if config_dir="$(resolve_skill_dir verasic-config 2>/dev/null)" && [[ -f "$config_dir/$config_wire" ]]; then
    need_config_scaffold=false
    if [[ -n "$EFFECTIVE_SCOPE" ]]; then
      IFS=',' read -ra _scope_parts <<< "$EFFECTIVE_SCOPE"
      for _sc_name in "${_scope_parts[@]}"; do
        [[ "$_sc_name" == verasic-init ]] && continue
        if resolve_skill_dir "$_sc_name" >/dev/null 2>&1; then
          need_config_scaffold=true
          break
        fi
      done
    fi
    if $need_config_scaffold; then
      _cfg_integrity_ok=true
      _cfg_hash_ok=true
      if ! check_integrity "$config_dir" >/dev/null 2>&1; then
        _cfg_integrity_ok=false
      fi
      if $STRICT_INTEGRITY && ! check_hash_integrity "$config_dir" >/dev/null 2>&1; then
        _cfg_hash_ok=false
      fi
      if $_cfg_integrity_ok && $_cfg_hash_ok; then
        out="$TMP/verasic-config-autoscaffold.out"
        rc=0
        bash "$config_dir/$config_wire" >"$out" 2>&1 || rc=$?
        wire_ran=$((wire_ran + 1))
        detail_files+=("$out")
        action_log=""
        if [[ -s "$out" ]]; then
          action_log="$(grep -E '^scaffold: step:' "$out" 2>/dev/null || true)"
        fi
        [[ -z "$action_log" ]] && action_log="wire: ran $config_wire (auto)"
        case "$rc" in
          0)
            names+=("verasic-config")
            statuses+=("wired")
            summaries+=("repo config hub — artifact dirs and verasic.config.ts scaffold (auto)")
            actions_lines+=("$action_log; $(integrity_action_ok)")
            wired=$((wired + 1))
            ;;
          3)
            names+=("verasic-config")
            statuses+=("action needed")
            summaries+=("manual step required — see details")
            actions_lines+=("$action_log; $(integrity_action_ok)")
            action_needed=$((action_needed + 1))
            ;;
          *)
            names+=("verasic-config")
            statuses+=("FAILED")
            summaries+=("exit $rc — see details")
            actions_lines+=("wire: failed (exit $rc)")
            failed=$((failed + 1))
            ;;
        esac
      fi
    fi
  fi
fi

if [[ -n "$SELECT" ]]; then
  IFS=',' read -ra requested <<< "$SELECT"
  for req in "${requested[@]}"; do
    [[ -z "$req" ]] && continue
    if [[ "$manifest_names" != *",$req,"* ]]; then
      names+=("$req"); statuses+=("unknown"); summaries+=("not in manifest — check spelling")
      detail_files+=(""); actions_lines+=("")
      unknown=$((unknown + 1))
    fi
  done
fi

if $PROFILE_UX_FAILED; then
  names+=("cursor-ux")
  statuses+=("FAILED")
  summaries+=("upstream Cursor UX fetch failed — see profile actions")
  detail_files+=("$PROFILE_INSTALL_LOG")
  actions_lines+=("profile: fetch failed (exit $PROFILE_UX_RC)")
  failed=$((failed + 1))
fi

RULE="────────────────────────────────────────────────────────────────"
origin="$(git remote get-url origin 2>/dev/null || echo '(no origin remote)')"
origin="$(printf '%s' "$origin" | sed -E 's#://[^/@]*@#://#')"

echo "$RULE"
if $LIST_ONLY; then
  echo " verasic-init · installed skills (no changes made)"
elif $PLAN_ONLY; then
  echo " verasic-init · setup plan (no changes made)"
else
  echo " verasic-init · repository setup report"
fi
echo "$RULE"
printf ' %-18s %s\n' "repo root" "$REPO_ROOT"
printf ' %-18s %s\n' "origin" "$origin"
printf ' %-18s %s\n' "skills root" "${SKILLS_ROOT#"$REPO_ROOT"/}"
if $EXTERNAL_INVOKER; then
  printf ' %-18s %s\n' "warning" "init invoked from outside repo ($INVOKED_SKILLS_ROOT) — using repo-local skills only"
fi
echo

if ! $LIST_ONLY; then
  verasic_profile_print_scope_section "$EFFECTIVE_SCOPE" "$SCOPE_SOURCE"
  verasic_profile_print_section "$PROFILE" "$SKILLS_ROOT" "$CONFIRMED" "$EFFECTIVE_SCOPE" "$SCOPE_SOURCE"
  if [[ -n "$PROFILE_INSTALL_LOG" && -s "$PROFILE_INSTALL_LOG" ]]; then
    echo " profile actions"
    echo " ----------------"
    sed 's/^/   /' "$PROFILE_INSTALL_LOG"
    echo
  fi
fi

echo " skill roots"
echo " -----------"
if ((${#DISCOVERED_ROOTS[@]} == 0)); then
  echo "   (none found under repo root)"
else
  for root in "${DISCOVERED_ROOTS[@]}"; do
    rel="${root#"$REPO_ROOT"/}"
    printf '   %-30s' "$rel"
    if [[ -f "$root/verasic-init/scripts/init.sh" ]]; then
      printf ' verasic-init present'
    else
      printf ' (no verasic-init)'
    fi
    echo
    for rline in "${MANIFEST_LINES[@]}"; do
      IFS='|' read -r rname rwire rf3 rf4 <<< "$rline"
      parse_manifest_line "$rname" "$rwire" "$rf3" "${rf4:-}"
      [[ -z "$MANIFEST_NAME" || "$MANIFEST_NAME" == \#* ]] && continue
      if $SELECT_GIVEN && ! is_selected "$MANIFEST_NAME"; then
        continue
      fi
      if [[ -d "$root/$MANIFEST_NAME" ]]; then
        printf '      %-22s %s\n' "$MANIFEST_NAME" "$(integrity_summary "$root/$MANIFEST_NAME")"
      fi
    done
  done
fi
echo

echo " versions"
echo " --------"
echo " (VERSION is hashed in integrity.sha256 — version and integrity move together)"
scope_versions=()
if [[ -n "$EFFECTIVE_SCOPE" ]]; then
  IFS=',' read -ra scope_versions <<< "$EFFECTIVE_SCOPE"
fi
manifest_omitted=()
for mname in "${manifest_entries[@]}"; do
  in_effective_scope "$mname" || {
    manifest_omitted+=("$mname")
    continue
  }
  if skill_dir="$(resolve_skill_dir "$mname" 2>/dev/null)"; then
    local_ver="$(read_skill_version "$skill_dir")"
  else
    local_ver="(not installed)"
  fi
  status_note=""
  if $CHECK_UPDATES; then
    remote_ver="$(fetch_remote_version "$mname")"
    if [[ -z "$remote_ver" ]]; then
      status_note="(upstream unavailable)"
    elif [[ "$local_ver" == "$remote_ver" ]]; then
      status_note="up to date"
    else
      status_note="${remote_ver} available"
    fi
    printf ' %-22s %-8s %s\n' "$mname" "$local_ver" "$status_note"
  else
    printf ' %-22s %s\n' "$mname" "$local_ver"
  fi
done
if ((${#manifest_omitted[@]} > 0)) && ! $SELECT_GIVEN; then
  echo "   (manifest skills omitted from scope — not installed: ${manifest_omitted[*]})"
fi
echo

printf ' %-22s %-15s %s\n' "SKILL" "STATUS" "SUMMARY"
printf ' %-22s %-15s %s\n' "-----" "------" "-------"
for i in ${names[@]+"${!names[@]}"}; do
  printf ' %-22s %-15s %s\n' "${names[$i]}" "${statuses[$i]}" "${summaries[$i]}"
done

has_details=false
for f in ${detail_files[@]+"${detail_files[@]}"}; do
  [[ -n "$f" && -s "$f" ]] && has_details=true
done
if $has_details; then
  echo
  echo " details"
  echo " -------"
  for i in ${names[@]+"${!names[@]}"}; do
    f="${detail_files[$i]}"
    [[ -n "$f" && -s "$f" ]] || continue
    echo
    echo " [${names[$i]}]"
    sed 's/^/   /' "$f"
  done
fi

has_actions=false
for a in ${actions_lines[@]+"${actions_lines[@]}"}; do
  [[ -n "$a" ]] && has_actions=true
done
if $has_actions; then
  echo
  echo " actions"
  echo " -------"
  for i in ${names[@]+"${!names[@]}"}; do
    a="${actions_lines[$i]}"
    [[ -n "$a" ]] || continue
    printf '   %-22s %s\n' "${names[$i]}" "$a"
  done
fi

echo
if $LIST_ONLY; then
  printf ' result: %d ok · %d ready · %d broken install · %d not installed · %d not selected · %d unknown\n' \
    "$list_ok" "$ready" "$broken_install" "$not_installed" "$not_selected" "$unknown"
else
  printf ' result: %d verified · %d wired · %d degraded · %d ready · %d action needed · %d broken install · %d not installed · %d not selected · %d unknown · %d failed' \
    "$verified" "$wired" "$degraded" "$ready" "$action_needed" "$broken_install" "$not_installed" "$not_selected" "$unknown" "$failed"
  if ((verify_failed > 0)); then
    printf ' · %d verify failed' "$verify_failed"
  fi
  echo
  if $PLAN_ONLY; then
    verasic_profile_plan_next false "$PROFILE"
  elif $PROFILE_UX_FAILED; then
    echo " next: fix Cursor UX fetch in profile actions (network or VERASIC_INIT_REMOTE_REPO_BASE), then re-run --yes --profile $PROFILE"
  elif ((failed > 0 || broken_install > 0)); then
    echo " next: fix broken installs and failures above, then re-run with --yes --profile $PROFILE"
  elif ((verify_failed > 0)); then
    echo " next: fix verify failures above, then re-run --yes --profile $PROFILE --verify"
  elif ((action_needed > 0)); then
    echo " next: complete the manual steps in the details above, then re-run --yes --profile $PROFILE"
  elif ((unknown > 0)); then
    echo " next: fix the unknown skill name(s) above and re-run with corrected --skills"
  else
    echo " next: follow any 'Next steps' lines in details above; re-run --yes anytime (idempotent)"
  fi
fi
echo "$RULE"

((failed == 0 && broken_install == 0)) || exit 1
if ((verify_failed > 0)); then
  exit 3
fi
if ((unknown > 0 && verified + wired + degraded + ready + action_needed + list_ok == 0)); then
  exit 2
fi
exit 0
