#!/usr/bin/env bash
# gamemode.sh — ігровий режим для MangoWM (+ Quickshell).
#   gamemode.sh [toggle|on|off|status]        (без аргументу = toggle)
#
# Що робить (кожен пункт вмикається у Settings → Ігровий режим → ~/.cache/quickshell/gamemode.conf):
#   EFFECTS  — MangoWM: blur / blur_layer / shadows / layer_shadows / border_radius / animations / layer_animations = 0,
#              focused_opacity / unfocused_opacity = 1 (без прозорості — менше змішування шарів)
#              (через dispatcher `setoption` — тимчасово; вихід = reload_config повертає все з config.conf)
#   TEARING  — allow_tearing=1: повноекранні ігри можуть показувати кадри без vsync (менша затримка)
#   POWER    — power-profiles-daemon → performance (потім повертається попередній профіль)
#   IDLE     — swayidle ставиться на паузу (SIGSTOP), щоб екран не гас і не блокувався під час гри
#   DND      — робить сам Quickshell (GameModeState): сповіщення мовчать, анімації shell вимкнені
#   PAUSE    — (необов'язково) імена процесів через пробіл, які ставимо на паузу, напр. PAUSE="awww-daemon"
#
# Порада: самі ігри запускай через `gamemoderun %command%` (Feral GameMode) — це додає CPU/GPU-тюнінг.
set -u

CACHE="$HOME/.cache/quickshell"
STATE="$CACHE/gamemode.state"
SAVED="$CACHE/gamemode.saved"
CONF="$CACHE/gamemode.conf"
mkdir -p "$CACHE"

EFFECTS=1; TEARING=1; POWER=1; IDLE=1; NOTIFY=1; PAUSE=""
MSG_ON="Game mode on"; MSG_ON_BODY="Effects off, power profile: performance"; MSG_OFF="Game mode off"   # локалізує Quickshell
# shellcheck disable=SC1090
[ -f "$CONF" ] && . "$CONF"

is_on() { [ "$(cat "$STATE" 2>/dev/null)" = "1" ]; }

notify() {
    [ "${NOTIFY:-1}" = "1" ] || return 0
    command -v notify-send >/dev/null 2>&1 && notify-send -a "Game mode" -i input-gaming "$1" "${2:-}"
}

# ── IPC до MangoWM: mmsg dispatch (нове покоління) або mmsg -d (старе) ──
MM_MODE=""
if command -v mmsg >/dev/null 2>&1; then
    if timeout 1 mmsg get version >/dev/null 2>&1; then MM_MODE="new"; else MM_MODE="old"; fi
fi
mm() {
    case "$MM_MODE" in
        new) mmsg dispatch "$1" >/dev/null 2>&1 ;;
        old) mmsg -d "$1" >/dev/null 2>&1 ;;
        *)   command -v mango >/dev/null 2>&1 && mango msg dispatch "$1" >/dev/null 2>&1 ;;
    esac
}

save() { printf '%s=%s\n' "$1" "$2" >> "$SAVED"; }

enable() {
    : > "$SAVED"

    if [ "$POWER" = "1" ] && command -v powerprofilesctl >/dev/null 2>&1; then
        prev="$(powerprofilesctl get 2>/dev/null)"
        [ -n "$prev" ] && save PROFILE "$prev"
        powerprofilesctl set performance 2>/dev/null
    fi

    if [ "$IDLE" = "1" ] && pkill -STOP -x swayidle 2>/dev/null; then save IDLE 1; fi

    if [ -n "$PAUSE" ]; then
        for p in $PAUSE; do pkill -STOP -x "$p" 2>/dev/null && save PAUSED "$p"; done
    fi

    if [ "$EFFECTS" = "1" ]; then
        for o in blur,0 blur_layer,0 shadows,0 layer_shadows,0 border_radius,0 \
                 animations,0 layer_animations,0 focused_opacity,1 unfocused_opacity,1; do
            mm "setoption,$o"
        done
        save EFFECTS 1
    fi
    [ "$TEARING" = "1" ] && { mm "setoption,allow_tearing,1"; save TEARING 1; }

    notify "$MSG_ON" "$MSG_ON_BODY"
    echo 1 > "$STATE"                       # Quickshell реагує на цей файл (DND, анімації, індикатор у барі)
}

disable() {
    PROFILE=""; IDLE_SAVED=""; EFFECTS_SAVED=""; TEARING_SAVED=""; PAUSED_LIST=""
    if [ -f "$SAVED" ]; then
        while IFS='=' read -r k v; do
            case "$k" in
                PROFILE) PROFILE="$v" ;;
                IDLE)    IDLE_SAVED="$v" ;;
                EFFECTS) EFFECTS_SAVED="$v" ;;
                TEARING) TEARING_SAVED="$v" ;;
                PAUSED)  PAUSED_LIST="$PAUSED_LIST $v" ;;
            esac
        done < "$SAVED"
    fi

    echo 0 > "$STATE"                       # спочатку знімаємо DND, щоб повідомлення нижче показалось

    pkill -CONT -x swayidle 2>/dev/null     # завжди відновлюємо, навіть якщо запис втрачено
    for p in $PAUSED_LIST; do pkill -CONT -x "$p" 2>/dev/null; done

    if command -v powerprofilesctl >/dev/null 2>&1; then
        powerprofilesctl set "${PROFILE:-balanced}" 2>/dev/null
    fi

    # setoption тимчасовий — reload_config повертає blur/тіні/кути/анімації з config.conf
    if [ -n "$EFFECTS_SAVED$TEARING_SAVED" ] || [ ! -f "$SAVED" ]; then mm "reload_config"; fi

    rm -f "$SAVED"
    notify "$MSG_OFF"
}

case "${1:-toggle}" in
    on|enable)    is_on || enable ;;
    off|disable)  is_on && disable || { pkill -CONT -x swayidle 2>/dev/null; true; } ;;
    status)       if is_on; then echo on; exit 0; else echo off; exit 1; fi ;;
    toggle|*)     if is_on; then disable; else enable; fi ;;
esac
