#!/usr/bin/env bash
set -euo pipefail

ZERO_SHA='0000000000000000000000000000000000000000'
BASE_REF="${GSD_PUBLISH_BASE_REF:-upstream/next}"
violations=()

is_local_only_path() {
  case "$1" in
    .agents|.agents/*|.planning|.planning/*|mise.toml|scratch|scratch/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

if ! git rev-parse --verify --quiet "refs/remotes/${BASE_REF#refs/remotes/}" >/dev/null; then
  echo "Push blocked: required publish base '$BASE_REF' is not available locally." >&2
  echo "Fetch it before pushing: git fetch upstream next" >&2
  exit 1
fi

check_sha() {
  local target_sha="$1"
  [ -z "$target_sha" ] && return 0
  [ "$target_sha" = "$ZERO_SHA" ] && return 0

  while IFS= read -r path; do
    [ -z "$path" ] && continue
    if is_local_only_path "$path"; then
      violations+=("$path")
    fi
  done < <(git diff --name-only --diff-filter=ACMRT "$BASE_REF...$target_sha")
}

if [ "$#" -gt 0 ]; then
  # Mode 1: Explicit target ref(s) passed as arguments
  for ref in "$@"; do
    target_sha="$(git rev-parse --verify "$ref")"
    check_sha "$target_sha"
  done
elif [ ! -t 0 ] && read -t 0; then
  # Mode 2: Git pre-push hook or piped input with available data
  while read -r _local_ref local_sha _remote_ref _remote_sha; do
    check_sha "${local_sha:-}"
  done
else
  # Mode 3: Standalone invocation (TTY or open pipe with no pending input) -> default to HEAD
  target_sha="$(git rev-parse --verify HEAD)"
  check_sha "$target_sha"
fi

if [ "${#violations[@]}" -gt 0 ]; then
  {
    echo "Push blocked: the contribution diff contains personal-only paths."
    echo "Base: $BASE_REF"
    printf '  - %s\n' "${violations[@]}" | sort -u
    echo "Keep these files local and commit only the intended upstream change."
  } >&2
  exit 1
fi
