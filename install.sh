#!/usr/bin/env bash
#
# install.sh — повний бутстрап Edots-rice.
#
# Adaptive to the OS:
#   * NixOS                  -> validate nix/ flake, print integration steps,
#                               optionally run the auto-installer.
#   * Arch-based (Arch/EndeavourOS/Manjaro/CachyOS/...) -> pacman + yay + sync.sh.
#
# Usage:
#   git clone https://github.com/Edgit13/Edots-rice.git ~/Dotfiles
#   cd ~/Dotfiles && ./install.sh
#
# Flags:
#   --auto              no questions
#   --disk=<dev>        target disk for NixOS auto-install
#   --user=<name>       user to create (NixOS)
#   --password=<pass>   initial password (NixOS)
#
set -uo pipefail

REPO_URL="https://github.com/Edgit13/Edots-rice.git"
REPO_DIR="${EDOTS_DIR:-$HOME/Dotfiles}"

# ── Flags ──
AUTO=0
DISK_ARG=""
USER_NAME="${USER:-user}"
USER_PASS="edots"
for a in "$@"; do
  case "$a" in
    --auto)       AUTO=1 ;;
    --disk=*)     DISK_ARG="${a#--disk=}" ;;
    --user=*)     USER_NAME="${a#--user=}" ;;
    --password=*) USER_PASS="${a#--password=}" ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--auto] [--disk=nvme0n1] [--user=name] [--password=pass]

  --auto           skip every prompt
  --disk=<dev>     target disk for the NixOS auto-installer
  --user=<name>    initial user name (NixOS)
  --password=<p>   initial password (NixOS)

Env fallbacks:
  EDOTS_AUTO=1 EDOTS_DISK=sda EDOTS_USER=eduard EDOTS_PASSWORD=xxx $0
EOF
      exit 0 ;;
  esac
done
[ "${EDOTS_AUTO:-0}" = "1" ]      && AUTO=1
[ -n "${EDOTS_DISK:-}" ]          && DISK_ARG="$EDOTS_DISK"
[ -n "${EDOTS_USER:-}" ]          && USER_NAME="$EDOTS_USER"
[ -n "${EDOTS_PASSWORD:-}" ]      && USER_PASS="$EDOTS_PASSWORD"

# ─────────────────────────── logging ────────────────────────────
c_info() { printf '\033[36m[i]\033[0m %s\n' "$*"; }
c_warn() { printf '\033[33m[!]\033[0m %s\n' "$*"; }
c_err()  { printf '\033[31m[x]\033[0m %s\n' "$*"; }
c_ok()   { printf '\033[32m[✓]\033[0m %s\n' "$*"; }

FAILED=()

# ── Conflict resolution: [S]kip / [A]ppend / [O]verwrite ──
ask_conflict() {
  local path="$1" default="${2:-skip}" a
  if [ "$AUTO" = "1" ]; then echo "$default"; return; fi
  while true; do
    read -r -p "  '$path' exists — [S]kip / [A]ppend / [O]verwrite? [S/a/o]: " a
    case "$a" in
      [Aa]*)  echo "append";    return ;;
      [Oo]*)  echo "overwrite"; return ;;
      [Ss]*|"") echo "skip";    return ;;
      *) c_warn "Enter s, a or o." ;;
    esac
  done
}

# ───────────────────── OS detection ─────────────────────
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
  c_err "Do not run as root — the script will ask for sudo when it needs it."
  exit 1
fi

# ───────────────────── wallpapers (shared across OSes) ─────────────────────
WALLPAPERS_REPO="https://github.com/Edgit13/Edot-Wallpapers.git"
WALLPAPERS_DIR="$HOME/Pictures/Wallpapers"

echo
echo "Wallpapers live in a separate repo: $WALLPAPERS_REPO"
echo "If you agree, they will be cloned to: $WALLPAPERS_DIR"
if [ "$AUTO" = "1" ]; then wp_answer="y"; else
  read -r -p "Install wallpapers? [y/N]: " wp_answer
fi
case "$wp_answer" in
  [Yy]*)
    if [ -d "$WALLPAPERS_DIR/.git" ]; then
      c_info "Wallpaper repo exists — pulling..."
      if git -C "$WALLPAPERS_DIR" pull --ff-only; then c_ok "wallpapers updated"
      else c_warn "git pull failed"; FAILED+=("wallpapers:pull"); fi
    elif [ -e "$WALLPAPERS_DIR" ]; then
      action=$(ask_conflict "$WALLPAPERS_DIR" skip)
      case "$action" in
        overwrite)
          wp_backup="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
          mkdir -p "$wp_backup"
          mv "$WALLPAPERS_DIR" "$wp_backup/Wallpapers"
          c_warn "old wallpapers moved to $wp_backup/Wallpapers"
          mkdir -p "$(dirname "$WALLPAPERS_DIR")"
          git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR" && c_ok "wallpapers cloned" \
            || { c_warn "git clone failed"; FAILED+=("wallpapers:clone"); }
          ;;
        append)
          wp_tmp=$(mktemp -d)
          if git clone "$WALLPAPERS_REPO" "$wp_tmp/Wallpapers" 2>/dev/null; then
            cp -rn "$wp_tmp/Wallpapers/." "$WALLPAPERS_DIR/" && c_ok "added new files"
          else
            c_warn "git clone failed"; FAILED+=("wallpapers:clone")
          fi
          rm -rf "$wp_tmp"
          ;;
        *) c_info "Wallpapers skipped." ;;
      esac
    else
      mkdir -p "$(dirname "$WALLPAPERS_DIR")"
      c_info "Cloning wallpapers..."
      if git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR"; then c_ok "wallpapers cloned"
      else c_warn "git clone failed"; FAILED+=("wallpapers:clone"); fi
    fi
    ;;
  *) c_info "Skipping wallpapers (later: git clone $WALLPAPERS_REPO $WALLPAPERS_DIR)." ;;
esac

# ───────────────────── repo clone ─────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  c_info "Repo already exists at $REPO_DIR — skipping clone."
elif [ -d "$REPO_DIR" ]; then
  action=$(ask_conflict "$REPO_DIR" skip)
  case "$action" in
    overwrite)
      repo_backup="$REPO_DIR.bak-$(date +%Y%m%d-%H%M%S)"
      mv "$REPO_DIR" "$repo_backup"
      c_warn "old $REPO_DIR moved to $repo_backup"
      git clone "$REPO_URL" "$REPO_DIR" || { c_err "git clone failed"; exit 1; }
      ;;
    append)
      c_info "Using existing $REPO_DIR as-is."
      ;;
    *)
      c_err "Clone skipped — cannot continue without the repo."
      exit 1
      ;;
  esac
else
  c_info "Cloning into $REPO_DIR..."
  git clone "$REPO_URL" "$REPO_DIR" || { c_err "git clone failed"; exit 1; }
fi
cd "$REPO_DIR" || exit 1

# Generate nix/local-user.nix (user + groups + Home-Manager)
write_lunix() {
  cat > "$REPO_DIR/nix/local-user.nix" <<EOF
{ osConfig, lib, ... }:
{
  users.users.$USER_NAME = {
    isNormalUser = lib.mkDefault true;
    initialPassword = lib.mkDefault "$USER_PASS";   # RUN `passwd` AFTER FIRST LOGIN
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "input" ];
  };

  home-manager.users.$USER_NAME = {
    imports = [ ./home.nix ];
    edots.home.enable = true;
    home.stateVersion = lib.mkDefault osConfig.system.stateVersion;
  };
}
EOF
}

# ════════════════════════ NIXOS ════════════════════════
nixos_auto_install() {
  echo
  c_warn "AUTO-INSTALL: the chosen disk will be WIPED (GPT: 1G ESP + ext4 root)."

  if [ ! -d /sys/firmware/efi ]; then
    c_err "BIOS boot detected. Auto mode only supports UEFI."
    c_err "For GRUB/BIOS — do the manual install (steps below)."
    return 1
  fi

  echo
  echo "Available disks:"
  lsblk -d -e 7,11 -o NAME,SIZE,MODEL | awk 'NR==1{print "  "$0; next}{print "  /dev/"$1"  "$2"  "$3}'
  echo
  if [ -n "$DISK_ARG" ]; then
    DISK="$DISK_ARG"
  elif [ "$AUTO" = "1" ]; then
    mapfile -t CAND < <(lsblk -d -n -e 7,11 -o NAME)
    if [ "${#CAND[@]}" -eq 1 ]; then
      c_warn "AUTO: single disk ${CAND[0]} chosen — WIPING in 5s (Ctrl+C to cancel)!"
      sleep 5
      DISK="${CAND[0]}"
    else
      c_err "AUTO: multiple disks — pass: $0 --auto --disk=<name>"
      return 1
    fi
  else
    read -r -p "Target disk (e.g. nvme0n1 or sda), Enter to cancel: " DISK
    [ -n "$DISK" ] || { c_info "Cancelled."; return 1; }
  fi
  case "$DISK" in /dev/*) ;; *) DISK="/dev/$DISK" ;; esac
  if [ ! -b "$DISK" ]; then
    nm="${DISK#/dev/}"
    for alt in "v$nm" "u$nm" "s$nm" "nvme${nm}n1" "${nm}n1"; do
      if [ "$alt" != "$nm" ] && [ -b "/dev/$alt" ]; then
        c_warn "'$nm' does not exist — using '/dev/$alt'."
        DISK="/dev/$alt"; break
      fi
    done
  fi
  if [ ! -b "$DISK" ]; then
    c_err "'$DISK' does not exist. Real disks:"
    lsblk -d -e 7,11 -o NAME,SIZE,MODEL | sed 's/^/    /'
    return 1
  fi

  if lsblk -nr -o MOUNTPOINT "$DISK" | grep -qE '^/'; then
    c_err "$DISK has mounted partitions — refusing (umount first)."
    return 1
  fi

  base=$(basename "$DISK")
  if [ "$AUTO" = "1" ]; then
    c_warn "AUTO: $base will be WIPED. Continuing..."
    sleep 2
  else
    read -r -p "CONFIRM: type '$base' again to WIPE all data: " CONFIRM
    if [ "$CONFIRM" != "$base" ]; then c_info "Mismatch — cancelled."; return 1; fi
  fi

  command -v sgdisk >/dev/null 2>&1 || { c_err "sgdisk missing — do manual install."; return 1; }

  c_info "Partitioning $DISK (GPT: EFI 1G + ext4 root)..."
  sudo sgdisk --zap-all "$DISK"
  sudo sgdisk -n1:0:+1G -t1:ef00 -c1:"EFI" "$DISK"
  sudo sgdisk -n2:0:0    -t2:8300 -c2:"nixos" "$DISK"
  sudo partprobe "$DISK" 2>/dev/null || sleep 2

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

  c_info "Generating installed-system config..."
  sudo nixos-generate-config --root /mnt

  if ! grep -qE '^\s*boot.loader.(grub|systemd-boot|efi).enable = true' /mnt/etc/nixos/configuration.nix; then
    sudo sed -i \
      -e 's/^# boot.loader.systemd-boot.enable = true;/boot.loader.systemd-boot.enable = true;/' \
      -e 's/^# boot.loader.efi.canTouchEfiVariables = true;/boot.loader.efi.canTouchEfiVariables = true;/' \
      /mnt/etc/nixos/configuration.nix
    c_ok "systemd-boot enabled in /mnt/etc/nixos/configuration.nix"
  fi

  c_info "Installing with the rice (this takes a while, downloads inputs)..."
  if sudo env "NIX_CONFIG=$NIX_CONFIG" EDOTS_HOST_ROOT=/mnt \
        nixos-install --flake "$REPO_DIR/nix#edots" --impure; then
    c_ok "nixos-install: success"
  else
    c_err "nixos-install failed — see log above."
    return 1
  fi

  echo
  c_ok "DONE. After reboot: sddm → MangoWM session → login: $USER / edots → run 'passwd' first."
  if [ "$AUTO" = "1" ]; then
    c_warn "AUTO: rebooting in 5 seconds..."
    sleep 5
    sudo reboot
  fi
  read -r -p "Reboot now? [y/N]: " rb
  case "$rb" in
    [Yy]*) sudo reboot ;;
    *) c_info "Reboot later: sudo reboot" ;;
  esac
  exit 0
}

install_nixos() {
  c_info "Detected NixOS."
  command -v nix >/dev/null 2>&1 || { c_err "nix not in PATH."; exit 1; }
  sudo -v

  export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG
}extra-experimental-features = nix-command flakes"
  if ! nix show-config 2>/dev/null | grep -qE 'experimental-features.*flakes' \
     && [ -w /etc/nix ] && [ ! -L /etc/nix/nix.conf ]; then
    c_info "Trying to enable flakes in /etc/nix/nix.conf..."
    printf 'extra-experimental-features = nix-command flakes\n' | sudo tee -a /etc/nix/nix.conf >/dev/null 2>&1 \
      && sudo systemctl restart nix-daemon 2>/dev/null || true
  fi
  c_ok "flakes: NIX_CONFIG (env) active"

  if [ -f /etc/nixos/flake.nix ]; then
    cat << 'EOF2'
─────────────────────────────────────────────────────────────
/etc/nixos/flake.nix ALREADY EXISTS — auto-integration is unsafe.

Add to your flake manually:
  inputs.edots.url = "path:~/Dotfiles";
  inputs.edots.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mango.url = "github:mangowm/mango";
  inputs.mango.inputs.nixpkgs.follows = "nixpkgs";

  modules: inputs.mango.nixosModules.mango, inputs.edots.nixosModules.edots,
    { edots.enable = true; programs.mango.enable = true;
      services.displayManager.defaultSession = "mango";
      home-manager.useUserPackages = true;
      home-manager.users.YOU = { imports = [ inputs.edots.homeManagerModules.edots ]; edots.home.enable = true; }; }

Then: sudo nixos-rebuild switch --flake .#HOST
─────────────────────────────────────────────────────────────
EOF2
    exit 0
  fi

  if [ -f /etc/nixos/hardware-configuration.nix ] \
     && grep -q 'fileSystems."/"' /etc/nixos/configuration.nix 2>/dev/null; then
    MODE="rebuild"
  else
    echo
    echo "Looks like a live CD / unconfigured host."
    echo "  [a] — AUTO: partition disk + install NixOS with the rice"
    echo "  [m] — MANUAL (print steps)"
    echo "  [s] — SKIP (attempt live-session rebuild)"
    if [ "$AUTO" = "1" ]; then
      MODE="install"
      c_warn "AUTO: chose install mode [a]."
    else
      read -r -p "Choice [a/m/s]: " m
      case "$m" in
        [Aa]*) MODE="install" ;;
        [Mm]*)
          cat << 'EOF3'
Manual install:
  1) sudo cfdisk /dev/<disk>   # GPT: EFI ~1G + root
  2) sudo mkfs.fat -F32 <ESP> && sudo mkfs.ext4 <root>
  3) sudo mount <root> /mnt && sudo mkdir -p /mnt/boot && sudo mount <ESP> /mnt/boot
  4) sudo nixos-generate-config --root /mnt
  5) edit /mnt/etc/nixos/configuration.nix (boot.loader...)
  6) sudo EDOTS_HOST_ROOT=/mnt nixos-install --flake <repo>/nix#edots --impure
EOF3
          exit 0 ;;
        *) MODE="rebuild" ;;
      esac
    fi
  fi

  LUNIX="$REPO_DIR/nix/local-user.nix"
  if [ -f "$LUNIX" ]; then
    action=$(ask_conflict "nix/local-user.nix" overwrite)
    case "$action" in
      skip) c_info "local-user.nix kept as-is." ;;
      append)
        printf '\n  # added by install.sh %s\n  home-manager.users.%s = {\n    imports = [ ./home.nix ];\n    edots.home.enable = true;\n  };\n' "$(date +%F)" "$USER_NAME" >> "$LUNIX"
        c_ok "local-user.nix appended" ;;
      *)
        mv "$LUNIX" "$LUNIX.bak-$(date +%Y%m%d-%H%M%S)"
        write_lunix ;;
    esac
  else
    write_lunix
  fi
  grep -q 'nix/local-user.nix' "$REPO_DIR/.gitignore" 2>/dev/null || \
    echo 'nix/local-user.nix' >> "$REPO_DIR/.gitignore"
  c_ok "nix/local-user.nix -> user $USER_NAME"

  if [ "$MODE" = "install" ]; then
    nixos_auto_install
    exit $?
  fi

  c_info "Building: nixos-rebuild switch --flake $REPO_DIR/nix#edots..."
  if sudo env "NIX_CONFIG=$NIX_CONFIG" \
        nixos-rebuild switch --flake "$REPO_DIR/nix#edots" --impure; then
    c_ok "nixos-rebuild: success"
  else
    c_err "nixos-rebuild failed. On a live CD that is expected without a target disk;"
    c_err "run the installer and choose [a]."
    exit 1
  fi

  echo
  c_ok "DONE. MangoWM is the default session; the bar is edots-bar (explicit -p)."
  c_warn "If mango/autostart.conf has a manual qs launch — remove it (two instances)."
}

# ════════════════════════ ARCH-BASED ════════════════════════
install_arch() {
  c_info "Detected Arch-based distribution."
  sudo -v

  # ───────────────────── pacman (official repos) ─────────────────────
  PACMAN_PKGS=(
    # Wayland / compositor
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-utils
    swayidle wlr-randr
    # Fonts
    ttf-material-symbols-variable ttf-fira-code ttf-jetbrains-mono
    # Networking / bluetooth
    networkmanager network-manager-applet bluez bluez-utils blueman polkit
    # Power / audio
    power-profiles-daemon wireplumber pipewire pipewire-pulse pipewire-alsa
    upower
    # Wayland utils
    wl-clipboard brightnessctl iproute2 iputils slurp grim wf-recorder
    imagemagick
    # Apps
    alacritty ghostty kitty nautilus dolphin firefox
    libnotify cpupower gamemode playerctl bc starship
    figlet inotify-tools flatpak python python-pip
    vlc vlc-plugins-all
    # Shell / dev tools
    fish jq fastfetch neovim git ripgrep fd rofi tree curl
    kdialog
    # PAM headers for lockscreen/pam-auth.c
    gcc pam
    # Notifications + clipboard history
    swaync cliphist
    # OCR (QuickSnip)
    tesseract tesseract-data-eng
  )

  c_info "Syncing pacman databases..."
  sudo pacman -Sy --noconfirm

  c_info "Installing official packages (${#PACMAN_PKGS[@]})..."
  for pkg in "${PACMAN_PKGS[@]}"; do
    if pacman -Qi "$pkg" >/dev/null 2>&1; then continue; fi
    if sudo pacman -S --needed --noconfirm "$pkg"; then c_ok "$pkg"
    else c_warn "failed: $pkg (pacman)"; FAILED+=("pacman:$pkg"); fi
  done

  # ───────────────────── Google Sans Flex (GTK UI font) ─────────────────────
  FONT_DIR="$HOME/.local/share/fonts"
  if [ ! -f "$FONT_DIR/GoogleSansFlex-Regular.ttf" ]; then
    c_info "Downloading Google Sans Flex..."
    mkdir -p "$FONT_DIR"
    if curl -fsSL -o "$FONT_DIR/GoogleSansFlex-Regular.ttf" \
      "https://raw.githubusercontent.com/LineageOS/android_external_google-fonts_google-sans-flex/lineage-23.2/GoogleSansFlex-Regular.ttf"; then
      fc-cache -f "$FONT_DIR" >/dev/null 2>&1
      c_ok "Google Sans Flex (Regular)"
      c_warn "  This is a static Regular instance; for full axes get the variable TTF from fonts.google.com"
    else
      c_warn "Google Sans Flex download failed — install manually"
      FAILED+=("font:google-sans-flex")
    fi
  fi

  # ───────────────────── yay bootstrap ─────────────────────
  if ! command -v yay >/dev/null 2>&1; then
    c_info "yay not found — building from AUR..."
    sudo pacman -S --needed --noconfirm base-devel git
    tmpdir=$(mktemp -d)
    if git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" && \
       (cd "$tmpdir/yay" && makepkg -si --noconfirm); then
      c_ok "yay installed"
    else
      c_err "yay build failed"; FAILED+=("yay-bootstrap")
    fi
    rm -rf "$tmpdir"
  fi

  # ───────────────────── AUR ─────────────────────
  AUR_PKGS=(
    mangowc-git
    quickshell
    ttf-jetbrains-mono-nerd
    awww
    zen-browser-bin
    matugen
    tesseract-data-ukr
    tesseract-data-rus
  )

  if command -v yay >/dev/null 2>&1; then
    c_info "Installing AUR packages (${#AUR_PKGS[@]})..."
    for pkg in "${AUR_PKGS[@]}"; do
      if pacman -Qi "$pkg" >/dev/null 2>&1; then continue; fi
      if yay -S --needed --noconfirm "$pkg"; then c_ok "$pkg"
      else c_warn "failed: $pkg (AUR)"; FAILED+=("aur:$pkg"); fi
    done
  else
    c_warn "yay unavailable — skipping AUR: ${AUR_PKGS[*]}"
    FAILED+=("aur:all (no yay)")
  fi

  # ───────────────────── Edots QuickSnip (capture) ─────────────────────
  # rishot is replaced by QuickSnip, which ships inside the rice.
  # No external installer needed — just make sure the QML config is present.
  if [ -d "$REPO_DIR/quickshell/QuickSnip" ]; then
    c_ok "QuickSnip present (part of the rice)"
  else
    c_warn "quickshell/QuickSnip missing — capture bind will not work"
    FAILED+=("quicksnip:missing")
  fi

  # ───────────────────── tui-player venv ─────────────────────
  TUI_DIR="$REPO_DIR/edots/tui-player"
  if [ -d "$TUI_DIR" ]; then
    c_info "venv for tui-player..."
    python3 -m venv "$TUI_DIR/.venv" 2>/dev/null || sudo pacman -S --needed --noconfirm python
    if [ -d "$TUI_DIR/.venv" ]; then
      "$TUI_DIR/.venv/bin/pip" install --quiet --upgrade pip
      "$TUI_DIR/.venv/bin/pip" install --quiet textual python-vlc mutagen && \
        c_ok "tui-player venv" || { c_warn "pip (tui-player) failed"; FAILED+=("pip:tui-player"); }
    fi
  fi

  # ───────────────────── pnpm ─────────────────────
  if ! command -v pnpm >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    c_info "pnpm via npm..."
    sudo npm install -g pnpm >/dev/null 2>&1 && c_ok "pnpm" || { c_warn "pnpm failed"; FAILED+=("npm:pnpm"); }
  fi

  # ───────────────────── explicit skips ─────────────────────
  c_warn "SF Pro Display — proprietary, not installed automatically (optional: yay -S otf-san-francisco)."
  c_warn "Cursor 'Moga-Black' — install manually if you want it."

  # ───────────────────── compile pam-auth for the lock screen ─────────────────────
  PAM_SRC="$REPO_DIR/quickshell/lockscreen/pam-auth.c"
  PAM_BIN="$REPO_DIR/quickshell/lockscreen/pam-auth"
  if [ -f "$PAM_SRC" ]; then
    c_info "Compiling lockscreen/pam-auth..."
    if cc -O2 -o "$PAM_BIN" "$PAM_SRC" -lpam; then
      chmod +x "$PAM_BIN"
      c_ok "pam-auth compiled"
    else
      c_warn "pam-auth compile failed (need gcc + pam headers)"
      FAILED+=("pam-auth")
    fi
  fi

  # ───────────────────── sync.sh install (symlinks) ─────────────────────
  if [ -x "$REPO_DIR/sync.sh" ]; then
    c_info "Symlinking configs via sync.sh install..."
    "$REPO_DIR/sync.sh" install
  else
    c_warn "sync.sh not found or not executable — link configs manually."
  fi

  # ───────────────────── systemd user services ─────────────────────
  mkdir -p "$HOME/.config/systemd/user"
  systemctl --user daemon-reload || true

  for unit in swayidle edots-lockscreen; do
    if [ -f "$HOME/.config/systemd/user/$unit.service" ]; then
      if systemctl --user enable --now "$unit.service"; then
        c_ok "$unit.service enabled + started"
      else
        c_warn "$unit.service failed to enable"; FAILED+=("systemd:$unit")
      fi
    else
      c_warn "$unit.service missing (sync.sh should have linked it)"
      FAILED+=("systemd:missing:$unit")
    fi
  done

  # ───────────────────── enable initial colour generation ─────────────────────
  if command -v python3 >/dev/null; then
    wp=$(find "$HOME/Pictures/Wallpapers" -type f \
         \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
         2>/dev/null | head -n 1)
    if [ -n "${wp:-}" ]; then
      c_info "Generating palette from $wp ..."
      python3 "$REPO_DIR/mango/scripts/wallcolors.py" "$wp" \
        && c_ok "palette generated" \
        || { c_warn "wallcolors.py failed"; FAILED+=("wallcolors"); }
    else
      c_warn "no wallpapers found — palette not generated"
    fi
  fi
}

# ───────────────────── dispatch ─────────────────────
case "$OS" in
  nixos) install_nixos ;;
  arch)  install_arch ;;
  *)
    c_err "Unsupported distribution: neither /etc/os-release ID=nixos nor pacman found."
    c_err "Supported: NixOS and Arch-based (Arch/EndeavourOS/Manjaro/CachyOS/...)."
    exit 1
    ;;
esac

# ───────────────────── summary ─────────────────────
echo
if [ "${#FAILED[@]}" -eq 0 ]; then
  c_ok "All done, no errors. Relogin and enjoy."
else
  c_warn "Finished with ${#FAILED[@]} skipped items:"
  for f in "${FAILED[@]}"; do echo "    - $f"; done
  c_warn "Install those manually."
fi

echo
echo "─────────────────────────────────────────────────────"
echo "Next steps:"
echo "  1. Relogin (so fish/swayidle/systemd pick up the environment)."
echo "  2. Bar:      qs -p ~/.config/quickshell/bar/shell.qml"
echo "  3. Settings: qs ipc call settings-launch toggle    (after the bar is up)"
echo "  4. Lock:     bash ~/.config/quickshell/lockscreen/lock.sh"
echo "  5. Idle/suspend: systemctl --user status swayidle.service"
echo "─────────────────────────────────────────────────────"
