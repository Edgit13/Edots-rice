#!/usr/bin/env bash
# screenrec.sh — запис екрана для MangoWM (wf-recorder). Працює незалежно від Quickshell:
# його можна смикати і з біндів, а shell лише читає ~/.cache/quickshell/screenrec.state для таймера в барі.
#
#   screenrec.sh start [--geometry "X,Y WxH"] [--output NAME] [--audio none|system|mic]
#                      [--fps N] [--encoder software|vaapi] [--delay SEC]
#   screenrec.sh stop | toggle [старт-аргументи] | status
#
# Налаштування за замовчуванням — ~/.cache/quickshell/screenrec.conf (пише Quickshell із Settings → Запис екрана).
# Потрібно: wf-recorder; за наявності ffmpeg/ffprobe — мініатюра й тривалість у сповіщенні; pactl — системний звук.
set -u

CACHE="$HOME/.cache/quickshell"
STATE="$CACHE/screenrec.state"
CONF="$CACHE/screenrec.conf"
LOG="$CACHE/screenrec.log"
mkdir -p "$CACHE"

AUDIO=system; FPS=30; ENCODER=software; DIR="$HOME/Videos/Recordings"; NOTIFY=1; VAAPI_DEVICE=/dev/dri/renderD128
MSG_DONE="Recording saved"; MSG_FAIL="Recording failed"; MSG_SOON="Recording starts in %ss"; MSG_MISSING="wf-recorder is not installed"
LBL_OPEN="Open"; LBL_FOLDER="Show in folder"; LBL_COPY="Copy path"
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"
DIR="${DIR/#\~/$HOME}"

alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }

PID=""; START=""; FILE=""
read_state() {
    PID=""; START=""; FILE=""
    [ -f "$STATE" ] || return 0
    local k v
    while IFS='=' read -r k v; do
        case "$k" in pid) PID="$v" ;; start) START="$v" ;; file) FILE="$v" ;; esac
    done < "$STATE"
}

notify() {  # notify <urgency> <title> [body]
    [ "$NOTIFY" = "1" ] || [ "$1" = "critical" ] || return 0
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Screen recorder" -u "$1" -i media-record "$2" "${3:-}"
}

show_in_folder() {
    if command -v gdbus >/dev/null 2>&1 && gdbus call --session --dest org.freedesktop.FileManager1 \
        --object-path /org/freedesktop/FileManager1 --method org.freedesktop.FileManager1.ShowItems \
        "['file://$1']" "" >/dev/null 2>&1; then return 0; fi
    xdg-open "$(dirname "$1")" >/dev/null 2>&1
}

finish() {  # після завершення wf-recorder: мініатюра + сповіщення з діями
    local file="$1" thumb="" dur="" size body action=""
    sleep 0.3
    if [ -s "$file" ]; then
        if command -v ffmpeg >/dev/null 2>&1; then
            thumb="$(mktemp --suffix=.png)"
            ffmpeg -loglevel error -y -ss 0.5 -i "$file" -frames:v 1 -vf scale=480:-2 "$thumb" 2>/dev/null || { rm -f "$thumb"; thumb=""; }
        fi
        if command -v ffprobe >/dev/null 2>&1; then
            local sec; sec="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$file" 2>/dev/null | cut -d. -f1)"
            [ -n "$sec" ] && dur="$(printf '%02d:%02d' $((sec / 60)) $((sec % 60)))"
        fi
        size="$(du -h "$file" | cut -f1)"
        body="$(basename "$file")${dur:+  ·  $dur}  ·  $size"
        if [ "$NOTIFY" = "1" ] && command -v notify-send >/dev/null 2>&1; then
            local hint=(); [ -n "$thumb" ] && hint=(-h "string:image-path:$thumb")
            action="$(timeout 3600 notify-send -a "Screen recorder" -i video-x-generic "${hint[@]}" \
                -A "default=$LBL_OPEN" -A "folder=$LBL_FOLDER" -A "copy=$LBL_COPY" -w "$MSG_DONE" "$body" 2>/dev/null)"
        fi
        case "$action" in
            default|open) xdg-open "$file" >/dev/null 2>&1 ;;
            folder)       show_in_folder "$file" ;;
            copy)         command -v wl-copy >/dev/null 2>&1 && printf %s "$file" | wl-copy ;;
        esac
        [ -n "$thumb" ] && rm -f "$thumb"
    else
        notify critical "$MSG_FAIL" "$(tail -n 3 "$LOG" 2>/dev/null)"
    fi
}

cmd_status() {
    read_state
    if alive "$PID"; then echo "recording $(( $(date +%s) - ${START:-0} )) $FILE"; return 0; fi
    rm -f "$STATE"; echo idle; return 1
}

cmd_stop() {
    read_state
    if alive "$PID"; then kill -INT "$PID"; else rm -f "$STATE"; fi
}

cmd_start() {
    local geom="" out="" delay=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --geometry) geom="$2"; shift 2 ;;
            --output)   out="$2"; shift 2 ;;
            --audio)    AUDIO="$2"; shift 2 ;;
            --fps)      FPS="$2"; shift 2 ;;
            --encoder)  ENCODER="$2"; shift 2 ;;
            --delay)    delay="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    read_state
    alive "$PID" && { echo "already recording"; return 0; }
    rm -f "$STATE"

    command -v wf-recorder >/dev/null 2>&1 || { notify critical "$MSG_FAIL" "$MSG_MISSING"; return 1; }

    # даємо оверлею screentool зникнути з екрана, щоб він не потрапив у запис
    sleep 0.45
    if [ "$delay" -gt 0 ] 2>/dev/null; then
        # shellcheck disable=SC2059
        notify low "$(printf "$MSG_SOON" "$delay")"
        sleep "$delay"
    fi

    mkdir -p "$DIR"
    local file; file="$DIR/Recording_$(date +%Y-%m-%d_%H-%M-%S).mp4"
    local args=(-f "$file" -r "$FPS")
    if [ -n "$geom" ]; then args+=(-g "$geom"); elif [ -n "$out" ]; then args+=(-o "$out"); fi
    case "$AUDIO" in
        system) local sink; sink="$(pactl get-default-sink 2>/dev/null)"; [ -n "$sink" ] && args+=("--audio=${sink}.monitor") ;;
        mic)    args+=(--audio) ;;
    esac
    case "$ENCODER" in
        vaapi) args+=(-c h264_vaapi -d "$VAAPI_DEVICE") ;;
        *)     args+=(-c libx264 -p preset=ultrafast -p crf=24) ;;
    esac

    # фонові процеси неінтерактивного shell ігнорують SIGINT — скидаємо, щоб `kill -INT` коректно завершував запис
    local runner=(); env --default-signal=INT true 2>/dev/null && runner=(env --default-signal=INT)
    nohup ${runner[@]+"${runner[@]}"} wf-recorder "${args[@]}" >"$LOG" 2>&1 &
    local pid=$!
    disown "$pid" 2>/dev/null || true
    sleep 0.4
    if ! alive "$pid"; then notify critical "$MSG_FAIL" "$(tail -n 3 "$LOG" 2>/dev/null)"; return 1; fi

    printf 'pid=%s\nstart=%s\nfile=%s\n' "$pid" "$(date +%s)" "$file" > "$STATE"
    nohup "$0" _watch "$pid" "$file" >/dev/null 2>&1 &
    disown 2>/dev/null || true
}

case "${1:-toggle}" in
    start)   shift; cmd_start "$@" ;;
    stop)    cmd_stop ;;
    status)  cmd_status ;;
    toggle)  shift || true; read_state; if alive "$PID"; then cmd_stop; else cmd_start "$@"; fi ;;
    _watch)  pid="$2"; file="$3"
             while alive "$pid"; do sleep 0.5; done
             read_state; [ "$PID" = "$pid" ] && rm -f "$STATE"
             finish "$file" ;;
    *)       echo "usage: $0 start|stop|toggle|status" >&2; exit 2 ;;
esac
