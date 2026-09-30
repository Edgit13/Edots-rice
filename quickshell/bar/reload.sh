#!/bin/bash

pkill -f 'qs .*bar/(shell|ShellNext)\.qml' 2>/dev/null || true
qs -d -p "$HOME/.config/quickshell/bar/shell.qml" >/dev/null 2>&1 &
