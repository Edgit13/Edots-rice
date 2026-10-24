# Edots — wallpaper color categories

This patch adds a Wallpapers page in Settings and color filters to the existing `surfaces/WallpaperSurface.qml` picker. It does **not** move, copy, rename, or edit wallpaper files.

## What it does

- Scans `~/Pictures/Wallpapers` for PNG, JPG, JPEG, WebP, and GIF images.
- Samples each image and assigns a dominant-color category: Blue, Purple, Pink, Red, Orange, Yellow, Green, Cyan, Monochrome, or Other.
- Shows a warning that scanning can take time, a progress bar, processed/total count, category totals, and a cancel button.
- Saves the index and progress JSON under `~/.cache/quickshell/`.
- Adds category chips to the existing Quickshell wallpaper picker. Choosing a chip filters the visible images; choosing All restores the full list.
- Keeps the current wallpaper application flow (`awww` and the existing `wallcolors.py`) intact.

## Arch Linux dependency

Install Pillow:

```bash
sudo pacman -S python-pillow
```

## Install

Back up the current configuration first. Extract this archive and merge its contents into `~/.config/quickshell/`, preserving folder structure. The patch changes these existing files:

- `settings/Schema.qml`
- `settings/Lang.qml`
- `settings/SettingsApp.qml`
- `settings/qmldir`
- `surfaces/WallpaperSurface.qml`

It adds:

- `settings/PageWallpapers.qml`
- `scripts/wallpaper_color_index.py`

Then restart Quickshell. Open Settings → Wallpapers → Analyze wallpapers. The first scan may take a while; subsequent picker launches reuse the cached index. To rebuild the categories, use Rescan.

## Notes

- The scan is performed by a separate Python process so the QML UI can continue to respond.
- Cancelling stops the scan; original wallpaper files remain untouched.
- The source project was statically checked and the Python scanner was tested with sample blue, red, and grayscale images. This environment did not have Quickshell available, so the QML could not be runtime-tested here.


### Troubleshooting / log

The scanner writes detailed progress to `~/.cache/quickshell/wallpaper-color-index.log` (start/end of each image, category, elapsed time, errors). Follow it live with `tail -f ~/.cache/quickshell/wallpaper-color-index.log`. Check the last lines with `tail -n 80 ~/.cache/quickshell/wallpaper-color-index.log`.
