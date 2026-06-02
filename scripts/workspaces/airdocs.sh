#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_URL="git@sgts.gitlab-dedicated.com:innersource/sgts/runtime/airbase/apps/airdocs.git"
REPO_DIR="${AIRDOCS_DIR:-${WORKSPACE_HOME:-$HOME/workspaces}/airdocs}"
GIT_NAME="${AIRDOCS_GIT_NAME:-Alex Chng}"
GIT_EMAIL="${AIRDOCS_GIT_EMAIL:-alex_chng@tech.gov.sg}"
CLAUDE_MODEL="${AIRDOCS_CLAUDE_MODEL:-claude-sonnet-4-6}"

DRY_RUN=false
RUN_DOTFILES=true
FORCE_DOTFILES=false
RUN_MISE=true
RUN_CLAUDE=true

usage() {
  cat <<'USAGE'
Usage: scripts/workspaces/airdocs.sh [options]

Bootstraps the SGTS Airdocs workspace.

Options:
  --dir PATH         Clone or use the repo at PATH
  --model MODEL      Claude model to launch
  --dry-run          Show actions without changing files
  --force-dotfiles   Back up and replace existing ~/.tmux.conf only
  --skip-dotfiles    Do not run scripts/bootstrap.sh
  --skip-mise        Do not run mise trust
  --skip-claude      Do not launch Claude Code
  -h, --help         Show this help
USAGE
}

log() {
  printf '%s\n' "$*"
}

run() {
  if "$DRY_RUN"; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run_in_repo() {
  if "$DRY_RUN"; then
    printf 'dry-run: cd %q &&' "$REPO_DIR"
    printf ' %q' "$@"
    printf '\n'
  else
    (cd "$REPO_DIR" && "$@")
  fi
}

reload_tmux() {
  if "$DRY_RUN"; then
    run tmux source-file "$HOME/.tmux.conf"
    return
  fi

  if ! command -v tmux >/dev/null 2>&1; then
    log "skip tmux reload (tmux is not installed)"
    return
  fi

  if [ ! -r "$HOME/.tmux.conf" ]; then
    log "skip tmux reload ($HOME/.tmux.conf is not readable)"
    return
  fi

  if [ -n "${TMUX:-}" ] || tmux list-sessions >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf" || log "tmux reload skipped; no active tmux server accepted the config"
  else
    log "tmux config is ready; no running tmux server to reload"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)
      if [ "$#" -lt 2 ]; then
        echo "--dir requires a path" >&2
        exit 2
      fi
      REPO_DIR="$2"
      shift
      ;;
    --model)
      if [ "$#" -lt 2 ]; then
        echo "--model requires a model name" >&2
        exit 2
      fi
      CLAUDE_MODEL="$2"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --force-dotfiles)
      FORCE_DOTFILES=true
      ;;
    --skip-dotfiles)
      RUN_DOTFILES=false
      ;;
    --skip-mise)
      RUN_MISE=false
      ;;
    --skip-claude)
      RUN_CLAUDE=false
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if "$RUN_DOTFILES"; then
  bootstrap_args=()
  if "$DRY_RUN"; then
    bootstrap_args+=(--dry-run)
  fi
  if "$FORCE_DOTFILES"; then
    bootstrap_args+=(--force)
  fi
  "$DOTFILES_DIR/scripts/bootstrap.sh" "${bootstrap_args[@]}"
fi

reload_tmux

if ! "$DRY_RUN" && ! command -v git >/dev/null 2>&1; then
  echo "git is required to bootstrap Airdocs." >&2
  exit 1
fi

if [ -d "$REPO_DIR/.git" ]; then
  log "using existing repo at $REPO_DIR"
elif [ -e "$REPO_DIR" ]; then
  echo "$REPO_DIR exists but is not a Git repository." >&2
  exit 1
else
  run mkdir -p "$(dirname "$REPO_DIR")"
  run git clone "$REPO_URL" "$REPO_DIR"
fi

run git -C "$REPO_DIR" config user.name "$GIT_NAME"
run git -C "$REPO_DIR" config user.email "$GIT_EMAIL"

if "$RUN_MISE"; then
  if "$DRY_RUN" || command -v mise >/dev/null 2>&1; then
    run_in_repo mise trust
  else
    log "skip mise trust (mise is not available in this workspace)"
  fi
fi

if "$RUN_CLAUDE"; then
  if "$DRY_RUN" || command -v claude >/dev/null 2>&1; then
    run_in_repo claude --model "$CLAUDE_MODEL"
  else
    log "skip Claude Code launch (claude is not available in this workspace)"
  fi
fi
