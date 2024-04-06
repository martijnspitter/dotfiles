#!/usr/bin/env bash

selected=$(find ~/projects ~/klar ~/klar/klar-fe ~/klar-be ~/doccs -mindepth 1 -maxdepth 1 -type d | fzf)
selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)
echo $selected
if [[ $selected == *"klar-fe"* ]]; then
  tmux detach
  tmuxifier load-session klar-fe

elif [[ $selected == *"clicky"* ]]; then
  tmux detach
  tmuxifier load-session clicky

elif [[ $selected == *"workout"* ]]; then
  tmux detach
  tmuxifier load-session workout

elif [[ $selected == *"klar-be"* ]]; then
  tmux detach
  tmuxifier load-session klar-be

else
    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        tmux new-session -s $selected_name -c $selected -n 'git'
        exit 0
    fi

    if ! tmux has-session -t=$selected_name 2> /dev/null; then
        tmux new-session -ds $selected_name -c $selected -n 'git'
    fi

    tmux switch-client -t $selected_name:1
fi
