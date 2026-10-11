#!/usr/bin/env bash
# Reload the bar shell: kill any running instance, clear stale IPC lock
# files (dead instance dirs make `qs -p` fail to route IPC to the fresh one),
# start a fresh daemon, and report the resulting PID.
set -euo pipefail

BAR_SHELL="$HOME/.config/quickshell/bar/shell.qml"
UID_NUM="$(id -u)"

# 1. Kill any running instance
pkill -f 'qs .*bar/(shell|ShellNext)\.qml' 2>/dev/null || true
sleep 0.3

# 2. Clear stale IPC state
rm -rf "/run/user/${UID_NUM}/quickshell/by-id/"* 2>/dev/null || true

# 3. Launch detached
qs -d -p "$BAR_SHELL" >/dev/null 2>&1 &
sleep 0.5

# 4. Report
PID="$(pgrep -f "qs -d -p ${BAR_SHELL}" | head -1 || true)"
if [ -n "$PID" ]; then
    echo "bar: running (pid $PID)"
else
    echo "bar: FAILED to start — run this to see why:"
    echo "    qs -p $BAR_SHELL"
    exit 1
fi
