#!/usr/bin/env bash
# Edots — bootstrap / sync / upgrade
# OS auto-detect: Arch → pacman+yay; NixOS → flake rebuild через sudo.
# Usage: ./install.sh [--minimal] [--cli-only] [--restore]

set -e
cd "$(dirname "$0")"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2; exit 1; }

MINIMAL=0 CLI_ONLY=0 RESTORE=0
for a in "$@"; do
  case "$a" in
    --minimal)  MINIMAL=1 ;;
    --cli-only) CLI_ONLY=1 ;;
    --restore)  RESTORE=1 ;;
    *) ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    echo "unknown"
  fi
}

detect_pkg_manager() {
  if command -v pacman >/dev/null; then echo "pacman"
  elif command -v nix-env >/dev/null; then echo "nix"
  else echo "unknown"
  fi
}

install_arch_packages() {
  # Пакети для повного rice (без терміналів/редакторів)
  PACMAN_PKGS="fish starship btop fastfetch cava yazi eza bat fzf ripgrep jq git gh wget unzip brightnessctl playerctl cliphist network-manager-applet blueman wlrctl wtype wf-recorder grim imagemagick tesseract tesseract-data-eng swaync rofi kitty libnotify wl-clipboard jq matugen"

  # AUR-пакети
  YAY_PKGS="quickshell cava webcord-vencord"

  say "Встановлення пакетів (pacman)…"
  sudo pacman -S --needed --noconfirm $PACMAN_PKGS || warn "pacman: деякі пакети не встановлено"

  if ! command -v yay >/dev/null; then
    warn "yay не знайдено — встановлюю…"
    sudo pacman -S --needed --noconfirm base-devel git || warn "base-devel не встановлено"
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm)
    rm -rf /tmp/yay
  fi

  say "Встановлення AUR-пакетів…"
  yay -S --needed --noconfirm $YAY_PKGS || warn "yay: деякі пакети не встановлено"
}

install_nix_packages() {
  say "NixOS виявлено — збираю flake з nix/…"
  sudo nixos-rebuild switch --flake ./nix#edots || die "nixos-rebuild не вдався"
}

sync_configs() {
  say "Синхронізація конфігів…"
  ./sync.sh
}

restore_backup() {
  say "Restore mode: повернення бекапу ~/.edots-backup (якщо є)…"
  [ -d "$HOME/.edots-backup" ] || { warn "Бекап не знайдено — пропускаю"; return; }
  for d in .config/mango .config/quickshell .config/rofi .config/kitty .config/fish .config/nvim .config/fastfetch; do
    [ -e "$HOME/$d" ] && rm -rf "$HOME/$d"
  done
  cp -r "$HOME/.edots-backup/." "$HOME/"
  say "Restore завершено"
}

# ── Main ─────────────────────────────────────────────────
OS_ID="$(detect_os)"
PKG_MGR="$(detect_pkg_manager)"

say "Виявлено OS=$OS_ID pkg=$PKG_MGR"

if [ "$RESTORE" = 1 ]; then
  restore_backup
  exit 0
fi

case "$PKG_MGR" in
  pacman)
    install_arch_packages
    ;;
  nix)
    install_nix_packages
    ;;
  *)
    warn "Невідомий пакетний менеджер — пропускаю встановлення пакетів"
    ;;
esac

if [ "$CLI_ONLY" = 1 ]; then
  say "CLI-only: пропускаю GUI/sync"
  exit 0
fi

sync_configs

if [ "$MINIMAL" = 1 ]; then
  say "Minimal: лише базові конфіги"
else
  say "Готово! Перелогіньтеся або перезапустіть сесію."
fi
