#!/bin/bash

pkill -f 'qs .*bar/ShellNext.qml' 2>/dev/null || true
qs -p ~/.config/quickshell/bar/ShellNext.qml>/dev/null 2>&1 &
