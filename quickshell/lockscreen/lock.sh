#!/usr/bin/env bash
# Launch the Edots M3 lock screen as a single instance.
# Used by swayidle before-sleep, loginctl lock-session, and Super+L.

set -euo pipefail

SHELL_QML="$HOME/Dotfiles/quickshell/lockscreen/shell.qml"
LOG="/tmp/qs-lockscreen.log"

# Already running? Exit — the existing instance will handle the lock.
if pgrep -f "qs -p ${SHELL_QML}" >/dev/null; then
    exit 0
fi

exec qs -p "$SHELL_QML" >>"$LOG" 2>&1
