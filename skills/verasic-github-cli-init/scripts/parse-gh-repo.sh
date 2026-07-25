#!/usr/bin/env bash
# shellcheck shell=bash

verasic_parse_gh_repo_from_remote() {
  local raw="${1%.git}"
  raw="${raw#ssh://}"
  raw="${raw#https://}"
  raw="${raw#http://}"
  raw="${raw#git@}"

  local owner repo
  if [[ "$raw" =~ ^github\.com:([^/]+)/([^/]+)$ ]]; then
    owner="${BASH_REMATCH[1]}"
    repo="${BASH_REMATCH[2]}"
  elif [[ "$raw" =~ ^(ssh\.)?github\.com(:[0-9]+)?/([^/]+)/([^/]+)$ ]]; then
    owner="${BASH_REMATCH[3]}"
    repo="${BASH_REMATCH[4]}"
  else
    return 1
  fi

  if [[ ! "$owner" =~ ^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$ ]]; then
    return 1
  fi
  if [[ ! "$repo" =~ ^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$ ]]; then
    return 1
  fi

  printf '%s/%s' "$owner" "$repo"
}
