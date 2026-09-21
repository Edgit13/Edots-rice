#!/bin/sh
# Stage 4 — збір фактів про MangoWM/mmsg, щоб не вгадувати API. Нічого не змінює.
#   sh ~/.config/quickshell/bar/tools/mango-probe.sh 2>&1 | tee /tmp/mango-probe.txt
sec() { printf '\n===== %s =====\n' "$1"; }
sec "env"
echo "MANGO_INSTANCE_SIGNATURE=${MANGO_INSTANCE_SIGNATURE:-<unset>}"
echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<unset>}"
qs --version 2>&1 | head -2
command -v mmsg mango mangowm 2>&1
sec "mmsg -h"
mmsg -h 2>&1 | head -30
sec "mmsg get version (json-покоління)"
timeout 2 mmsg get version 2>&1 | head -5
sec "mmsg get all-tags"
timeout 2 mmsg get all-tags 2>&1 | head -c 3500
sec "mmsg get all-monitors"
timeout 2 mmsg get all-monitors 2>&1 | head -c 2500
sec "mmsg -g -t (legacy-покоління)"
timeout 2 mmsg -g -t 2>&1 | head -40
sec "mmsg watch all-tags (2 с)"
timeout 2 mmsg watch all-tags 2>&1 | head -c 2500
echo
echo "== done =="
