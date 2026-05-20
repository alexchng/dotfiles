path_prepend() {
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

[ -d "$HOME/.local/bin" ] && path_prepend "$HOME/.local/bin"
[ -d "$HOME/bin" ] && path_prepend "$HOME/bin"

export PATH
export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"

if command -v mise >/dev/null 2>&1; then
  case "${SHELL##*/}" in
    bash)
      eval "$(mise activate bash)"
      ;;
    zsh)
      eval "$(mise activate zsh)"
      ;;
  esac
fi
