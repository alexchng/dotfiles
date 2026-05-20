for file in "$HOME/.config/dotfiles/shell/env.sh" "$HOME/.config/dotfiles/shell/aliases.sh"; do
  [ -r "$file" ] && . "$file"
done

