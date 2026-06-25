#!/usr/bin/env bash
# Claude Code status line — Catppuccin Mocha theme (mirrors Starship config)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Catppuccin Mocha palette (ANSI 24-bit)
surface0="\e[48;2;49;50;68m"    # bg: #313244
peach="\e[48;2;250;179;135m"    # bg: #fab387
green="\e[48;2;166;227;161m"    # bg: #a6e3a1
teal="\e[48;2;148;226;213m"     # bg: #94e2d5
purple="\e[48;2;203;166;247m"   # bg: #cba6f7

fg_text="\e[38;2;205;214;244m"  # #cdd6f4
fg_base="\e[38;2;30;30;46m"     # #1e1e2e (dark text on light bg)
fg_peach="\e[38;2;250;179;135m" # peach fg for arrows
fg_green="\e[38;2;166;227;161m"
fg_teal="\e[38;2;148;226;213m"
fg_purple="\e[38;2;203;166;247m"

reset="\e[0m"

# Truncate cwd to last 3 segments (mirrors starship truncation_length=3)
short_path=$(echo "$cwd" | awk -F'/' '{
  n=NF; if(n<=3){print $0} else {
    out=""; for(i=n-2;i<=n;i++){out=out"/"$i}; print ".../"substr(out,2)
  }
}')

# Git branch (skip optional lock)
git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Git status indicators
git_dirty=""
if [ -n "$git_branch" ]; then
  git_status_out=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  [ -n "$git_status_out" ] && git_dirty=" *"
fi

# fg colors matching each segment's bg (for rounded caps and arrows)
fg_surface0="\e[38;2;49;50;68m"   # surface0 as fg

# Build status line
# Left rounded cap (no bg, fg = surface0 color)
printf "${fg_surface0}${reset}"
printf "${surface0}${fg_text} $(whoami) ${reset}"
printf "${fg_peach}${peach}${reset}"
printf "${peach}${fg_base} ${short_path} ${reset}"

if [ -n "$git_branch" ]; then
  printf "${fg_green}${green}${reset}"
  printf "${green}${fg_base}  ${git_branch}${git_dirty} ${reset}"
  printf "${fg_teal}${teal}${reset}"
else
  printf "${fg_teal}${teal}${reset}"
fi

printf "${teal}${fg_base} ${model} ${reset}"

# Context segment in purple (only when usage data is available)
fg_black="\e[38;2;0;0;0m"
if [ -n "$used" ]; then
  used_int=${used%.*}
  printf "${fg_purple}${purple}${reset}"
  printf "${purple}${fg_black} ${used_int}%% ${reset}"
  printf "${fg_purple}${reset}"
else
  printf "${fg_teal}${reset}"
fi

printf "\n"
