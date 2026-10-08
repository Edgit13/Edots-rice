#!/usr/bin/env bash
# M3 dock toggle.
#   dock not running -> starts it (detached), honoring the state file
#   dock running     -> flips the state file: 1 -> 0 (hide), 0 -> 1 (show)
# The dock watches the state file live, so the flip is instant — no restart.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$DIR/state"
LOG="$DIR/dock.log"

# A detached dock shows up in the process list as "qs -d -p <dir>", so the
# pattern must match any "qs ... <dir>" cmdline (that's also why the old
# "qs -p <dir>" pattern always reported "not running").
running() {
    pgrep -f "qs .*${DIR}" >/dev/null 2>&1
}

if running; then
    cur="$(tr -d '[:space:]' < "$STATE" 2>/dev/null || true)"
    if [ "$cur" = "0" ]; then
        echo 1 > "$STATE"
        echo "dock running -> state=1 (shown)"
    else
        echo 0 > "$STATE"
        echo "dock running -> state=0 (hidden, still active)"
    fi
    exit 0
fi

[ -f "$STATE" ] || echo 1 > "$STATE"
if ! qs -d -p "$DIR" >>"$LOG" 2>&1; then
    echo "ERROR: dock failed to start — run this to see why:"
    echo "  qs -p $DIR"
    exit 1
fi
echo "dock started (state=$(tr -d '[:space:]' < "$STATE"))"
