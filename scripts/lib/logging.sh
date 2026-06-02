#!/usr/bin/env bash

LOG_ENABLED=true
LOG_FILE="${LOG_FILE:-}"
LOG_INITIALIZED=false

logging_usage_options() {
  cat <<'USAGE'
  --no-log          Do not write a log file
  --log-file PATH   Write the log to PATH
USAGE
}

init_logging() {
  local name="$1"
  local log_dir
  log_dir="${DOTFILES_DIR:-$HOME/.dotfiles}/logs"

  if ! "$LOG_ENABLED"; then
    return
  fi

  if [ -z "$LOG_FILE" ]; then
    LOG_FILE="$log_dir/$name-$(date +%Y%m%d-%H%M%S).log"
  fi

  mkdir -p "$(dirname "$LOG_FILE")"
  : > "$LOG_FILE"
  LOG_INITIALIZED=true
  log "log file: $LOG_FILE"
}

log() {
  local message="$*"
  local timestamp

  printf '%s\n' "$message"

  if "$LOG_ENABLED" && "$LOG_INITIALIZED"; then
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s %s\n' "$timestamp" "$message" >> "$LOG_FILE"
  fi
}

log_command() {
  local command_line
  printf -v command_line '%q ' "$@"
  log "${command_line% }"
}

