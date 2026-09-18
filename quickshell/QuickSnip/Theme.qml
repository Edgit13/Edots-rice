import QtQuick
import Quickshell
import Quickshell.Io

// ==========================================================================
// Theme.qml — Edots adaptive colors for QuickSnip.
//
// Reads ~/.config/quickshell/colors.json — the same file that
// mango/scripts/wallcolors.py (matugen-based) writes for the Edots bar.
// watchChanges: нові кольори підхоплюються без перезапуску, коли
// wallcolors.py перегенеровує палітру.
// Fallback — дефолтна Edots-палітра, якщо файлу ще нема.
//
// NOTE: QtObject has no default property, so the FileView is assigned to
// an explicit property instead of being a plain child.
// ==========================================================================

QtObject {
    id: root

    readonly property var fallback: ({
        "bg0": "#060f0c",
        "bg1": "#0a1a16",
        "bg2": "#0f2922",
        "bg3": "#15372e",
        "bg4": "#1c4a3d",
        "fg": "#dae7e3",
        "accent": "#74e7c8",
        "grey1": "#31816c",
        "grey2": "#90d5c2"
    })

    property var palette: root.fallback

    function col(key) {
        const v = palette[key]
        if (typeof v === "string" && v.length > 0)
            return v
        return root.fallback[key] || "#ffffff"
    }

    readonly property color bg0:    col("bg0")
    readonly property color bg1:    col("bg1")
    readonly property color bg2:    col("bg2")
    readonly property color bg3:    col("bg3")
    readonly property color fg:     col("fg")
    readonly property color accent: col("accent")
    readonly property color grey1:  col("grey1")
    readonly property color grey2:  col("grey2")

    readonly property string colorsPath:
        (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config"))
        + "/quickshell/colors.json"

    readonly property FileView _colorsFile: FileView {
        path: root.colorsPath
        watchChanges: true
        onTextChanged: root.reload()
        Component.onCompleted: root.reload()
    }

    function reload() {
        try {
            const raw = _colorsFile.text()
            if (raw && raw.trim().length > 0)
                root.palette = Object.assign({}, root.fallback, JSON.parse(raw))
        } catch (e) {
            console.warn("[QuickSnip] Theme: failed to parse colors.json:", e)
        }
    }
}
