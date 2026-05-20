#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
status=0

check_command() {
  local command_name="$1"
  local required="${2:-optional}"

  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'ok   command %s\n' "$command_name"
  elif [ "$required" = "required" ]; then
    printf 'miss command %s (required)\n' "$command_name"
    status=1
  else
    printf 'skip command %s (not available)\n' "$command_name"
  fi
}

check_link() {
  local source="$1"
  local relative="${source#$DOTFILES_DIR/home/}"
  local target="$HOME_DIR/$relative"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    printf 'ok   link %s\n' "$target"
  elif [ -e "$target" ] || [ -L "$target" ]; then
    printf 'warn exists but not linked %s\n' "$target"
  else
    printf 'miss link %s\n' "$target"
    status=1
  fi
}

check_command git required
check_command tmux
check_command rg
check_command mise
check_command claude

while IFS= read -r -d '' source; do
  check_link "$source"
done < <(find "$DOTFILES_DIR/home" -type f -print0)

exit "$status"
