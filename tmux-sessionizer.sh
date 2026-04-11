#!/usr/bin/env bash

selected=$(find ~/.config ~/ ~/projects ~/projects/go-learning ~/projects/coding-challenges ~/klar ~/klar/codesubmit ~/klar/klar-fe -mindepth 1 -maxdepth 1 -type d | fzf)
selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)
echo $selected

load_session() {
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -d -y "$1"
  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$selected_name"
  else
    tmux attach-session -t "$selected_name"
  fi
}

if [[ $selected == *"new-shiny-theme-palette"* ]]; then
  load_session ~/dotfiles/tmuxp/klar-fe.yaml

elif [[ $selected == *"learn-platform"* ]]; then
  load_session ~/dotfiles/tmuxp/ai.yaml

elif [[ $selected == *"claude-setup"* ]]; then
  load_session ~/dotfiles/tmuxp/ai.yaml

elif [[ $selected == *"claude"* ]]; then
  load_session ~/dotfiles/tmuxp/ai.yaml

elif [[ $selected == *"klar-fe"* ]]; then
  load_session ~/dotfiles/tmuxp/klar-fe.yaml

elif [[ $selected == *"clicky-fe"* ]]; then
  load_session ~/dotfiles/tmuxp/fe-run-dev.yaml

elif [[ $selected == *"clicky"* ]]; then
  load_session ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"workout"* ]]; then
  load_session ~/dotfiles/tmuxp/fe-run-dev.yaml

elif [[ $selected == *"klar-be"* ]]; then
  load_session ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"nvim"* ]]; then
  load_session ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"dotfiles"* ]]; then
  load_session ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"coding-challenges"* ]]; then
  load_session ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"obsidian"* ]]; then
  load_session ~/dotfiles/tmuxp/vault.yaml

elif [[ $selected == *"go-learning"* ]]; then
  load_session ~/dotfiles/tmuxp/go-dev.yaml

elif [[ $selected == *"tui-todo"* ]]; then
  load_session ~/dotfiles/tmuxp/go-dev.yaml

elif [[ $selected == *"kata"* ]]; then
  load_session ~/dotfiles/tmuxp/go-dev.yaml

else
  load_session ~/dotfiles/tmuxp/no_server.yaml
fi
