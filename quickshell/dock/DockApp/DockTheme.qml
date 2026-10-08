pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.DockApp

// The dock's colors in the Material 3 style. They are read from a flat JSON
// file of Material color roles — the same format matugen writes with
// templates/colors.json:
//
//   { "background": "#131315", "primary": "#81d5cd", ... }
//
// The file is theme.colorsFile in the dock's config.json, by default
//
//   ~/.config/quickshell/dock-colors.json
//
// which wallcolors.py rewrites on every wallpaper change (the patched
// wallcolors.py ships the full M3 role set there). The file is watched: the
// dock recolors as soon as it changes, without a reload call. Keys missing
// from the file, or a missing file, keep the built-in colors below.
Singleton {
    id: root

    readonly property string fontFamily: "Fira Sans Semibold"

    // Built-in colors, used until (and unless) the colors file provides them.
    // Only the roles the dock draws with are listed; other keys in the file are
    // ignored.
    readonly property var defaultColors: ({
        "background": "#131315",
        "on_primary": "#003734",
        "on_surface": "#e3e3e3",
        "on_surface_variant": "#c7c7c7",
        "outline_variant": "#444746",
        "primary": "#81d5cd",
        "shadow": "#000000",
        "surface_container_high": "#1d1d1f",
        "primary_container": "#1f4a47",
        "on_primary_container": "#a9ece5",
        "secondary_container": "#364542",
        "on_secondary_container": "#d5e4e1"
    })

    property color background: defaultColors.background
    property color on_primary: defaultColors.on_primary
    property color on_surface: defaultColors.on_surface
    property color on_surface_variant: defaultColors.on_surface_variant
    property color outline_variant: defaultColors.outline_variant
    property color primary: defaultColors.primary
    property color shadow: defaultColors.shadow
    property color surface_container_high: defaultColors.surface_container_high
    property color primary_container: defaultColors.primary_container
    property color on_primary_container: defaultColors.on_primary_container
    property color secondary_container: defaultColors.secondary_container
    property color on_secondary_container: defaultColors.on_secondary_container

    // M3 state layer helper: a color tinted to the given opacity, for hover
    // (0.08), focus (0.10) and pressed (0.12) states.
    function stateLayer(baseColor, opacity) {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, opacity)
    }

    // theme.colorsFile with a leading "~" or "$HOME" expanded — FileView takes
    // a plain path. Empty (nothing loaded) until the dock's config.json has
    // been read, so a custom path is never preceded by a load of the default.
    readonly property string defaultColorsFile: Quickshell.env("HOME")
        + "/.config/quickshell/dock-colors.json"
    readonly property string colorsFile: {
        if (!DockSettings.ready)
            return ""
        const raw = `${DockSettings.settings.theme.colorsFile ?? ""}`.trim()
        if (raw === "")
            return root.defaultColorsFile
        return raw.replace(/^(~|\$HOME)(?=\/|$)/, Quickshell.env("HOME"))
    }

    // Apply the file's colors over the built-in ones. Every role is reset
    // first, so a key removed from the file falls back instead of keeping the
    // previous theme's value.
    function applyColors(text): void {
        let parsed = ({})
        if (text && text.trim() !== "") {
            try {
                parsed = JSON.parse(text)
            } catch (e) {
                console.warn("dock theme: could not parse " + root.colorsFile
                    + ", using the built-in colors:", e)
            }
        }
        for (let key in root.defaultColors)
            root[key] = (typeof parsed[key] === "string" && parsed[key] !== "")
                ? parsed[key] : root.defaultColors[key]
    }

    // Re-read the colors file. It is watched, so this is only needed when the
    // file did not exist yet when the dock started (a watch cannot follow a
    // file that is created later). Part of "Reload Dock" / the reload IPC.
    function reload(): void {
        colorsView.reload()
    }

    FileView {
        id: colorsView
        path: root.colorsFile
        watchChanges: true
        printErrors: false
        onFileChanged: colorsView.reload()
        onLoaded: root.applyColors(colorsView.text())
        onLoadFailed: root.applyColors("")
    }
}
