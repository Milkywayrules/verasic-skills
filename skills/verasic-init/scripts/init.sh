#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVOKED_SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INVOKED_SKILLS_ROOT="$(cd "$INVOKED_SKILL_ROOT/.." && pwd)"

usage() {
  cat <<'EOF'
verasic-init — wire installed Verasic skills into this repository

Usage:
  init.sh                  wire every installed verasic skill
  init.sh --skills a,b     wire only the listed skills (cherry-pick)
  init.sh --list           show manifest + installed state, change nothing
  init.sh --help           this help

Idempotent: safe to re-run anytime. Run from anywhere inside the repo.
Uses repo-local skills roots only — never wires from an external install path.
EOF
}

SELECT=""
SELECT_GIVEN=false
LIST_ONLY=false
while (($#)); do
  case "$1" in
    --skills) SELECT="${2:?init: --skills needs a comma-separated list}"; SELECT_GIVEN=true; shift 2 ;;
    --skills=*) SELECT="${1#*=}"; SELECT_GIVEN=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
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

integrity_summary() {
  local skill_dir="$1"
  local issues miss=0 emp=0 line
  if check_integrity "$skill_dir" >/dev/null 2>&1; then
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

select_skills_root() {
  local -a roots=("$@")
  local root
  if [[ "$INVOKED_SKILLS_ROOT" == "$REPO_ROOT/"* ]]; then
    printf '%s' "$INVOKED_SKILLS_ROOT"
    return
  fi
  for pref in .agents/skills .cursor/skills; do
    for root in "${roots[@]}"; do
      [[ "$root" == "$REPO_ROOT/$pref" ]] && printf '%s' "$root" && return
    done
  done
  printf '%s' "${roots[0]}"
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

SKILLS_ROOT="$(select_skills_root "${LOCAL_INIT_ROOTS[@]}")"
MANIFEST="$SKILLS_ROOT/verasic-init/manifest.txt"

if [[ ! -f "$MANIFEST" ]]; then
  echo "init: manifest not found at $MANIFEST — broken install" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

names=()
statuses=()
summaries=()
detail_files=()
actions_lines=()
manifest_names=","
wired=0; verified=0; degraded=0; ready=0; action_needed=0
not_installed=0; not_selected=0; unknown=0; failed=0; broken_install=0
list_ok=0

while IFS='|' read -r name wire desc || [[ -n "$name" ]]; do
  name="${name//[[:space:]]/}"; wire="${wire//[[:space:]]/}"; desc="${desc%$'\r'}"
  [[ -z "$name" || "$name" == \#* ]] && continue
  manifest_names+="$name,"

  if ! is_selected "$name"; then
    names+=("$name"); statuses+=("not selected"); summaries+=("skipped by --skills")
    detail_files+=(""); actions_lines+=("")
    not_selected=$((not_selected + 1))
    continue
  fi

  if ! skill_dir="$(resolve_skill_dir "$name")"; then
    names+=("$name"); statuses+=("not installed"); summaries+=("$desc")
    detail_files+=(""); actions_lines+=("")
    not_installed=$((not_installed + 1))
    continue
  fi

  integrity_issues=""
  integrity_ok=true
  if ! integrity_issues="$(check_integrity "$skill_dir" 2>/dev/null)"; then
    integrity_ok=false
  fi

  if [[ "$wire" == "-" ]]; then
    if $integrity_ok; then
      names+=("$name"); statuses+=("ready"); summaries+=("no repo wiring needed")
      detail_files+=("")
      actions_lines+=("integrity: ok")
      ready=$((ready + 1))
    else
      names+=("$name"); statuses+=("broken install")
      summaries+=("required files missing — re-run the skills install")
      detail_files+=("$TMP/${name}.integrity")
      printf '%s\n' "$integrity_issues" >"$TMP/${name}.integrity"
      actions_lines+=("integrity: failed ($(integrity_summary "$skill_dir"))")
      broken_install=$((broken_install + 1))
    fi
    continue
  fi

  if $LIST_ONLY; then
    if $integrity_ok; then
      names+=("$name"); statuses+=("ok"); summaries+=("would run $wire")
      detail_files+=(""); actions_lines+=("integrity: ok")
      list_ok=$((list_ok + 1))
    else
      names+=("$name"); statuses+=("broken install")
      summaries+=("required files missing — would not wire")
      detail_files+=("$TMP/${name}.integrity")
      printf '%s\n' "$integrity_issues" >"$TMP/${name}.integrity"
      actions_lines+=("integrity: failed ($(integrity_summary "$skill_dir"))")
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
  detail_files+=("$out")

  post_integrity_ok=true
  post_issues=""
  if ! post_issues="$(check_integrity "$skill_dir" 2>/dev/null)"; then
    post_integrity_ok=false
  fi

  action_log=""
  if [[ -s "$out" ]]; then
    action_log="$(grep -E '^bootstrap: step:' "$out" 2>/dev/null || true)"
  fi
  [[ -z "$action_log" ]] && action_log="wire: ran $wire"

  case "$rc" in
    0)
      if [[ "$name" == verasic-github-env ]]; then
        IFS='|' read -r st sum <<< "$(parse_github_env_status "$(cat "$out")" "$rc" "$post_integrity_ok")"
        names+=("$name"); statuses+=("$st"); summaries+=("${sum:-$desc}")
        case "$st" in
          verified) verified=$((verified + 1)); actions_lines+=("$action_log; integrity: ok; verify: ok") ;;
          degraded) degraded=$((degraded + 1)); actions_lines+=("$action_log; integrity: $([[ $post_integrity_ok == true ]] && echo ok || echo incomplete); verify: skipped") ;;
          wired) wired=$((wired + 1)); actions_lines+=("$action_log; integrity: ok; verify: skipped (no token)") ;;
        esac
      elif $post_integrity_ok; then
        names+=("$name"); statuses+=("wired"); summaries+=("$desc")
        actions_lines+=("$action_log; integrity: ok")
        wired=$((wired + 1))
      else
        names+=("$name"); statuses+=("degraded"); summaries+=("wire ok but integrity incomplete")
        printf '%s\n' "$post_issues" >>"$out"
        actions_lines+=("$action_log; integrity: incomplete")
        degraded=$((degraded + 1))
      fi
      ;;
    3)
      names+=("$name"); statuses+=("action needed"); summaries+=("manual step required — see details")
      actions_lines+=("$action_log; integrity: ok")
      action_needed=$((action_needed + 1))
      ;;
    *)
      names+=("$name"); statuses+=("FAILED"); summaries+=("exit $rc — see details")
      actions_lines+=("wire: failed (exit $rc)")
      failed=$((failed + 1))
      ;;
  esac
done < "$MANIFEST"

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

RULE="────────────────────────────────────────────────────────────────"
origin="$(git remote get-url origin 2>/dev/null || echo '(no origin remote)')"
origin="$(printf '%s' "$origin" | sed -E 's#://[^/@]*@#://#')"

echo "$RULE"
if $LIST_ONLY; then
  echo " verasic-init · installed skills (no changes made)"
else
  echo " verasic-init · repository setup report"
fi
echo "$RULE"
printf ' %-18s %s\n' "repo root" "$REPO_ROOT"
printf ' %-18s %s\n' "origin" "$origin"
printf ' %-18s %s\n' "skills root" "$SKILLS_ROOT"
if $EXTERNAL_INVOKER; then
  printf ' %-18s %s\n' "warning" "init invoked from outside repo ($INVOKED_SKILLS_ROOT) — using repo-local skills only"
fi
echo

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
    while IFS='|' read -r rname rwire _ || [[ -n "$rname" ]]; do
      rname="${rname//[[:space:]]/}"
      [[ -z "$rname" || "$rname" == \#* ]] && continue
      if [[ -d "$root/$rname" ]]; then
        printf '      %-22s %s\n' "$rname" "$(integrity_summary "$root/$rname")"
      fi
    done < "$MANIFEST"
  done
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
  printf ' result: %d verified · %d wired · %d degraded · %d ready · %d action needed · %d broken install · %d not installed · %d not selected · %d unknown · %d failed\n' \
    "$verified" "$wired" "$degraded" "$ready" "$action_needed" "$broken_install" "$not_installed" "$not_selected" "$unknown" "$failed"
  if ((failed > 0 || broken_install > 0)); then
    echo " next: fix broken installs and failures above, then re-run init (idempotent — safe to repeat)"
  elif ((action_needed > 0)); then
    echo " next: complete the manual steps in the details above, then re-run init to confirm"
  elif ((unknown > 0)); then
    echo " next: fix the unknown skill name(s) above and re-run with corrected --skills"
  else
    echo " next: follow any 'Next steps' lines in details above; re-run init anytime (idempotent)"
  fi
fi
echo "$RULE"

((failed == 0 && broken_install == 0)) || exit 1
if ((unknown > 0 && verified + wired + degraded + ready + action_needed + list_ok == 0)); then
  exit 2
fi
exit 0
