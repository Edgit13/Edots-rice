#!/usr/bin/env bash
#
# sync.sh — Edots-rice config symlinker.
#
# Links each config in the repository directly into ~/.config via symlink,
# so editing the repo file and editing ~/.config/... touch the same file.
#
# Usage:
#   ./sync.sh install      link everything (backs up old real configs)
#   ./sync.sh status       show link state for each config
#   ./sync.sh unlink       remove symlinks we created
#   ./sync.sh firefox      print manual steps for the Firefox chrome files
#   ./sync.sh --dry-run install
#
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
SYSTEMD_HOME="$CONFIG_HOME/systemd/user"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then DRY_RUN=1; shift; fi

# ---------- directory symlinks: "repo_path:target" ----------
LINKS=(
  "alacritty:$CONFIG_HOME/alacritty"
  "dolphinrc:$CONFIG_HOME/dolphinrc"
  "edots:$HOME/edots"
  "fish:$CONFIG_HOME/fish"
  "ghostty:$CONFIG_HOME/ghostty"
  "gtk-3.0:$CONFIG_HOME/gtk-3.0"
  "gtk-4.0:$CONFIG_HOME/gtk-4.0"
  "kdeglobals:$CONFIG_HOME/kdeglobals"
  "kitty:$CONFIG_HOME/kitty"
  "mango:$CONFIG_HOME/mango"
  "nvim:$CONFIG_HOME/nvim"
  "quickshell:$CONFIG_HOME/quickshell"
  "rofi:$CONFIG_HOME/rofi"
  "swaylock:$CONFIG_HOME/swaylock"
  "swaync:$CONFIG_HOME/swaync"
)

# ---------- file symlinks into systemd user dir ----------
FILE_LINKS=(
  "systemd/edots-lockscreen.service:$SYSTEMD_HOME/edots-lockscreen.service"
  "systemd/swayidle.service:$SYSTEMD_HOME/swayidle.service"
)

# ---------- helpers that go into /usr/local/bin (need sudo) ----------
BIN_LINKS=(
  "edots/tool-manager/upkg:/usr/local/bin/upkg"
  "edots/tool-manager/utimer:/usr/local/bin/utimer"
)

# ---------- output helpers ----------
c_green="\033[0;32m"; c_yellow="\033[0;33m"; c_red="\033[0;31m"; c_dim="\033[2m"; c_reset="\033[0m"
info() { printf "${c_green}[ok]${c_reset}  %s\n" "$*"; }
warn() { printf "${c_yellow}[!!]${c_reset}  %s\n" "$*"; }
err()  { printf "${c_red}[err]${c_reset} %s\n" "$*"; }
dim()  { printf "${c_dim}     %s${c_reset}\n" "$*"; }

run() {
  if [ "$DRY_RUN" = "1" ]; then dim "DRY: $*"; else "$@"; fi
}

# ---------- core linker ----------
_link() {
  local src="$1" dst="$2"
  if [ ! -e "$src" ]; then warn "missing in repo, skipping: $src"; return 1; fi

  if [ -L "$dst" ]; then
    if [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
      info "already linked: $dst"; return 0
    fi
    warn "replacing stale link: $dst -> $(readlink "$dst")"
    run rm "$dst"
  elif [ -e "$dst" ]; then
    run mkdir -p "$BACKUP_DIR"
    warn "backing up old: $dst -> $BACKUP_DIR/"
    run mv "$dst" "$BACKUP_DIR/"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  info "linked: $dst -> $src"
}

_unlink() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    run rm "$dst"; info "removed: $dst"
  fi
}

_status() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
    info "$dst -> $src"
  elif [ -L "$dst" ]; then
    warn "$dst symlink, but points elsewhere ($(readlink -f "$dst"))"
  elif [ -e "$dst" ]; then
    err  "$dst exists but is NOT a symlink (real copy)"
  else
    warn "$dst missing"
  fi
}

# ---------- commands ----------
cmd_install() {
  run mkdir -p "$CONFIG_HOME"

  echo "── directory links ──"
  for pair in "${LINKS[@]}"; do
    _link "${pair%%:*}" "${pair#*:}"
  done

  echo
  echo "── systemd user units ──"
  run mkdir -p "$SYSTEMD_HOME"
  for pair in "${FILE_LINKS[@]}"; do
    _link "$REPO_DIR/${pair%%:*}" "${pair#*:}"
  done

  echo
  echo "── scripts +x ──"
  run chmod +x "$REPO_DIR"/quickshell/bar/reload.sh 2>/dev/null || true
  run chmod +x "$REPO_DIR"/quickshell/lockscreen/*.sh 2>/dev/null || true
  run chmod +x "$REPO_DIR"/quickshell/scripts/*.sh 2>/dev/null || true
  run chmod +x "$REPO_DIR"/mango/scripts/*.sh 2>/dev/null || true
  run chmod +x "$REPO_DIR"/edots/tool-manager/upkg "$REPO_DIR"/edots/tool-manager/utimer 2>/dev/null || true
  info "chmod +x applied"

  echo
  echo "── bin links (sudo) ──"
  if ! command -v sudo >/dev/null; then
    warn "sudo missing, skipping bin links"
  else
    for pair in "${BIN_LINKS[@]}"; do
      local src="$REPO_DIR/${pair%%:*}" dst="${pair#*:}"
      if [ ! -e "$src" ]; then warn "missing in repo, skipping: $src"; continue; fi
      if [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        info "already linked: $dst"; continue
      fi
      run sudo ln -sf "$src" "$dst"
      info "linked (sudo): $dst -> $src"
    done
  fi

  echo
  echo "── reload user systemd ──"
  run systemctl --user daemon-reload || warn "systemctl --user unavailable"

  echo
  echo "── initial colour generation ──"
  if command -v python3 >/dev/null; then
    local wp
    wp="$(find "$HOME/Pictures/Wallpapers" -type f \
          \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
          2>/dev/null | head -n 1)"
    if [ -n "${wp:-}" ]; then
      run python3 "$REPO_DIR/mango/scripts/wallcolors.py" "$wp" \
        || warn "wallcolors.py failed, run manually"
    else
      warn "no wallpapers found — clone Edot-Wallpapers or set one manually"
    fi
  fi

  if [ -d "$BACKUP_DIR" ]; then
    echo
    echo "Old configs backed up in: $BACKUP_DIR"
  fi

  echo
  info "done.  qs -p $CONFIG_HOME/quickshell/bar/shell.qml"
  echo
  echo "Firefox chrome files need a manual step — see:  ./sync.sh firefox"
}

cmd_status() {
  for pair in "${LINKS[@]}"; do _status "${pair%%:*}" "${pair#*:}"; done
  echo
  for pair in "${FILE_LINKS[@]}"; do _status "$REPO_DIR/${pair%%:*}" "${pair#*:}"; done
  echo
  for pair in "${BIN_LINKS[@]}"; do _status "$REPO_DIR/${pair%%:*}" "${pair#*:}"; done
}

cmd_unlink() {
  for pair in "${LINKS[@]}"; do _unlink "${pair%%:*}" "${pair#*:}"; done
  for pair in "${FILE_LINKS[@]}"; do _unlink "$REPO_DIR/${pair%%:*}" "${pair#*:}"; done
  for pair in "${BIN_LINKS[@]}"; do
    local src="$REPO_DIR/${pair%%:*}" dst="${pair#*:}"
    [ -L "$dst" ] && [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ] && sudo rm "$dst" && info "removed (sudo): $dst"
  done
  echo "Backups in ~/.config-backup-* can be restored manually."
}

cmd_firefox() {
  cat <<'EOF'
Firefox userChrome.css / userContent.css need to live in <profile>/chrome/.

Steps:
  1. Open Firefox → about:support
  2. Find "Profile Folder" → click "Open Folder"
  3. From the repo:
        mkdir -p <profile>/chrome
        ln -sf ~/Dotfiles/firefox/chrome/userChrome.css  <profile>/chrome/userChrome.css
        ln -sf ~/Dotfiles/firefox/chrome/userContent.css <profile>/chrome/userContent.css
  4. about:config → toolkit.legacyUserProfileCustomizations.stylesheet = true
  5. Restart Firefox.

The colour palette itself (~/.config/firefox-colors.css) is written by
wallcolors.py — no symlink needed, both CSS files @import it.
EOF
}

case "${1:-}" in
  install)  cmd_install ;;
  status)   cmd_status ;;
  unlink)   cmd_unlink ;;
  firefox)  cmd_firefox ;;
  *)
    cat <<EOF
Usage: $0 [--dry-run] {install|status|unlink|firefox}

  install   link every config from the repo into ~/.config (and systemd, bin)
  status    show what's currently linked
  unlink    remove symlinks this script created
  firefox   print manual steps for Firefox chrome (needs profile path)
EOF
    exit 1 ;;
esac
