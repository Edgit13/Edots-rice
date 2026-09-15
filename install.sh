#!/usr/bin/env bash
#
# install.sh — повний бутстрап Edots-rice.
# Адаптивний до ОС:
#   * NixOS  -> валідація nix/-flake + інструкція підключення модулів
#               (пакети/симлінки керуються NixOS + home-manager, НЕ pacman).
#   * Arch-based (Arch/EndeavourOS/Manjaro/CachyOS...) -> pacman + yay + sync.sh.
#
# Використання:
#   git clone https://github.com/Edgit13/Edots-rice.git ~/Dotfiles
#   cd ~/Dotfiles && ./install.sh
#
set -uo pipefail

REPO_URL="https://github.com/Edgit13/Edots-rice.git"
REPO_DIR="${EDOTS_DIR:-$HOME/Dotfiles}"

# ─────────────────────────── логування ────────────────────────────
c_info()  { printf '\033[36m[i]\033[0m %s\n' "$*"; }
c_warn()  { printf '\033[33m[!]\033[0m %s\n' "$*"; }
c_err()   { printf '\033[31m[x]\033[0m %s\n' "$*"; }
c_ok()    { printf '\033[32m[✓]\033[0m %s\n' "$*"; }

FAILED=()

# ───────────────────── визначення ОС (ДО будь-яких дій) ─────────────────────
detect_os() {
  if [ -r /etc/os-release ] && grep -q '^ID=nixos$' /etc/os-release; then
    echo "nixos"
  elif command -v pacman >/dev/null 2>&1; then
    echo "arch"
  else
    echo "unknown"
  fi
}
OS="$(detect_os)"

if [ "$EUID" -eq 0 ]; then
  c_err "Не запускай від root — скрипт сам просить sudo де треба."
  exit 1
fi

# ───────────────────────── шпалери (спільне для всіх ОС) ─────────────────────────
WALLPAPERS_REPO="https://github.com/Edgit13/Edot-Wallpapers.git"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

echo
echo "Шпалери зберігаються в окремому репозиторії: $WALLPAPERS_REPO"
echo "Якщо погодишся — вони скачаються в: $WALLPAPERS_DIR"
read -r -p "Поставити шпалери? [y/N]: " wp_answer
case "$wp_answer" in
  [Yy]*)
    if [ -d "$WALLPAPERS_DIR/.git" ]; then
      c_info "Репо шпалер вже є — оновлюю (git pull)..."
      if git -C "$WALLPAPERS_DIR" pull --ff-only; then c_ok "шпалери оновлено"
      else c_warn "git pull для шпалер не вдався"; FAILED+=("wallpapers:pull"); fi
    else
      if [ -e "$WALLPAPERS_DIR" ]; then
        wp_backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$wp_backup"
        mv "$WALLPAPERS_DIR" "$wp_backup/Wallpapers"
        c_warn "існуючу $WALLPAPERS_DIR перенесено в $wp_backup/Wallpapers"
      fi
      mkdir -p "$(dirname "$WALLPAPERS_DIR")"
      c_info "Клоную шпалери..."
      if git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"; then c_ok "шпалери склоновано"
      else c_warn "git clone шпалер не вдався"; FAILED+=("wallpapers:clone"); fi
    fi
    ;;
  *)
    c_info "Пропускаю шпалери (пізніше: git clone $WALLPAPERS_REPO $WALLPAPERS_DIR)."
    ;;
esac

# ───────────────────────── клон репозиторію (спільне) ─────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  c_info "Репо вже є в $REPO_DIR — пропускаю clone."
elif [ -d "$REPO_DIR" ]; then
  c_warn "$REPO_DIR існує, але це не git-репо. Клонуй вручну або онови REPO_DIR."
else
  c_info "Клоную репозиторій у $REPO_DIR..."
  git clone "$REPO_URL" "$REPO_DIR" || { c_err "git clone не вдався"; exit 1; }
fi
cd "$REPO_DIR" || exit 1

# ════════════════════════ NIXOS ════════════════════════
install_nixos() {
  c_info "Виявлено NixOS — пакети й симлінки керуються NixOS + home-manager."

  if ! command -v nix >/dev/null 2>&1; then
    c_err "nix не знайдено у PATH — це не повинно трапитись на NixOS."
    exit 1
  fi

  # Валідація nix/-flake (не фатально: перший run качає inputs)
  if [ -f "$REPO_DIR/nix/flake.nix" ]; then
    c_info "Валідую nix/ (flake check)..."
    if nix --extra-experimental-features 'nix-command flakes' flake check "$REPO_DIR/nix" --no-write-lock-file 2>&1 | tail -5; then
      c_ok "nix/ валідний"
    else
      c_warn "flake check не пройшов (може треба мережа/inputs) — модулі все одно в ./nix"
      FAILED+=("nix:flake-check")
    fi
  else
    c_warn "nix/ відсутній у репо — онови репозиторій (git pull)."
    FAILED+=("nix:no-flake-dir")
  fi

  cat << 'EOF'

─────────────────── ПІДКЛЮЧЕННЯ ДО ТВОГО FLAKE ───────────────────

У flake.nix твоєї NixOS-конфігурації додай:

  inputs.edots.url = "github:Edgit13/Edots-rice";   # або path:/home/you/Dotfiles
  inputs.edots.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mango.url = "github:mangowm/mango";
  inputs.mango.inputs.nixpkgs.follows = "nixpkgs";

У nixosConfiguration (modules):
  inputs.mango.nixosModules.mango
  inputs.edots.nixosModules.edots
  { edots.enable = true; programs.mango.enable = true;
    services.displayManager.defaultSession = "mango"; }

У home-manager:
  inputs.edots.homeManagerModules.edots
  { edots.home.enable = true; }

Потім:  sudo nixos-rebuild switch --flake .#HOST

Деталі та відомі прогалини (SF Pro, AUR-only, snapd):  nix/README.md
EOF

  c_warn "НЕ запускай sync.sh на NixOS — симлінками керує home-manager (home.nix)."
  c_warn "AUR-only (quicksnip, anydesk, viber...) — вручну/flake; snapd на NixOS немає."
  c_warn "SF Pro Display — пропріетарний, постав вручну у ~/.local/share/fonts/"
  c_warn "  (або зміни appearance.uiFont/monoFont у Defaults.qml на наявний шрифт)."
}

# ════════════════════════ ARCH-BASED ════════════════════════
install_arch() {
  c_info "Виявлено Arch-based дистрибутив."
  sudo -v

  # ───────────────────────── pacman (офіційні репо) ─────────────────────────
  PACMAN_PKGS=(
    xdg-desktop-portal-wlr swayidle
    ttf-material-symbols-variable ttf-fira-code
    networkmanager network-manager-applet bluez bluez-utils blueman
    power-profiles-daemon wireplumber
    wl-clipboard brightnessctl iproute2 iputils slurp wf-recorder
    alacritty ghostty kitty nautilus dolphin firefox
    libnotify cpupower gamemode playerctl bc starship
    figlet inotify-tools flatpak python-pip
    vlc
    fish jq fastfetch neovim git ripgrep fd rofi tree curl
    imagemagick kdialog
  )

  c_info "Синхронізую бази pacman..."
  sudo pacman -Sy --noconfirm

  c_info "Ставлю пакети з офіційних репо (${#PACMAN_PKGS[@]} шт.)..."
  for pkg in "${PACMAN_PKGS[@]}"; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then continue; fi
    if sudo pacman -S --needed --noconfirm "$pkg"; then c_ok "$pkg"
    else c_warn "не вдалося: $pkg (pacman)"; FAILED+=("pacman:$pkg"); fi
  done

  # ───────────────────────── Google Sans Flex (GTK font, OSS) ─────────────────────────
  FONT_DIR="$HOME/.local/share/fonts"
  if [ ! -f "$FONT_DIR/GoogleSansFlex-Regular.ttf" ]; then
    c_info "Качаю Google Sans Flex..."
    mkdir -p "$FONT_DIR"
    if curl -fsSL -o "$FONT_DIR/GoogleSansFlex-Regular.ttf" \
      "https://raw.githubusercontent.com/LineageOS/android_external_google-fonts_google-sans-flex/lineage-23.2/GoogleSansFlex-Regular.ttf"; then
      fc-cache -f "$FONT_DIR" >/dev/null 2>&1
      c_ok "Google Sans Flex (Regular)"
      c_warn "  Це статична Regular-інстанція; для повних осей (wght/opsz) — variable TTF з fonts.google.com"
    else
      c_warn "Google Sans Flex не скачався — постав вручну"
      FAILED+=("font:google-sans-flex")
    fi
  fi

  # ───────────────────────── бутстрап yay ─────────────────────────
  if ! command -v yay >/dev/null 2>&1; then
    c_info "yay не знайдено — збираю з AUR..."
    sudo pacman -S --needed --noconfirm base-devel git
    tmpdir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" && \
      (cd "$tmpdir/yay" && makepkg -si --noconfirm) && \
      c_ok "yay встановлено" || { c_err "yay не зібрався"; FAILED+=("yay-bootstrap"); }
    rm -rf "$tmpdir"
  fi

  # ───────────────────────── AUR ─────────────────────────
  AUR_PKGS=(
    mangowc-git
    swaylock-effects-git
    quickshell
    ttf-jetbrains-mono-nerd
    swaync
    cliphist
    awww
    zen-browser-bin
    matugen
  )

  if command -v yay >/dev/null 2>&1; then
    c_info "Ставлю AUR-пакети (${#AUR_PKGS[@]} шт.)..."
    for pkg in "${AUR_PKGS[@]}"; do
      if pacman -Qi "$pkg" >/dev/null 2>&1; then continue; fi
      if yay -S --needed --noconfirm "$pkg"; then c_ok "$pkg"
      else c_warn "не вдалося: $pkg (AUR)"; FAILED+=("aur:$pkg"); fi
    done
  else
    c_warn "yay недоступний — пропускаю AUR: ${AUR_PKGS[*]}"
    FAILED+=("aur:усі (немає yay)")
  fi

  # ───────────────────────── rishot ─────────────────────────
  if ! command -v rishot >/dev/null 2>&1; then
    c_info "Ставлю rishot..."
    if curl -fsSL https://raw.githubusercontent.com/Gakuseei/rishot/main/install.sh | sh; then
      c_ok "rishot"
    else
      c_warn "rishot не встав — вручну: curl -fsSL https://raw.githubusercontent.com/Gakuseei/rishot/main/install.sh | sh"
      FAILED+=("rishot")
    fi
  fi

  # ───────────────────────── tui-player (venv) ─────────────────────────
  TUI_DIR="$REPO_DIR/edots/tui-player"
  if [ -d "$TUI_DIR" ]; then
    c_info "venv для tui-player..."
    python3 -m venv "$TUI_DIR/.venv" 2>/dev/null || sudo pacman -S --needed --noconfirm python
    if [ -d "$TUI_DIR/.venv" ]; then
      "$TUI_DIR/.venv/bin/pip" install --quiet --upgrade pip
      "$TUI_DIR/.venv/bin/pip" install --quiet textual python-vlc mutagen && \
        c_ok "tui-player venv" || { c_warn "pip (tui-player) не вдався"; FAILED+=("pip:tui-player"); }
    fi
  fi

  # ───────────────────────── pnpm ─────────────────────────
  if ! command -v pnpm >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    c_info "pnpm через npm..."
    sudo npm install -g pnpm >/dev/null 2>&1 && c_ok "pnpm" || { c_warn "pnpm не встав"; FAILED+=("npm:pnpm"); }
  fi

  # ───────────────────────── свідомі пропуски ─────────────────────────
  c_warn "SF Pro Display — пропріетарний, автоматично НЕ ставлю (опц.: yay -S otf-san-francisco)."
  c_warn "Курсор 'Moga-Black' — постав вручну, якщо треба."

  # ───────────────────────── sync.sh ─────────────────────────
  if [ -x "$REPO_DIR/sync.sh" ]; then
    c_info "Симлінкую конфіги через sync.sh install..."
    "$REPO_DIR/sync.sh" install
  else
    c_warn "sync.sh не знайдено — запусти симлінки вручну."
  fi
}

# ───────────────────────── dispatch ─────────────────────────
case "$OS" in
  nixos) install_nixos ;;
  arch)  install_arch ;;
  *)
    c_err "Непідтримуваний дистрибутив: немає ні /etc/os-release ID=nixos, ні pacman."
    c_err "Підтримуються: NixOS та Arch-based (Arch/EndeavourOS/Manjaro/CachyOS...)."
    exit 1
    ;;
esac

# ───────────────────────── підсумок ─────────────────────────
echo
if [ "${#FAILED[@]}" -eq 0 ]; then
  c_ok "Готово без помилок. Перелогінься (NixOS: nixos-rebuild switch) і насолоджуйся."
else
  c_warn "Завершено з ${#FAILED[@]} пропусками:"
  for f in "${FAILED[@]}"; do echo "    - $f"; done
  c_warn "Постав їх вручну."
fi
