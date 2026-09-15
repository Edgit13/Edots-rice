# rice.nix — ядро пакетів Edots (Wayland-стек rice, без десктопних додатків).
# Відібрано з install.sh + реальних runtime-залежностей бару/скриптів.
{ pkgs }:

{
  # --- Композитор та shell ---
  mango = [ pkgs.mangowc ];                 # або pkgs.mango-nightly через flake mango
  shell = [ pkgs.quickshell ];              # nixpkgs-unstable; для git-версії — flake input

  # --- Capture / OCR / Lens / запис (PillShell, Snap, QuickSnip) ---
  capture = [
    pkgs.grim
    pkgs.slurp
    pkgs.imagemagick            # `magick`
    pkgs.wl-clipboard           # wl-copy / wl-paste
    pkgs.wf-recorder
    (pkgs.tesseract.override { enableLanguages = [ "eng" "ukr" "rus" ]; })
    pkgs.libnotify              # notify-send
  ];

  # --- Поверхні пігулки ---
  barDeps = [
    pkgs.awww                   # wallpaper
    pkgs.matugen                # colors.json
    pkgs.cliphist
    pkgs.brightnessctl
    pkgs.playerctl
    pkgs.networkmanagerapplet   # nm-applet (tray)
    pkgs.blueman
    pkgs.swaync
    pkgs.swayidle
    pkgs.swaylock-effects       # AUR -git аналог є в nixpkgs
    pkgs.rofi
    pkgs.kitty                  # upkg / термінал у Task Manager
  ];

  # --- CLI/стиль rice ---
  cli = [
    pkgs.fish pkgs.starship pkgs.btop pkgs.fastfetch pkgs.cava
    pkgs.yazi pkgs.eza pkgs.bat pkgs.fzf pkgs.ripgrep pkgs.jq
    pkgs.git pkgs.gh pkgs.wget pkgs.unzip
  ];

  # --- Термінали/редактори rice (конфіги — file-based symlinks у home.nix) ---
  terms = [ pkgs.kitty pkgs.alacritty pkgs.ghostty pkgs.neovim ];

  # --- Шрифти ---
  fonts = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.material-symbols        # Material Symbols (іконки бару)
    pkgs.noto-fonts
    pkgs.noto-fonts-emoji
    pkgs.noto-fonts-cjk-sans
    pkgs.ttf-dejavu
    # SF Pro Display / SF Mono — НЕ у вільних репозиторіях (Apple).
    # Покласти вручну: ~/.local/share/fonts/  (див. README «Відомі прогалини»)
  ];
}
