#!/usr/bin/env bash
# tuios equivalent of herdr-sessionizer.sh / tmux-sessionizer.sh.
#
# Pick a project directory with fzf (or pass it as $1). If a tuios session
# with that name exists, switch to it. Otherwise create it detached in that
# directory, build the layout from tuios/layouts/<name>.sh, then switch to it.
#
# Works two ways:
#   1. Inside a tuios pane or popup (TUIOS_ENV=1), e.g. from the prefix+ctrl+f
#      keybinding in tuios/config.toml: switches the client in place.
#   2. From a plain shell: `exec tuios attach` (starts the daemon if needed).
#
# Usage: tuios-sessionizer.sh [--no-attach] [DIR]

# Intentionally NOT using `set -e`: log visibly and keep going.
set -u
set -o pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
LAYOUT_DIR="$DOTFILES/tuios/layouts"

log()  { printf 'sessionizer: %s\n' "$*" >&2; }
die()  { log "ERROR: $*"; exit 1; }
warn() { log "WARN: $*"; }

attach=1
if [ "${1:-}" = "--no-attach" ]; then attach=0; shift; fi

command -v tuios >/dev/null 2>&1 || die "tuios is not on PATH"
command -v jq    >/dev/null 2>&1 || die "jq is required"

# --- Pick a project directory (mirrors tmux-sessionizer.sh) ----------------
if [ $# -ge 1 ]; then
  selected=$1
else
  command -v fzf >/dev/null 2>&1 || die "fzf is required"
  selected=$(find \
    "$HOME/.config" \
    "$HOME" \
    "$HOME/projects" \
    "$HOME/klar" \
    "$HOME/klar/klar-fe" \
    -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf) || {
      log "fzf cancelled"
      exit 0
    }
fi
[ -n "$selected" ] || { log "no selection"; exit 0; }
[ -d "$selected" ] || die "not a directory: $selected"
selected=$(cd "$selected" && pwd)

# ':' means HOST:SESSION to tuios, so keep it (and dots/spaces) out of names.
SESSION=$(basename "$selected" | tr '.: ' '___')
ROOT=$selected
log "selected: $ROOT  (session=$SESSION)"

session_exists() {
  tuios ls --json 2>/dev/null \
    | jq -e --arg n "$1" 'any(.[]; .name == $n)' >/dev/null 2>&1
}

# --- Layout helpers, used by the files in tuios/layouts/ ---------------------
CUR_WS=1
CUR_LABEL=""
PANE_N=0
FIRST_WIN=""       # the window `tuios new` creates; reused as the first pane
FOCUS_ID=""
PENDING_IDS=()
PENDING_CMDS=()

# ws N LABEL: following panes go on workspace N, which is named LABEL.
ws() {
  CUR_WS=$1
  CUR_LABEL=$2
  PANE_N=0
  tuios set-workspace-name -s "$SESSION" "$CUR_WS" "$CUR_LABEL" >/dev/null \
    || warn "could not name workspace $CUR_WS"
}

# pane [CMD]: add a pane in $ROOT on the current workspace; type CMD into it.
pane() {
  local cmd=${1:-} name id
  PANE_N=$((PANE_N + 1))
  name=$CUR_LABEL
  [ "$PANE_N" -gt 1 ] && name="$CUR_LABEL-$PANE_N"

  if [ -n "$FIRST_WIN" ] && [ "$CUR_WS" = 1 ]; then
    id=$FIRST_WIN
    FIRST_WIN=""
    tuios set-window -s "$SESSION" -w "$id" --name "$name" >/dev/null \
      || warn "could not name window $name"
  else
    id=$(tuios new-window -s "$SESSION" "$name" --workspace "$CUR_WS" \
           --cwd "$ROOT" --no-focus --print-id) \
      || { warn "could not open pane $name on workspace $CUR_WS"; return 0; }
  fi

  [ -z "$FOCUS_ID" ] && FOCUS_ID=$id
  if [ -n "$cmd" ]; then
    PENDING_IDS+=("$id")
    PENDING_CMDS+=("$cmd")
  fi
}

build_session() {
  local layout
  case "$ROOT" in
    *new-shiny-theme-palette*|*klar-fe*) layout="klar-fe.sh" ;;
    *)                                    layout="default.sh" ;;
  esac
  [ -f "$LAYOUT_DIR/$layout" ] || die "missing layout $LAYOUT_DIR/$layout"

  log "creating session $SESSION with layout $layout"
  tuios new "$SESSION" --detach --cwd "$ROOT" >/dev/null \
    || die "tuios new $SESSION failed"

  FIRST_WIN=$(tuios list-windows -s "$SESSION" --json \
    | jq -r '.windows[0].window_id // empty')

  # shellcheck source=/dev/null
  . "$LAYOUT_DIR/$layout"

  # Type the commands once each shell has drawn its prompt. Panes were all
  # opened above, so they start in parallel and these waits are short.
  local i
  for ((i = 0; i < ${#PENDING_IDS[@]}; i++)); do
    tuios wait-for window-idle -s "$SESSION" -w "${PENDING_IDS[$i]}" \
      --idle 300 --timeout 5000 >/dev/null 2>&1 || true
    tuios send-text -s "$SESSION" -w "${PENDING_IDS[$i]}" \
      "${PENDING_CMDS[$i]}"$'\n' >/dev/null \
      || warn "could not start: ${PENDING_CMDS[$i]}"
  done

  tuios select-workspace -s "$SESSION" 1 >/dev/null || warn "select-workspace failed"
  if [ -n "$FOCUS_ID" ]; then
    tuios focus-window -s "$SESSION" "$FOCUS_ID" >/dev/null || warn "focus failed"
  fi
}

if session_exists "$SESSION"; then
  log "session $SESSION exists"
else
  build_session
fi

# --- Show it ----------------------------------------------------------------
[ "$attach" = 1 ] || { log "done (not attaching)"; exit 0; }

if [ "${TUIOS_ENV:-}" = "1" ]; then
  log "switching to $SESSION"
  tuios switch-session "$SESSION" >/dev/null || die "switch-session failed"
else
  log "attaching to $SESSION"
  exec tuios attach "$SESSION"
fi
