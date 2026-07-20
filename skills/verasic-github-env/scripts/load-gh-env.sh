#!/usr/bin/env bash
# shellcheck shell=bash
# Source-only GH var loader — side-effect free except exporting GH_TOKEN/GH_REPO.
# Does not change shell options or cwd; its `_verasic_*` helpers are unset on exit
# (a caller's own `_verasic_*` names would be clobbered — treat the prefix as reserved).
# Safe when the caller has set -euo pipefail active.
#   source .cursor/skills/verasic-github-env/scripts/load-gh-env.sh

_verasic_extract_var() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 1

  local line value
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" == "${key}="* ]] || continue
    value="${line#*=}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [[ "$value" =~ ^\"(.*)\"$ ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
      value="${BASH_REMATCH[1]}"
    fi
    printf '%s' "$value"
    return 0
  done < "$file"
  return 1
}

_verasic_load_key() {
  local key="$1"
  local current="${!key-}"
  [[ -n "$current" ]] && return 0

  local value=""
  value="$(_verasic_extract_var "$_verasic_agent_file" "$key" 2>/dev/null || true)"
  if [[ -z "$value" ]]; then
    value="$(_verasic_extract_var "$_verasic_env_file" "$key" 2>/dev/null || true)"
  fi
  [[ -n "$value" ]] || return 1
  printf -v "$key" '%s' "$value"
  export "$key"
}

_verasic_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
_verasic_agent_file="$_verasic_root/.github-agent.local"
_verasic_env_file="$_verasic_root/.env.local"

_verasic_load_key GH_TOKEN || true
_verasic_load_key GH_REPO || true

unset -f _verasic_extract_var _verasic_load_key
unset _verasic_root _verasic_agent_file _verasic_env_file
