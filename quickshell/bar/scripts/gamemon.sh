#!/usr/bin/env bash
# gamemon.sh [mangohud_dir] — один рядок key=value для ігрового оверлея Quickshell:
#   gpu= gtemp=        — навантаження/температура GPU (AMD: sysfs, NVIDIA: nvidia-smi; інакше -1)
#   mh= mhfps= mhgpu= mhcpu=  — останній семпл логу MangoHud (mh = вік файлу в секундах, -1 якщо логу немає)
set -u
dir="${1:-/tmp/MangoHud}"

gpu=-1; gtemp=-1
for d in /sys/class/drm/card[0-9]*/device; do
  if [ -r "$d/gpu_busy_percent" ]; then
    gpu=$(cat "$d/gpu_busy_percent" 2>/dev/null || echo -1)
    t=$(cat "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
    [ -n "$t" ] && gtemp=$((t / 1000))
    break
  fi
done
if [ "$gpu" = "-1" ] && command -v nvidia-smi >/dev/null 2>&1; then
  o=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 | tr -d ' ')
  if [ -n "$o" ]; then gpu=${o%%,*}; gtemp=${o##*,}; fi
fi

mh=-1; mhfps=0; mhgpu=-1; mhcpu=-1
f=$(ls -t "$dir"/*.csv 2>/dev/null | grep -v '_summary' | head -1)
if [ -n "$f" ]; then
  hdr=$(grep -m1 '^fps,' "$f")
  last=$(tail -n1 "$f")
  if [ -n "$hdr" ] && [ "$last" != "$hdr" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$f") ))
    read -r mhfps mhgpu mhcpu < <(printf '%s\n%s\n' "$hdr" "$last" | awk -F, '
      NR==1 { for (i = 1; i <= NF; i++) c[$i] = i; next }
      { printf "%s %s %s\n", $(c["fps"]), (c["gpu_load"] ? $(c["gpu_load"]) : -1), (c["cpu_load"] ? $(c["cpu_load"]) : -1) }')
    [ -n "${mhfps:-}" ] && mh=$age
  fi
fi
echo "gpu=$gpu gtemp=$gtemp mh=$mh mhfps=${mhfps:-0} mhgpu=${mhgpu:--1} mhcpu=${mhcpu:--1}"
