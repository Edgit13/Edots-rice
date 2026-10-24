# Edots: Nothing system palette integration

This patch connects the Quickshell Design setting (`Material` / `Nothing`) to the generated desktop palette.

## Files changed
- `theme/ThemeSettings.qml`: applies the matching system palette after startup and when the selected design changes.
- `surfaces/WallpaperSurface.qml`: choosing a new wallpaper preserves Nothing colors while updating the remembered wallpaper; Material mode regenerates the dynamic palette.
- `wallcolors.py`: includes `--no-shell-restart`, allowing Quickshell to invoke the script without killing itself, and restores a saved wallpaper palette (or creates it for older setups).

## Install
1. Back up the current Quickshell config and `~/.config/mango/scripts/wallcolors.py`.
2. Copy the changed QML files into the corresponding folders of your Quickshell config.
3. Install `wallcolors.py` to `~/.config/mango/scripts/wallcolors.py` (the same path already used by `WallpaperSurface.qml`).
4. Restart Quickshell once.
5. Open Settings → Appearance/Design and select `Nothing` or `Material`.

The script also updates GTK/KDE color config files. Some applications only reread their theme on restart; Firefox and terminal applications may need their own theme import/config enabled. This does not force apps that ignore generated config files to adopt the palette.
