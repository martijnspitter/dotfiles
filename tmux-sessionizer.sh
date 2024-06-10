#!/usr/bin/env bash

tmux detach
selected=$(find ~/.config ~/ ~/projects ~/projects/go-learning ~/klar ~/klar/klar-fe -mindepth 1 -maxdepth 1 -type d | fzf)
selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)
echo $selected

if [[ $selected == *"new-shiny-theme-palette"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/klar-fe.yaml

elif [[ $selected == *"RBAC"* ]]; then 
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/klar-fe.yaml

elif [[ $selected == *"klar-fe"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/klar-fe.yaml

elif [[ $selected == *"clicky-fe"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/fe-run-dev.yaml

elif [[ $selected == *"clicky"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"workout"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/fe-run-dev.yaml

elif [[ $selected == *"klar-be"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"nvim"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"dotfiles"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"coding-challenges"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"obsidian"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

elif [[ $selected == *"go-learning"* ]]; then
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml

else
  SESSION_NAME=$selected_name QUERY=$selected tmuxp load -y ~/dotfiles/tmuxp/no_server.yaml
fi
