#!/usr/bin/env bash
# Lock, wait for ack, suspend.
set -euo pipefail

LOCK="$HOME/Dotfiles/quickshell/lockscreen/lock.sh"

# Kick off the lock (idempotent — pgrep guard inside)
bash "$LOCK" &

# Wait until logind says the session is locked, or 3 s timeout
for _ in $(seq 1 30); do
    if loginctl show-session "$XDG_SESSION_ID" -p LockedHint --value 2>/dev/null | grep -q yes; then
        break
    fi
    sleep 0.1
done

systemctl suspend
