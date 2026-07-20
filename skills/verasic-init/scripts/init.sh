#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_ROOT="$(cd "$SKILL_ROOT/.." && pwd)"
MANIFEST="$SKILL_ROOT/manifest.txt"

usage() {
  cat <<'EOF'
verasic-init — wire installed Verasic skills into this repository

Usage:
  init.sh                  wire every installed verasic skill
  init.sh --skills a,b     wire only the listed skills (cherry-pick)
  init.sh --list           show manifest + installed state, change nothing
  init.sh --help           this help

Idempotent: safe to re-run anytime. Run from anywhere inside the repo.
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

# normalize: skill names never contain whitespace, so strip it all
# ("--skills ' a, b '" and "--skills a,b" mean the same thing)
SELECT="${SELECT//[[:space:]]/}"
if $SELECT_GIVEN && [[ -z "$SELECT" ]]; then
  echo "init: --skills needs a comma-separated list (got empty)" >&2
  exit 2
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "init: manifest not found at $MANIFEST — broken install" >&2
  exit 1
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

names=()
statuses=()
summaries=()
detail_files=()
manifest_names=","
wired=0; ready=0; action_needed=0; not_installed=0; not_selected=0; failed=0
installed=0; unknown=0

# "|| [[ -n ... ]]" keeps the last manifest line even without a trailing newline
while IFS='|' read -r name wire desc || [[ -n "$name" ]]; do
  name="${name//[[:space:]]/}"; wire="${wire//[[:space:]]/}"; desc="${desc%$'\r'}"
  [[ -z "$name" || "$name" == \#* ]] && continue
  manifest_names+="$name,"
  skill_dir="$SKILLS_ROOT/$name"

  if ! is_selected "$name"; then
    names+=("$name"); statuses+=("not selected"); summaries+=("skipped by --skills"); detail_files+=("")
    not_selected=$((not_selected + 1))
    continue
  fi

  if [[ ! -d "$skill_dir" ]]; then
    names+=("$name"); statuses+=("not installed"); summaries+=("$desc"); detail_files+=("")
    not_installed=$((not_installed + 1))
    continue
  fi

  if [[ "$wire" == "-" ]]; then
    names+=("$name"); statuses+=("ready"); summaries+=("no repo wiring needed"); detail_files+=("")
    ready=$((ready + 1))
    continue
  fi

  if $LIST_ONLY; then
    names+=("$name"); statuses+=("installed"); summaries+=("would run $wire"); detail_files+=("")
    installed=$((installed + 1))
    continue
  fi

  if [[ ! -f "$skill_dir/$wire" ]]; then
    names+=("$name"); statuses+=("FAILED"); summaries+=("wire script $wire missing — broken install, re-run the skills install"); detail_files+=("")
    failed=$((failed + 1))
    continue
  fi

  out="$TMP/$name.out"
  rc=0
  bash "$skill_dir/$wire" >"$out" 2>&1 || rc=$?
  detail_files+=("$out")
  case "$rc" in
    0) names+=("$name"); statuses+=("wired"); summaries+=("$desc"); wired=$((wired + 1)) ;;
    3) names+=("$name"); statuses+=("action needed"); summaries+=("manual step required — see details"); action_needed=$((action_needed + 1)) ;;
    *) names+=("$name"); statuses+=("FAILED"); summaries+=("exit $rc — see details"); failed=$((failed + 1)) ;;
  esac
done < "$MANIFEST"

if [[ -n "$SELECT" ]]; then
  IFS=',' read -ra requested <<< "$SELECT"
  for req in "${requested[@]}"; do
    [[ -z "$req" ]] && continue
    if [[ "$manifest_names" != *",$req,"* ]]; then
      names+=("$req"); statuses+=("unknown"); summaries+=("not in manifest — check spelling"); detail_files+=("")
      unknown=$((unknown + 1))
    fi
  done
fi

RULE="────────────────────────────────────────────────────────────────"
origin="$(git remote get-url origin 2>/dev/null || echo '(no origin remote)')"
# never print credentials embedded in the remote URL (https://user:token@host/...)
origin="$(printf '%s' "$origin" | sed -E 's#://[^/@]*@#://#')"

echo "$RULE"
if $LIST_ONLY; then
  echo " verasic-init · installed skills (no changes made)"
else
  echo " verasic-init · repository setup report"
fi
echo "$RULE"
printf ' %-10s %s\n' "repo root" "$REPO_ROOT"
printf ' %-10s %s\n' "origin" "$origin"
printf ' %-10s %s\n' "skills at" "$SKILLS_ROOT"
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

echo
if $LIST_ONLY; then
  printf ' result: %d installed · %d ready · %d not installed · %d not selected · %d unknown\n' \
    "$installed" "$ready" "$not_installed" "$not_selected" "$unknown"
else
  printf ' result: %d wired · %d ready · %d action needed · %d not installed · %d not selected · %d unknown · %d failed\n' \
    "$wired" "$ready" "$action_needed" "$not_installed" "$not_selected" "$unknown" "$failed"
  if ((failed > 0)); then
    echo " next: fix the failures above and re-run init (idempotent — safe to repeat)"
  elif ((action_needed > 0)); then
    echo " next: complete the manual steps in the details above, then re-run init to confirm"
  elif ((unknown > 0)); then
    echo " next: fix the unknown skill name(s) above and re-run with corrected --skills"
  else
    echo " next: follow any 'Next steps' lines in details above; re-run init anytime (idempotent)"
  fi
fi
echo "$RULE"

((failed == 0)) || exit 1
# a --skills selection that matched nothing real is an input error, not success
if ((unknown > 0 && wired + ready + action_needed + installed == 0)); then
  exit 2
fi
exit 0
