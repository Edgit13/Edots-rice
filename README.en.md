# Edots

A minimal, fully-themed **MangoWM** + **Quickshell** rice.
**[Українська версія](README.md)**

![Edots](screenshots/banner.png)

| Dashboard | Lock screen |
|---|---|
| ![Dashboard](screenshots/dashboard.png) | ![Lock screen](screenshots/lockscreen.png) |

## Features

### Shell (Quickshell)
- **Material 3 bar** — a pill that morphs into surfaces: launcher, wallpapers,
  media, mixer, clipboard, Wi-Fi, power, notifications, settings
- **Dashboard** (Super+D) — clock, volume (Pipewire), brightness, battery,
  quick toggles, swaync, calendar
- **Task Manager** (Super+T) — folder-based tasks (`edots/task-manager/core.py`),
  `utimer`, `upkg`
- **M3 lock screen** — a custom Quickshell lock screen with an animated password
  field, shape-morphing dots, ken burns, parallax, power menu
- **Material 3 Settings** (Super+A) — standalone window with live controls:
  - pages: Appearance, Colors, Bar, Lock screen, Animations, Presets, System, About
  - **search** across every category
  - every control has a ↺ reset-to-default
  - all changes are live, no restart, persisted to `~/.config/quickshell/*.json`
- **Animations everywhere** — global switch + speed multiplier
- **Modules from the UI** — toggle and reorder bar modules from Settings
- **Panel position** top/bottom/left/right

### Colors
- **wallcolors.py** (matugen) derives one palette from the wallpaper and
  distributes it to:
  - `~/.config/quickshell/colors.json` → bar, lockscreen, settings
  - `~/.config/{kitty,ghostty,gtk-3.0,gtk-4.0,rofi,swaync,fish}/…`
  - `~/.config/firefox-colors.css`, `~/.config/kdeglobals`, swaylock
- Wallpaper change → the whole system recolors instantly

### Session
- **Lock** (Super+L) — M3 lock screen
- **Suspend** (Super+F3) — lock-then-suspend via logind
- **Idle** — `swayidle` as a systemd user service; lock after 5 min, DPMS off after 10

## Structure

```
quickshell/               # rice runtime
├── bar/                  # bar shell
│   ├── shell.qml         # entry
│   ├── Config.qml Defaults.qml Presets.qml  # settings backend
│   ├── Anim.qml Colors.qml Md.qml
│   ├── dashboard/        # Dashboard widgets
│   ├── modules/          # per-monitor bar modules
│   ├── services/         # MangoService, WifiService, WeatherService, ClockSettings, PerformanceService
│   ├── shell/            # BarWindow, MorphSurface, ShellState, SurfaceOverlay
│   ├── theme/            # Theme tokens (colors, typography, motion, shapes, …)
│   └── tools/            # mango-probe.sh
├── lockscreen/           # M3 lock screen + pam-auth + systemd hooks
├── material/             # shared M3 component library
├── settings/             # standalone Settings UI (M3)
└── scripts/              # gamemode.sh, modernmode.sh, pilldesign.sh

mango/                    # MangoWM config
├── config.conf           # sources the fragments below
├── binds.conf autostart.conf animations.conf decorations.conf
├── env.conf input.conf layout.conf monitors.conf rules.conf swayidle.conf
├── colors.json           # live palette (generated)
└── scripts/
    ├── wallcolors.py     # the palette pipeline
    └── lock.sh swaylock-*.sh

edots/                    # CLI ecosystem
├── bin/edot-i18.py       # settings.edot parser
├── task-manager/core.py  # folder-based tasks
├── tui-player/           # TUI + daemon music player
├── tool-manager/         # upkg, utimer
└── run.sh autostart.sh update.sh backup.sh

systemd/                  # user units (symlinked by sync.sh)
├── swayidle.service
└── edots-lockscreen.service

fish/ ghostty/ kitty/ gtk-3.0/ gtk-4.0/ firefox/ rofi/ swaync/ nvim/
install.sh                # bootstrap
sync.sh                   # symlink manager
```

## Requirements

- **Quickshell** (with Io/Wayland/Services/Networking/UPower/Pipewire/Mpris)
- **MangoWM** (`mangowc-git`)
- Fonts: `SF Pro Display` (proprietary, optional), `SF Mono`,
  `JetBrainsMono Nerd Font`, `Material Symbols Rounded`, `Google Sans Flex`
- Binaries: `matugen`, `awww`, `cliphist`, `swaync-client`, `brightnessctl`,
  `nmcli`, `rfkill`, `playerctl`, `grim`, `tesseract`, `python3`, `jq`
- For the lockscreen: `gcc`, `pam` headers (`pam-auth` is compiled by `install.sh`)

## Installation

```sh
git clone https://github.com/Edgit13/Edots-rice ~/Dotfiles
cd ~/Dotfiles && ./install.sh
# relogin (so fish/swayidle/systemd pick up the new environment)
```

`install.sh`:
1. Clones the repo and `Edot-Wallpapers` (into `~/Pictures/Wallpapers`).
2. Installs pacman + AUR packages (`yay` is bootstrapped automatically).
3. Downloads Google Sans Flex.
4. Runs `./sync.sh install` — symlinks configs into `~/.config`.
5. Enables + starts the systemd user services.
6. Compiles `lockscreen/pam-auth`.
7. Generates the initial palette from the first wallpaper.

Then:
```sh
qs -p ~/.config/quickshell/bar/shell.qml
```

`--auto` runs without prompts.

## Keybinds (mango/binds.conf)

| Bind | Action |
|---|---|
| `Super+Space` | Launcher |
| `Super+C` | Wallpapers |
| `Super+V` | Clipboard |
| `Super+W` | Wi-Fi |
| `Super+X` | Mixer |
| `Super+O` | Power menu |
| `Super+A` | Settings |
| `Super+D` | Dashboard |
| `Super+T` | Tasks |
| `Super+U` | QuickSnip (screen capture) |
| `Super+L` | Lock (M3 lock screen) |
| `Super+F3` | Suspend (lock → suspend) |
| `Super+Esc` | Close surface |
| `Super+B` / `Super+E` | Firefox / Files |

## IPC

```sh
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleLauncher
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleWallpaper
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleClipboard
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleMixer
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleWifi
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill togglePower
qs -p ~/.config/quickshell/bar/shell.qml ipc call dashboard toggle
qs -p ~/.config/quickshell/bar/shell.qml ipc call tasks toggle
qs -p ~/.config/quickshell/bar/shell.qml ipc call settings-launch toggle
```

Settings shell runs as a separate process:
```sh
qs ipc call settingsapp toggle
```

## Color system

One palette, many consumers. `wallcolors.py` (matugen + custom HSL rules)
writes:

| File | Consumer |
|---|---|
| `~/.config/quickshell/colors.json` | bar, lockscreen, settings |
| `~/.config/quickshell/dock-colors.json` | dock |
| `~/.config/mango/colors.json` | bar (mirror) |
| `~/.config/mango/swaylock/colors.conf` | swaylock (legacy) |
| `~/.config/{kitty,ghostty}/*-colors.conf` | terminals |
| `~/.config/gtk-{3.0,4.0}/gtk-colors.css` | GTK |
| `~/.config/firefox-colors.css` | Firefox chrome |
| `~/.config/swaync/colors.css` | notifications |
| `~/.config/rofi/colors.rasi` | rofi |
| `~/.config/fish/fish-colors.fish` | fish |
| `~/.config/kdeglobals` | Qt / KDE |

Wallpaper change → **everything** updates live. Quickshell, GTK, kitty, fish
recolor with no restart (`watchChanges`).

## NixOS

See [nix/README.md](nix/README.md) — NixOS + home-manager modules
(mango flake, quickshell, capture stack).

## License

MIT.
