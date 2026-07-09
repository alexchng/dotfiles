#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
source "$DOTFILES_DIR/scripts/lib/logging.sh"

DRY_RUN=false
FORCE=false
CONFIGURE_CLAUDE_SETTINGS=true
CONFIGURE_CLAUDE_MD=true
BACKUP_DIR="$HOME_DIR/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'USAGE'
Usage: scripts/bootstrap.sh [options]

Links files from ./home into $HOME.

Options:
  --dry-run                Show actions without changing files
  --force                  Back up and replace existing ~/.tmux.conf only
  --skip-claude-settings   Do not merge Claude Code model preferences
  --skip-claude-md         Do not install global CLAUDE.md
  --no-log                 Do not write a log file
  --log-file PATH          Write the log to PATH
  -h, --help               Show this help
USAGE
}

run() {
  if "$DRY_RUN"; then
    log_command dry-run: "$@"
  else
    "$@"
  fi
}

shell_hook_block() {
  cat <<'HOOK'

# >>> dotfiles shell setup >>>
for file in "$HOME/.config/dotfiles/shell/env.sh" "$HOME/.config/dotfiles/shell/aliases.sh"; do
  [ -r "$file" ] && . "$file"
done
# <<< dotfiles shell setup <<<
HOOK
}

shell_hook_present() {
  local target="$1"
  local begin_marker="# >>> dotfiles shell setup >>>"

  grep -Fq "$begin_marker" "$target" ||
    (grep -Fq "$HOME/.config/dotfiles/shell/env.sh" "$target" &&
      grep -Fq "$HOME/.config/dotfiles/shell/aliases.sh" "$target") ||
    (grep -Fq '$HOME/.config/dotfiles/shell/env.sh' "$target" &&
      grep -Fq '$HOME/.config/dotfiles/shell/aliases.sh' "$target")
}

append_shell_hook() {
  local target="$1"

  if [ ! -e "$target" ]; then
    return
  fi

  if [ -L "$target" ]; then
    log "skip shell hook $target (symlink)"
    return
  fi

  if shell_hook_present "$target"; then
    log "shell hook already present in $target; skip append"
    return
  fi

  if "$DRY_RUN"; then
    log "dry-run: append dotfiles shell hook to $target"
  else
    shell_hook_block >> "$target"
  fi
  log "append dotfiles shell hook to $target"
}

git_hook_block() {
  local source="$DOTFILES_DIR/home/.gitconfig"

  cat <<HOOK

# >>> dotfiles git setup >>>
[include]
	path = $source
# <<< dotfiles git setup <<<
HOOK
}

git_hook_present() {
  local target="$1"
  local begin_marker="# >>> dotfiles git setup >>>"
  local source="$DOTFILES_DIR/home/.gitconfig"

  grep -Fq "$begin_marker" "$target" || grep -Fq "path = $source" "$target"
}

append_git_hook() {
  local target="$HOME_DIR/.gitconfig"

  if [ ! -e "$target" ]; then
    return
  fi

  if [ -L "$target" ]; then
    log "skip git hook $target (symlink)"
    return
  fi

  if git_hook_present "$target"; then
    log "git hook already present in $target; skip append"
    return
  fi

  if "$DRY_RUN"; then
    log "dry-run: append dotfiles git hook to $target"
  else
    git_hook_block >> "$target"
  fi
  log "append dotfiles git hook to $target"
}

append_tmux_hook() {
  local target="$HOME_DIR/.tmux.conf"
  local source="$DOTFILES_DIR/home/.tmux.conf"
  local begin_marker="# >>> dotfiles tmux setup >>>"

  if [ -L "$target" ]; then
    log "skip tmux hook $target (symlink)"
    return
  fi

  if [ ! -e "$target" ]; then
    return
  fi

  if grep -Fq "$begin_marker" "$target"; then
    log "tmux hook already present in $target"
    return
  fi

  if "$DRY_RUN"; then
    log "dry-run: append dotfiles tmux hook to $target"
  else
    {
      printf '\n%s\n' "$begin_marker"
      printf 'source-file "%s"\n' "$source"
      printf '%s\n' "# <<< dotfiles tmux setup <<<"
    } >> "$target"
  fi
  log "append dotfiles tmux hook to $target"
}

configure_claude_settings() {
  local script="$DOTFILES_DIR/scripts/configure-claude-settings.py"
  local args=()
  local output
  local status

  if [ ! -x "$script" ]; then
    log "skip Claude settings merge ($script is not executable)"
    return
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    log "skip Claude settings merge (python3 is not available)"
    return
  fi

  if "$DRY_RUN"; then
    args+=(--dry-run)
  fi

  if output="$("$script" "${args[@]}" 2>&1)"; then
    status=0
  else
    status=$?
  fi

  if [ -n "$output" ]; then
    while IFS= read -r line; do
      log "$line"
    done <<< "$output"
  fi

  return "$status"
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
    if "$FORCE" && [ "$relative" = ".tmux.conf" ]; then
      backup_target "$target"
    else
      if [ "$relative" = ".tmux.conf" ]; then
        log "skip $target (exists; use --force to replace tmux config)"
      else
        log "skip $target (exists; leaving in place)"
      fi
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
    --skip-claude-settings)
      CONFIGURE_CLAUDE_SETTINGS=false
      ;;
    --skip-claude-md)
      CONFIGURE_CLAUDE_MD=false
      ;;
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

init_logging "bootstrap"

if [ ! -d "$DOTFILES_DIR/home" ]; then
  log "No home/ directory found; nothing to link."
  exit 0
fi

while IFS= read -r -d '' source; do
  local_relative="${source#$DOTFILES_DIR/home/}"
  if ! "$CONFIGURE_CLAUDE_MD" && [ "$local_relative" = ".claude/CLAUDE.md" ]; then
    log "skip CLAUDE.md (--skip-claude-md)"
    continue
  fi
  link_file "$source"
done < <(find "$DOTFILES_DIR/home" -type f ! -name '.DS_Store' -print0)

append_shell_hook "$HOME_DIR/.zshrc"
append_shell_hook "$HOME_DIR/.bashrc"
append_git_hook
append_tmux_hook

if "$CONFIGURE_CLAUDE_SETTINGS"; then
  configure_claude_settings
fi

log "Done. Run scripts/doctor.sh to check the setup."
