#!/usr/bin/env bash
# Herdr equivalent of tmux-sessionizer.sh.
#
# Works two ways:
#   1. Inside a Herdr pane (HERDR_ENV=1), launched from the keybinding in
#      dotfiles/herdr/config.toml. Applies (or focuses) the workspace and
#      returns to the caller pane.
#   2. From a plain shell (no HERDR_ENV). Starts the Herdr server if
#      needed, applies (or focuses) the workspace, then attaches with
#      `exec herdr` so the shell becomes the Herdr client.

# Note: intentionally NOT using `set -e`. We want visible errors, not
# silent exits, so every step logs and continues to the attach step.
set -u
set -o pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
TEMPLATE_DIR="$DOTFILES/herdr-spreader"

log()  { printf 'sessionizer: %s\n' "$*" >&2; }
die()  { log "ERROR: $*"; exit 1; }
warn() { log "WARN: $*"; }

# --- Prerequisites ---------------------------------------------------------
command -v jq       >/dev/null 2>&1 || die "jq is required"
command -v fzf      >/dev/null 2>&1 || die "fzf is required"
command -v envsubst >/dev/null 2>&1 || die "envsubst is required (gettext)"
command -v herdr    >/dev/null 2>&1 || die "herdr is not on PATH"

# --- Resolve herdr-spreader binary (plugin build fallback) -----------------
SPREADER=$(command -v herdr-spreader 2>/dev/null || true)
if [ -z "$SPREADER" ]; then
  SPREADER=$(find "$HOME/.config/herdr/plugins/github" \
    -maxdepth 4 -type f -name herdr-spreader -perm -111 2>/dev/null | head -n 1)
fi
[ -n "$SPREADER" ] || die "herdr-spreader not found; install with:
  herdr plugin install yuk1ty/herdr-spreader"

# --- Ensure the herdr server is running ------------------------------------
# Note: `herdr status server` always returns exit 0 (running or not), so we
# have to health-check with a real API call. `workspace list` is cheap and
# fails fast with a socket error when the server is dead or its socket is
# stale.
server_alive() { herdr workspace list >/dev/null 2>&1; }

ensure_server() {
  if server_alive; then
    log "server already running"
    return 0
  fi

  # Clean up any stale sockets left behind by a killed/crashed server so
  # the fresh one can bind cleanly.
  for sock in "$HOME/.config/herdr/herdr.sock" \
              "$HOME/.config/herdr/herdr-client.sock"; do
    if [ -e "$sock" ] && [ ! -S "$sock" ] || \
       { [ -S "$sock" ] && ! server_alive; }; then
      rm -f "$sock" && log "removed stale socket $sock"
    fi
  done

  log "starting herdr server..."
  nohup herdr server </dev/null >/tmp/herdr-server.startup.log 2>&1 &
  disown 2>/dev/null || true
  for _ in $(seq 1 60); do
    if server_alive; then
      log "server up"
      return 0
    fi
    sleep 0.1
  done
  log "herdr server did not come up in time. Last startup log:"
  tail -n 20 /tmp/herdr-server.startup.log >&2 || true
  return 1
}

ensure_server || die "could not start herdr server"

# --- Pick a project directory (mirrors tmux-sessionizer.sh) ----------------
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
[ -n "$selected" ] || { log "no selection"; exit 0; }

selected_name=$(basename "$selected" | tr . _)
log "selected: $selected  (label=$selected_name)"

# --- Focus if a workspace with that label already exists -------------------
existing_id=""
if ws_json=$(herdr workspace list 2>&1); then
  existing_id=$(printf '%s' "$ws_json" \
    | jq -r --arg n "$selected_name" \
        '.result.workspaces[]? | select(.label == $n) | .workspace_id' \
        2>/dev/null | head -n 1 || true)
else
  warn "workspace list failed: $ws_json"
fi

if [ -n "$existing_id" ]; then
  log "focusing existing workspace $selected_name ($existing_id)"
  herdr workspace focus "$existing_id" >/dev/null || warn "focus failed"
else
  # --- Otherwise render the right template and apply it --------------------
  case "$selected" in
    *new-shiny-theme-palette*|*klar-fe*) tpl_name="klar-fe.yaml" ;;
    *)                                    tpl_name="no_server.yaml" ;;
  esac
  template="$TEMPLATE_DIR/$tpl_name"
  [ -f "$template" ] || die "missing template $template"

  rendered=$(mktemp -t "herdr-spreader.${selected_name}.XXXXXX.yaml")
  trap 'rm -f "$rendered"' EXIT

  SESSION_NAME="$selected_name" QUERY="$selected" \
    envsubst '${SESSION_NAME} ${QUERY}' <"$template" >"$rendered"

  log "applying $tpl_name -> workspace $selected_name"
  if ! "$SPREADER" apply --file "$rendered"; then
    die "herdr-spreader apply failed (see error above)"
  fi
fi

# --- Attach if we were launched from outside herdr -------------------------
if [ -z "${HERDR_ENV:-}" ]; then
  log "attaching to herdr (exec herdr)..."
  exec herdr
fi

log "done"
