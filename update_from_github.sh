#!/usr/bin/env bash
set -euo pipefail

# Script to reset this directory to match the upstream GitHub repository.
# Usage: ./update_from_github.sh [options] [branch]
# Options:
#   -b, --branch <name>   Branch to sync (defaults to env DEFAULT_BRANCH or 'main').
#   -h, --help            Show this help message.
#   --force               Skip safety prompt when running outside a git repo.

REPO_URL="https://github.com/srijan816/debatefeedback.git"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
FORCE_MODE="false"
TARGET_BRANCH=""
SCRIPT_NAME="update_from_github.sh"

usage() {
  cat <<USAGE
Reset this copy of DebateFeedback to match the GitHub repository.

Usage: ${SCRIPT_NAME} [options] [branch]

Options:
  -b, --branch <name>   Branch to sync (defaults to '${DEFAULT_BRANCH}')
  -h, --help            Show this help message and exit
  --force               Skip confirmation when directory is not a git clone

You may also pass the branch name as a positional argument (e.g. './${SCRIPT_NAME} main').
USAGE
}

log() {
  printf '==> %s\n' "$*"
}

fail() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "required command '$1' not found in PATH"
  fi
}

resolve_script_dir() {
  local source="${BASH_SOURCE[0]}"
  while [[ -h "$source" ]]; do
    local dir
    dir="$(cd -P "$(dirname "$source")" && pwd)"
    source="$(readlink "$source")"
    [[ $source != /* ]] && source="$dir/$source"
  done
  cd -P "$(dirname "$source")" && pwd
}

parse_args() {
  local positional=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -b|--branch)
        [[ $# -lt 2 ]] && fail "missing value for $1"
        TARGET_BRANCH="$2"
        shift 2
        ;;
      --force)
        FORCE_MODE="true"
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        positional+=("$@")
        break
        ;;
      -* )
        fail "unknown option: $1"
        ;;
      * )
        positional+=("$1")
        shift
        ;;
    esac
  done

  if [[ ${#positional[@]} -gt 1 ]]; then
    fail "too many positional arguments"
  fi

  if [[ -z "$TARGET_BRANCH" ]]; then
    TARGET_BRANCH="${positional[0]:-$DEFAULT_BRANCH}"
  elif [[ ${#positional[@]} -eq 1 ]]; then
    fail "branch already specified via option"
  fi
}

is_git_repo() {
  [[ -d "$WORK_DIR/.git" ]]
}

confirm_proceed() {
  if [[ "$FORCE_MODE" == "true" ]]; then
    return 0
  fi
  read -r -p "Directory is not a git repository. Proceed and replace its contents? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

checkout_branch() {
  if git -C "$WORK_DIR" rev-parse --verify --quiet "$TARGET_BRANCH" >/dev/null; then
    git -C "$WORK_DIR" checkout -f "$TARGET_BRANCH"
  else
    git -C "$WORK_DIR" checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
  fi
}

sync_with_git() {
  log "Fetching latest changes from $REPO_URL"
  git -C "$WORK_DIR" fetch --prune --tags origin

  if ! git -C "$WORK_DIR" rev-parse --verify --quiet "origin/$TARGET_BRANCH" >/dev/null; then
    fail "branch 'origin/$TARGET_BRANCH' not found on remote"
  fi

  log "Checking out branch '$TARGET_BRANCH'"
  checkout_branch

  log "Resetting local state to origin/$TARGET_BRANCH"
  git -C "$WORK_DIR" reset --hard "origin/$TARGET_BRANCH"

  log "Removing untracked files (excluding ${SCRIPT_NAME})"
  git -C "$WORK_DIR" clean -fdx -e "$SCRIPT_NAME"
}

sync_with_fresh_clone() {
  require rsync
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  cleanup() { [[ -d "$tmp_dir" ]] && rm -rf "$tmp_dir"; }
  trap cleanup EXIT

  log "Cloning $REPO_URL ($TARGET_BRANCH)"
  git clone --depth 1 --branch "$TARGET_BRANCH" "$REPO_URL" "$tmp_dir"

  local remote_script=""
  if [[ -f "$tmp_dir/$SCRIPT_NAME" ]]; then
    remote_script="$tmp_dir/$SCRIPT_NAME"
  fi

  log "Mirroring repo contents into $WORK_DIR"
  rsync -a --delete --exclude "$SCRIPT_NAME" "$tmp_dir"/ "$WORK_DIR"/

  if [[ -n "$remote_script" ]]; then
    cp "$remote_script" "$WORK_DIR/$SCRIPT_NAME"
  fi

  trap - EXIT
  cleanup
}

main() {
  SCRIPT_DIR="$(resolve_script_dir)"
  SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
  WORK_DIR="$SCRIPT_DIR"

  parse_args "$@"

  log "Preparing to sync branch '$TARGET_BRANCH' from $REPO_URL"

  require git

  if is_git_repo; then
    sync_with_git
  else
    log "No .git directory detected in $WORK_DIR"
    if ! confirm_proceed; then
      log "Aborting at user request"
      exit 1
    fi
    sync_with_fresh_clone
  fi

  log "Done. Workspace now mirrors $REPO_URL@$TARGET_BRANCH"
}

main "$@"
