#!/usr/bin/env bash
set -euo pipefail

# Validate etc/cursor/agents/*.md — frontmatter, name/filename parity, model catalog membership.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ETC_AGENTS="${ETC_CURSOR_AGENTS_DIR:-$REPO_ROOT/etc/cursor/agents}"
SNAPSHOT="${ETC_SUBAGENTS_SNAPSHOT:-$REPO_ROOT/references/snapshots/cursor-custom-subagents-2026-07-25.md}"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

catalog_slugs() {
  awk '/^## Full catalog \(/,0' "$SNAPSHOT" |
    grep -E '^\| `[A-Za-z0-9]' |
    sed -n 's/^| `\([^`]*\)`.*/\1/p' |
    sort -u
}

# Roster table is the documented source of truth for which agents must exist.
roster_rows() {
  awk '/^## Author selection roster/,/^## Task inline/' "$SNAPSHOT" |
    sed -n 's/^| `\([^`]*\)`[[:space:]]*| `\([^`]*\)`.*/\1 \2/p' |
    grep '^subagent-' || true
}

declare -A CATALOG=()
while IFS= read -r slug; do
  [[ -n "$slug" ]] && CATALOG["$slug"]=1
done < <(catalog_slugs)

declare -A ROSTER=()
while read -r rname rmodel; do
  [[ -n "$rname" ]] && ROSTER["$rname"]="$rmodel"
done < <(roster_rows)

echo "== check-etc-subagents =="
echo "agents: $ETC_AGENTS"
echo "snapshot: $SNAPSHOT"
echo

[[ -d "$ETC_AGENTS" ]] && ok 'etc/cursor/agents/ exists' || bad 'etc/cursor/agents/ exists'
[[ -f "$SNAPSHOT" ]] && ok 'snapshot catalog exists' || bad 'snapshot catalog exists'

if ((${#CATALOG[@]} == 0)); then
  bad 'snapshot catalog yielded zero slugs'
else
  ok "snapshot catalog lists ${#CATALOG[@]} slugs"
fi

shopt -s nullglob
agent_files=("$ETC_AGENTS"/*.md)
shopt -u nullglob

if ((${#agent_files[@]} == 0)); then
  bad 'no subagent-*.md files under etc/cursor/agents/'
else
  ok "found ${#agent_files[@]} agent file(s)"
fi

if ((${#ROSTER[@]} == 0)); then
  bad 'snapshot roster table yielded zero entries'
else
  ok "snapshot roster lists ${#ROSTER[@]} agent(s)"
fi

for rname in "${!ROSTER[@]}"; do
  if [[ -f "$ETC_AGENTS/$rname.md" ]]; then
    ok "roster entry $rname has a file"
  else
    bad "roster entry $rname has no etc/cursor/agents/$rname.md"
  fi
done

for f in "${agent_files[@]}"; do
  base="$(basename "$f" .md)"
  rel="${f#"$REPO_ROOT/"}"
  [[ "$rel" == "$f" ]] && rel="$f"

  if ! head -n1 "$f" | grep -q '^---$'; then
    bad "$rel missing opening frontmatter ---"
    continue
  fi

  fm_end="$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$f")"
  if [[ -z "$fm_end" ]]; then
    bad "$rel missing closing frontmatter ---"
    continue
  fi
  ok "$rel frontmatter block present"

  name="$(sed -n '2,'"$((fm_end - 1))"'p' "$f" | awk -F': ' '/^name: / { print $2; exit }' | tr -d '\r')"
  model="$(sed -n '2,'"$((fm_end - 1))"'p' "$f" | awk -F': ' '/^model: / { print $2; exit }' | tr -d '\r')"

  if [[ -z "$name" ]]; then
    bad "$rel missing name: in frontmatter"
  elif [[ "$name" == "$base" ]]; then
    ok "$rel name: matches basename ($name)"
  else
    bad "$rel name: '$name' != basename '$base'"
  fi

  if [[ -z "$model" ]]; then
    bad "$rel missing model: in frontmatter"
  elif [[ "$model" == inherit ]]; then
    ok "$rel model: inherit"
  elif [[ -n "${CATALOG[$model]+x}" ]]; then
    ok "$rel model: $model (in catalog)"
  else
    bad "$rel model: '$model' not in snapshot catalog"
  fi

  if [[ -z "${ROSTER[$base]+x}" ]]; then
    bad "$rel has no row in the snapshot roster table"
  elif [[ -n "$model" && "${ROSTER[$base]}" != "$model" ]]; then
    bad "$rel model: '$model' disagrees with roster '${ROSTER[$base]}'"
  else
    ok "$rel matches its roster row"
  fi
done

echo "---"
echo "check-etc-subagents: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
