# tuios-sessionizer layout - default (no server)
# Sourced by ~/dotfiles/tuios-sessionizer.sh. Port of herdr-spreader/no_server.yaml.
#
#   ws N LABEL    start tuios workspace N (a herdr "tab") and name it LABEL
#   pane [CMD]    add a pane (window) to that workspace, started in $ROOT.
#                 CMD is typed into the pane's shell, so it lands in history
#                 and the shell stays when CMD exits.
#
# The first pane of the layout gets the focus, and workspace 1 is shown.
# $ROOT is the project directory, $SESSION the session name.

ws 1 pi
pane pi

ws 2 editor
pane

ws 3 git
pane lazygit

ws 4 terminal
pane
pane

ws 5 extra
pane
