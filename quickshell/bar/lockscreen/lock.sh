#!/usr/bin/env bash
# Trigger the M3 lock screen via the running bar shell.
# The bar owns the WlSessionLock (bar/lockscreen/LockScreen.qml) and listens
# on the "ilock" IPC target.
set -euo pipefail

BAR_SHELL="$HOME/.config/quickshell/bar/shell.qml"

# Start the bar if it is not running.
if ! pgrep -f "qs -d -p .*bar/shell.qml" >/dev/null; then
    qs -d -p "$BAR_SHELL" >/dev/null 2>&1
    sleep 1
fi

qs -p "$BAR_SHELL" ipc call ilock relock
