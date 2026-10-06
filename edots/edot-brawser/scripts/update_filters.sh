#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/edot-browser/filters"
mkdir -p "$CACHE"
python3 - "$ROOT/filters/sources.json" "$CACHE" <<'PY'
import json, pathlib, subprocess, sys
sources=json.load(open(sys.argv[1], encoding='utf-8'))
out=pathlib.Path(sys.argv[2])
for s in sources:
    p=out/(s['id'].replace('/','_')+'.txt')
    print('fetch', s['id'])
    subprocess.run(['curl','-L','--fail','--silent','--show-error','--user-agent','edot-browser/2.0',s['url'],'-o',str(p)], check=True)
PY
