#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
DRY_RUN=false
FORCE=false
BACKUP_DIR="$HOME_DIR/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'USAGE'
Usage: scripts/bootstrap.sh [options]

Links files from ./home into $HOME.

Options:
  --dry-run   Show actions without changing files
  --force     Back up and replace existing files
  -h, --help  Show this help
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

backup_target() {
  local target="$1"
  local relative="${target#$HOME_DIR/}"
  local backup="$BACKUP_DIR/$relative"

  run mkdir -p "$(dirname "$backup")"
  run mv "$target" "$backup"
  log "backed up $target -> $backup"
}

link_file() {
  local source="$1"
  local relative="${source#$DOTFILES_DIR/home/}"
  local target="$HOME_DIR/$relative"
  local target_parent
  target_parent="$(dirname "$target")"

  run mkdir -p "$target_parent"

  if [ -L "$target" ]; then
    local current
    current="$(readlink "$target")"
    if [ "$current" = "$source" ]; then
      log "linked $target"
      return
    fi
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    if "$FORCE"; then
      backup_target "$target"
    else
      log "skip $target (exists; use --force to replace)"
      return
    fi
  fi

  run ln -s "$source" "$target"
  log "link $target -> $source"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --force)
      FORCE=true
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

if [ ! -d "$DOTFILES_DIR/home" ]; then
  log "No home/ directory found; nothing to link."
  exit 0
fi

while IFS= read -r -d '' source; do
  link_file "$source"
done < <(find "$DOTFILES_DIR/home" -type f -print0)

log "Done. Run scripts/doctor.sh to check the setup."
