# M3 Dock — a Material 3 dock for Quickshell

A standalone Quickshell dock (based on [ml4w-dock](https://github.com/mylinuxforwork/ml4w-dock)),
restyled to Material 3 and wired into the `wallcolors.py` wallpaper pipeline.
It is compositor-agnostic (MangoWM, Sway, Hyprland — plain Wayland
layer-shell + foreign-toplevel, no compositor-specific APIs), shows on **all
monitors**, and recolors live when the wallpaper changes.

A `state` file in this directory controls visibility: `0` hides the dock,
`1` shows it. The quickshell process keeps running while hidden and watches
the file, so toggling is instant. `toggle-dock.sh` is the entry point: it
starts the dock if it is not running, and flips the state file if it is.

## Layout

```
~/Dotfiles/quickshell/dock/
├── shell.qml            # entry point (qs -p)
├── toggle-dock.sh       # start-if-not-running, otherwise flip state 0<->1
├── state                # 1 = show, 0 = hide (created by toggle-dock.sh)
├── README.md
└── DockApp/
    ├── DockLoader.qml        # lifecycle + IPC + state file, one dock per monitor
    ├── DockClickCatcher.qml  # transparent surface: dismisses open menus on outside clicks
    ├── DockWindow.qml        # layer-shell panel, pill, mask, context menu
    ├── DockItem.qml          # app icon + M3 active indicator + tooltip
    ├── DockLauncherButton.qml
    ├── DockMenu.qml          # M3 context menu (8dp, state-layer rows)
    ├── DockSettings.qml      # config singleton (~/.config/quickshell-dock/config.json)
    ├── DockSettingsWindow.qml
    ├── DockSwitch.qml        # M3 switch
    ├── DockTheme.qml         # M3 color roles, watches the colors file
    └── config.json           # documented defaults
```

## Start

```sh
qs -p ~/Dotfiles/quickshell/dock
```

To start it with your compositor, add it to the autostart (MangoWM
`~/.config/mango/autostart`, Sway `~/.config/sway/config`, Hyprland
`exec-once`):

```sh
qs -p ~/Dotfiles/quickshell/dock
```

## IPC

```sh
qs -p ~/Dotfiles/quickshell/dock ipc call dock <function>
```

| Function | Description |
| --- | --- |
| `toggle` / `enable` / `disable` | Show or hide the dock |
| `autohideToggle` / `autohideOn` / `autohideOff` | Toggle autohide |
| `reload` | Re-read `config.json` and the colors file |
| `settings` | Open the settings dialog |
| `edit` | Open `config.json` in the configured editor |

## Colors (Material 3)
## Config

`~/.config/quickshell-dock/config.json` is created on first start and merged
over the built-in defaults (`DockApp/config.json` documents every key). Only
the values you want to change need to be there. The dock writes `enabled`,
`autohide` and the pinned list back into it (right-click an icon → Pin to Dock).
