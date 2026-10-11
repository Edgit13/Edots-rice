#!/usr/bin/env bash
# M3 dock toggle.
#
# The dock now lives inside the bar shell (bar/dock/DockLoader.qml), so this
# just flips the state file the loader watches. It is instant and works even
# when the bar shell is not running (the loader picks it up on next start).
set -euo pipefail

STATE="$HOME/Dotfiles/quickshell/dock/state"

[ -f "$STATE" ] || echo 1 > "$STATE"

cur="$(tr -d "[:space:]" < "$STATE")"
if [ "$cur" = "0" ]; then
    echo 1 > "$STATE"
    echo "dock -> shown"
else
    echo 0 > "$STATE"
    echo "dock -> hidden"
fi
