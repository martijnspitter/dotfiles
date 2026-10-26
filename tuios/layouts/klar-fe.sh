# tuios-sessionizer layout - klar-fe (with proxy + dev server)
# Sourced by ~/dotfiles/tuios-sessionizer.sh. Port of herdr-spreader/klar-fe.yaml.
# See default.sh for the ws/pane helpers.

ws 1 pi
pane pi

ws 2 editor
pane

ws 3 git
pane lazygit

ws 4 terminal
pane
pane

# Left pane: klar-proxy-prod via docker compose in ./proxy. Attaches when it
# is already running, starts it otherwise. One `sh -c` payload so the whole
# conditional is typed as a single line.
proxy_cmd=$(cat <<'EOF'
sh -c 'echo "[server] cd ./proxy"; cd proxy || { echo "[server] no ./proxy in $PWD"; exit 1; }; echo "[server] checking klar-proxy-prod..."; if docker compose ps --status running --format "{{.Name}}" | grep -qx klar-proxy-prod; then echo "[server] attaching (ctrl-p ctrl-q to detach)"; docker compose attach klar-proxy-prod; else echo "[server] starting klar-proxy-prod..."; docker compose up klar-proxy-prod; fi'
EOF
)

ws 5 server
pane "$proxy_cmd"
# Right pane: vite dev server.
pane "echo '[dev] pnpm start'; pnpm start"
