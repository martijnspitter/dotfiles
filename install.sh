#!/usr/bin/env bash
# Symlink dotfiles into their expected locations.
# Idempotent: re-running is safe. Existing real files/dirs are backed up to *.backup.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

link() {
  local src="$1" dest="$2"

  if [ ! -e "$src" ]; then
    echo "skip  (missing source): $src"
    return
  fi

  # Already the correct symlink? Nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    echo "ok    $dest -> $src"
    return
  fi

  mkdir -p "$(dirname "$dest")"

  # Back up anything real (or a stale symlink) that's in the way.
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$dest.backup"
    echo "backup $dest -> $backup"
    rm -rf "$backup"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "link  $dest -> $src"
}

link "$DOTFILES/.zshrc"          "$HOME/.zshrc"
link "$DOTFILES/alacritty.toml"  "$CONFIG/alacritty/alacritty.toml"
link "$DOTFILES/skhdrc"          "$CONFIG/skhd/skhdrc"
link "$DOTFILES/yabairc"         "$CONFIG/yabai/yabairc"
link "$DOTFILES/starship.toml"   "$CONFIG/starship.toml"
link "$DOTFILES/television"      "$CONFIG/television"
link "$DOTFILES/zed"             "$CONFIG/zed"
link "$DOTFILES/nvim"            "$CONFIG/nvim"
link "$DOTFILES/.aerospace.toml" "$HOME/.aerospace.toml"
link "$DOTFILES/.tmux.conf"      "$HOME/.tmux.conf"
link "$DOTFILES/.claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$DOTFILES/herdr/config.toml" "$CONFIG/herdr/config.toml"

# Not symlinked (used in place from the repo):
#   tmuxp/                -> via $TMUXP_CONFIGDIR in .zshrc
#   tmux-sessionizer.sh   -> referenced by ~/dotfiles path in .zshrc
#   herdr-spreader/       -> templates read by herdr-sessionizer.sh
#   herdr-sessionizer.sh  -> invoked by ctrl+g keybinding in herdr/config.toml
#                            and by zsh bindkey ^g in .zshrc

echo "Done."
