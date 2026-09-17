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

# ── Конфлікти: [S]пропустити / [D]дописати / [П]ерезаписати ──
# Друкує рішення у stdout: skip | append | overwrite
ask_conflict() {
  local path="$1" a
  while true; do
    read -r -p "  '$path' вже існує — [S]пропустити / [D]дописати / [П]ерезаписати? [S/d/p]: " a
    case "$a" in
      [Dd]*)  echo "append"; return ;;
      [ПпPp]*) echo "overwrite"; return ;;
      [Ss]*|"") echo "skip"; return ;;
      *) c_warn "Введи s, d або p." ;;
    esac
  done
}

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
    elif [ -e "$WALLPAPERS_DIR" ]; then
      action=$(ask_conflict "$WALLPAPERS_DIR")
      case "$action" in
        overwrite)
          wp_backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
          mkdir -p "$wp_backup"
          mv "$WALLPAPERS_DIR" "$wp_backup/Wallpapers"
          c_warn "старі шпалери перенесено в $wp_backup/Wallpapers"
          mkdir -p "$(dirname "$WALLPAPERS_DIR")"
          git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR" && c_ok "шпалери склоновано"             || { c_warn "git clone шпалер не вдався"; FAILED+=("wallpapers:clone"); }
          ;;
        append)
          wp_tmp=$(mktemp -d)
          if git clone "$WALLPAPERS_REPO" "$wp_tmp/Wallpapers" 2>/dev/null; then
            cp -rn "$wp_tmp/Wallpapers/." "$WALLPAPERS_DIR/" && c_ok "дописано (нові файли, існуючі не чіпав)"
          else
            c_warn "git clone шпалер не вдався"; FAILED+=("wallpapers:clone")
          fi
          rm -rf "$wp_tmp"
          ;;
        *)
          c_info "Шпалери пропущено."
          ;;
      esac
    else
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

# Генерація nix/local-user.nix (юзер + групи + HM)
write_lunix() {
  cat > "$REPO_DIR/nix/local-user.nix" <<EOF
{ osConfig, lib, ... }:
{
  users.users.$USER = {
    isNormalUser = lib.mkDefault true;
    initialPassword = lib.mkDefault "edots";   # ПІСЛЯ ПЕРШОГО ВХОДУ: passwd
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" ];
  };

  home-manager.users.$USER = {
    imports = [ ./home.nix ];
    edots.home.enable = true;
    home.stateVersion = lib.mkDefault osConfig.system.stateVersion;
  };
}
EOF
}

# ════════════════════════ NIXOS ════════════════════════
# Генерація nix/local-user.nix (юзер + групи + HM)
write_lunix() {
  cat > "$REPO_DIR/nix/local-user.nix" <<EOF
{ osConfig, lib, ... }:
{
  users.users.$USER = {
    isNormalUser = lib.mkDefault true;
    initialPassword = lib.mkDefault "edots";   # ПІСЛЯ ПЕРШОГО ВХОДУ: passwd
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" ];
  };

  home-manager.users.$USER = {
    imports = [ ./home.nix ];
    edots.home.enable = true;
    home.stateVersion = lib.mkDefault osConfig.system.stateVersion;
  };
}
EOF
}

# Автоматична розмітка цілього диска + встановлення з rice.
nixos_auto_install() {
  echo
  c_warn "АВТО-УСТАНОВЛЕННЯ: вибраний диск буде ПОВНІСТЮ ЗНИЩЕНО (GPT: 1G ESP + решта ext4)."

  if [ ! -d /sys/firmware/efi ]; then
    c_err "Виявлено BIOS-завантаження. Авто-режим підтримує лише UEFI."
    c_err "Для GRUB/BIOS — пройди ручну установку (кроки нижче)."
    return 1
  fi

  # --- список дисків ---
  echo
  echo "Доступні диски:"
  lsblk -d -e 7,11 -o NAME,SIZE,MODEL | sed 's/^/  /'
  echo
  read -r -p "Введи ім'я цільового диска (напр. nvme0n1 або sda), або Enter — відміна: " DISK
  [ -n "$DISK" ] || { c_info "Відмінено."; return 1; }
  DISK="/dev/$DISK"
  [ -b "$DISK" ] || { c_err "$DISK не існує."; return 1; }

  # --- безпека: відмова, якщо хоч один розділ змонтований ---
  if lsblk -nr -o MOUNTPOINT "$DISK" | grep -qE '^/'; then
    c_err "На $DISK є змонтовані розділи — відмова (спочатку umount)."
    return 1
  fi

  # --- підтвердження введенням імені ---
  base=$(basename "$DISK")
  read -r -p "ПІДТВЕРДЖЕННЯ: введи ще раз '$base' для ЗНИЩЕННЯ всіх даних на ньому: " CONFIRM
  if [ "$CONFIRM" != "$base" ]; then
    c_info "Не збігається — відмінено."
    return 1
  fi

  command -v sgdisk >/dev/null 2>&1 || { c_err "sgdisk немає на образі — ручна установка."; return 1; }

  c_info "Розмітка $DISK (GPT: EFI 1G + root ext4)..."
  sudo sgdisk --zap-all "$DISK"
  sudo sgdisk -n1:0:+1G  -t1:ef00 -c1:"EFI" "$DISK"
  sudo sgdisk -n2:0:0     -t2:8300 -c2:"nixos" "$DISK"
  sudo partprobe "$DISK" 2>/dev/null || sleep 2

  # партиції: p1/p2 для nvme (nvme0n1p1), 1/2 для sata/sd (sda1)
  case "$DISK" in
    *[0-9]) P1="${DISK}p1"; P2="${DISK}p2" ;;
    *)      P1="${DISK}1";  P2="${DISK}2" ;;
  esac
  [ -b "$P1" ] || P1="${DISK}1"
  [ -b "$P2" ] || P2="${DISK}2"

  sudo mkfs.fat -F32 "$P1"
  sudo mkfs.ext4 -F "$P2"

  sudo mount "$P2" /mnt
  sudo mkdir -p /mnt/boot
  sudo mount "$P1" /mnt/boot

  c_info "Генерую конфігурацію встановлюваної системи..."
  sudo nixos-generate-config --root /mnt

  # systemd-boot (якщо користувач ще не обрав інший)
  if ! grep -qE '^\s*boot.loader.(grub|systemd-boot|efi).enable = true' /mnt/etc/nixos/configuration.nix; then
    sudo sed -i \
      -e 's/^# boot.loader.systemd-boot.enable = true;/boot.loader.systemd-boot.enable = true;/' \
      -e 's/^# boot.loader.efi.canTouchEfiVariables = true;/boot.loader.efi.canTouchEfiVariables = true;/' \
      /mnt/etc/nixos/configuration.nix
    c_ok "systemd-boot увімкнено у /mnt/etc/nixos/configuration.nix"
  fi

  c_info "Встановлення системи з rice (довго, качає inputs)..."
  if sudo EDOTS_HOST_ROOT=/mnt nixos-install --flake "$REPO_DIR/nix#edots" --impure; then
    c_ok "nixos-install: успіх"
  else
    c_err "nixos-install не вдався — лог вище."
    return 1
  fi

  echo
  c_ok "ГОТОВО. Після reboot: sddm → сесія MangoWM → логін: $USER / edots → одразу 'passwd'."
  read -r -p "Перезавантажити зараз? [y/N]: " rb
  case "$rb" in
    [Yy]*) sudo reboot ;;
    *) c_info "Перезавантажся сам: sudo reboot" ;;
  esac
  exit 0
}

install_nixos() {
  c_info "Виявлено NixOS."
  command -v nix >/dev/null 2>&1 || { c_err "nix не знайдено у PATH."; exit 1; }
  sudo -v

  # 1. Flakes
  if ! nix show-config 2>/dev/null | grep -qE 'experimental-features.*flakes'; then
    c_info "Вмикаю flakes (experimental-features)..."
    printf 'extra-experimental-features = nix-command flakes\n' | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon 2>/dev/null || true
  fi

  # 2. Система вже на flakes — не ліземо
  if [ -f /etc/nixos/flake.nix ]; then
    cat << 'EOF2'
─────────────────────────────────────────────────────────────
/etc/nixos/flake.nix ВЖЕ ІСНУЄ — автовпровадження небезпечне.

Додай у свій flake вручну:
  inputs.edots.url = "path:~/Dotfiles";   # або github:Edgit13/Edots-rice
  inputs.edots.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mango.url = "github:mangowm/mango";
  inputs.mango.inputs.nixpkgs.follows = "nixpkgs";

modules: inputs.mango.nixosModules.mango, inputs.edots.nixosModules.edots,
  { edots.enable = true; programs.mango.enable = true;
    services.displayManager.defaultSession = "mango";
    home-manager.useUserPackages = true;
    home-manager.users.YOU = { imports = [ inputs.edots.homeManagerModules.edots ]; edots.home.enable = true; }; }

Потім: sudo nixos-rebuild switch --flake .#HOST
─────────────────────────────────────────────────────────────
EOF2
    exit 0
  fi

  # 3. Встановлена система чи live CD?
  if [ -f /etc/nixos/hardware-configuration.nix ] \
     && grep -q 'fileSystems."/"' /etc/nixos/configuration.nix 2>/dev/null; then
    MODE="rebuild"   # звичайна встановлена система
  else
    echo
    echo "Схоже на live CD / не налаштований хост."
    echo "  [a] — АВТО: розмітити диск + встановити NixOS з rice"
    echo "  [m] — вручну (друкую кроки)"
    echo "  [s] — скіп (спробувати rebuild live-сесії)"
    read -r -p "Вибір [a/m/s]: " m
    case "$m" in
      [Aa]*) MODE="install" ;;
      [Mm]*)
        cat << 'EOF3'
Ручна установка:
  1) sudo cfdisk /dev/<disk>   # GPT: EFI ~1G + root
  2) sudo mkfs.fat -F32 <ESP> && sudo mkfs.ext4 <root>
  3) sudo mount <root> /mnt && sudo mkdir -p /mnt/boot && sudo mount <ESP> /mnt/boot
  4) sudo nixos-generate-config --root /mnt
  5) відредагуй /mnt/etc/nixos/configuration.nix (boot.loader...)
  6) sudo EDOTS_HOST_ROOT=/mnt nixos-install --flake <repo>/nix#edots --impure
EOF3
        exit 0 ;;
      *) MODE="rebuild" ;;
    esac
  fi

  # 4. local-user.nix (спільне)
  LUNIX="$REPO_DIR/nix/local-user.nix"
  if [ -f "$LUNIX" ]; then
    action=$(ask_conflict "nix/local-user.nix")
    case "$action" in
      skip) c_info "local-user.nix не чіпаю." ;;
      append)
        printf '\n  # додано install.sh %s\n  home-manager.users.%s = {\n    imports = [ ./home.nix ];\n    edots.home.enable = true;\n  };\n' "$(date +%F)" "$USER" >> "$LUNIX"
        c_ok "local-user.nix дописано" ;;
      *)
        mv "$LUNIX" "$LUNIX.bak-$(date +%Y%m%d-%H%M%S)"
        write_lunix ;;
    esac
  else
    write_lunix
  fi
  grep -q 'nix/local-user.nix' "$REPO_DIR/.gitignore" 2>/dev/null || \
    echo 'nix/local-user.nix' >> "$REPO_DIR/.gitignore"
  c_ok "nix/local-user.nix -> юзер $USER"

  # 5. Режим
  if [ "$MODE" = "install" ]; then
    nixos_auto_install   # всередині: розмітка→mount→generate→nixos-install→reboot
    exit $?              # якщо auto повернув помилку/відміну — вихід
  fi

  # 5b. Rebuild (встановлена система або свідомий live-скіп)
  c_info "Збираю: nixos-rebuild switch --flake $REPO_DIR/nix#edots..."
  if sudo nixos-rebuild switch --flake "$REPO_DIR/nix#edots" --impure; then
    c_ok "nixos-rebuild: успіх"
  else
    c_err "nixos-rebuild не вдався. Якщо це live CD — це нормально без дисків;"
    c_err "для установки запусти інсталлер і обери [a]."
    exit 1
  fi

  echo
  c_ok "ГОТОВО. MangoWM-сесія за замовчуванням; бар — edots-bar (explicit -p)."
  c_warn "Якщо у mango/autostart.conf є ручний запуск qs — прибери (дві інстанції)."
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
