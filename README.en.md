# Edots

A minimal and functional **MangoWM** + **Quickshell** config.
**[Українська версія](README.md)**

![Edots](screenshots/preview.png)

## Features

- **Pill** that morphs into surfaces: launcher, wallpapers, media, mixer, clipboard, Wi-Fi, Bluetooth/links, power, settings
- **Full Settings window** — centralized customization system:
  - pages: Pill, Animations, Bar, Presets, System, About
  - **search** across all settings at once
  - every control has a ↺ reset-to-default
  - **presets**: built-in immutable Default + user presets (create/apply/rename/delete/export/import)
  - all changes are live (no restart), persisted to `~/.config/quickshell/settings.json`
- **Dashboard** (Super+D / `qs ipc call dashboard toggle`) — clock, volume (Pipewire), brightness, battery, quick toggles (Wi-Fi/Bluetooth), **swaync** (panel + DND), **calendar with per-day timed tasks**
- **Task Manager** (`qs ipc call tasks toggle`) — folder-based tasks (backend `edots/task-manager/core.py`), **utimer** (background timer with swaync notification), **upkg** (packages via terminal)
- **Blur** — real, via `blur_layer`/`blur_params_radius` in MangoWM config (hot-reload)
- **Animations everywhere** — global switch + speed multiplier (`Anim.ms`)
- Modular hover bar: module visibility and order from the UI
- Panel position top/bottom
- swaync, swaylock-effects, rofi, nm-applet

## Structure

```
quickshell/
├── bar/                    # main shell
│   ├── shell.qml, PillShell.qml
│   ├── Config.qml Defaults.qml Presets.qml   # settings system
│   ├── Anim.qml CompositorFx.qml SettingsSearch.qml TasksStore.qml
│   └── settings/           # Settings UI + Dashboard + Task Manager (plain files)
├── test-implementions/     # experiments (Task Manager ported into the bar)
mango/                      # binds.conf, swayidle.conf, scripts/wallcolors.py, config.conf (blur)
edots/                      # CLI utils: task-manager/, tool-manager/ (utimer, upkg), settings.edot
swaync/ rofi/ kitty/ ...
```

## Requirements

Quickshell (with Io/Wayland/Services/Networking), MangoWM, SF Pro Display/SF Mono/Material Symbols Rounded/JetBrainsMono Nerd Font, `brightnessctl`, `nmcli`, `rfkill`, `swaync-client`, `kitty`, `awww`, `matugen`, `cliphist`, `python3`.

## Installation

```sh
git clone https://github.com/Edgit13/Edots-rice ~/Edots-rice
cd ~/Edots-rice && ./install.sh   # or ./sync.sh to re-sync
qs -p ~/.config/quickshell/bar/shell.qml
```

## Keybinds (mango/binds.conf)

`Super+Space` launcher · `Super+C` wallpaper · `Super+V` clipboard · `Super+W` wifi · `Super+X` mixer · `Super+O` power · `Super+A` settings · `Super+D` dashboard · `Super+Esc` close

## IPC

```sh
qs -p ~/.config/quickshell/bar/shell.qml ipc call pill toggleLauncher
qs -p ~/.config/quickshell/bar/shell.qml ipc call settingsapp toggle
qs -p ~/.config/quickshell/bar/shell.qml ipc call dashboard toggle
qs -p ~/.config/quickshell/bar/shell.qml ipc call tasks toggle
```
