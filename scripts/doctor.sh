#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
source "$DOTFILES_DIR/scripts/lib/logging.sh"

status=0

usage() {
  cat <<USAGE
Usage: scripts/doctor.sh [options]

Checks command availability and dotfile links.

Options:
$(logging_usage_options)
  -h, --help       Show this help
USAGE
}

check_command() {
  local command_name="$1"
  local required="${2:-optional}"

  if command -v "$command_name" >/dev/null 2>&1; then
    log "ok   command $command_name"
  elif [ "$required" = "required" ]; then
    log "miss command $command_name (required)"
    status=1
  else
    log "skip command $command_name (not available)"
  fi
}

check_link() {
  local source="$1"
  local relative="${source#$DOTFILES_DIR/home/}"
  local target="$HOME_DIR/$relative"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    log "ok   link $target"
  elif [ "$relative" = ".zshrc" ] || [ "$relative" = ".bashrc" ]; then
    if [ -f "$target" ] &&
      (grep -Fq "# >>> dotfiles shell setup >>>" "$target" ||
        (grep -Fq "$HOME/.config/dotfiles/shell/env.sh" "$target" &&
          grep -Fq "$HOME/.config/dotfiles/shell/aliases.sh" "$target") ||
        (grep -Fq '$HOME/.config/dotfiles/shell/env.sh' "$target" &&
          grep -Fq '$HOME/.config/dotfiles/shell/aliases.sh' "$target")); then
      log "ok   hook $target"
    else
      log "warn exists but not linked $target"
    fi
  elif [ "$relative" = ".gitconfig" ]; then
    if [ -f "$target" ] &&
      (grep -Fq "# >>> dotfiles git setup >>>" "$target" ||
        grep -Fq "path = $source" "$target"); then
      log "ok   hook $target"
    else
      log "warn exists but not linked $target"
    fi
  elif [ "$relative" = ".tmux.conf" ]; then
    if [ -f "$target" ] && grep -Fq "# >>> dotfiles tmux setup >>>" "$target"; then
      log "ok   hook $target"
    else
      log "warn exists but not linked $target"
    fi
  elif [ -e "$target" ] || [ -L "$target" ]; then
    log "warn exists but not linked $target"
  else
    log "miss link $target"
    status=1
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-log)
      LOG_ENABLED=false
      ;;
    --log-file)
      if [ "$#" -lt 2 ]; then
        echo "--log-file requires a path" >&2
        exit 2
      fi
      LOG_FILE="$2"
      shift
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

init_logging "doctor"

check_command git required
check_command tmux
check_command rg
check_command mise
check_command claude

while IFS= read -r -d '' source; do
  check_link "$source"
done < <(find "$DOTFILES_DIR/home" -type f ! -name '.DS_Store' -print0)

exit "$status"
