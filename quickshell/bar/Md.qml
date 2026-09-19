pragma Singleton
import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick

// Md.qml — Material 3 style layer ПОВЕРХ Colors (одне джерело: colors.json).
// Семантика M3 (containers, state layers, shape, type) без другої колірної системи.
Singleton {
    id: md

    // Власне читання colors.json (не залежить від внутрішностей Colors.qml)
    property var data: ({})
    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: md.parse()
        Component.onCompleted: md.parse()
    }
    function parse() {
        try { md.data = JSON.parse(colorsFile.text()) } catch (e) { md.data = {} }
    }
    function hexToColor(hex) {
        if (typeof hex !== "string" || hex.charAt(0) !== "#")
            return Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 1)
        let h = hex.slice(1)
        if (h.length === 3) h = h.split("").map(function(ch) { return ch + ch }).join("")
        const n = parseInt(h, 16)
        if (isNaN(n)) return Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 1)
        return Qt.rgba(((n >> 16) & 255) / 255, ((n >> 8) & 255) / 255, (n & 255) / 255, 1)
    }
    function c(k) {
        if (md.data[k] !== undefined && md.data[k] !== null) return hexToColor(md.data[k])
        return Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 1)
    }

    function mix(a, b, f) {
        if (typeof a === "string") a = hexToColor(a)
        if (typeof b === "string") b = hexToColor(b)
        if (a === undefined || a === null) a = Colors.accent
        if (b === undefined || b === null) b = Colors.accent
        return Qt.tint(a, Qt.rgba(b.r, b.g, b.b, f))
    }
    function hoverOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.08) }
    function focusOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.12) }
    function pressedOf(c) { return Qt.rgba(c.r, c.g, c.b, 0.12) }

    // Повні M3-токени — якщо colors.json згенеровано новим шаблоном (md3:true);
    // інакше fallback на евристику + WCAG-контраст нижче.
    readonly property bool hasMd3: md.data.md3 === true
    readonly property color primary:          hasMd3 ? md.c("primary")          : Colors.accent
    readonly property color onPrimary:        hasMd3 ? md.c("on_primary")        : Colors.bg0
    readonly property color primaryContainer: hasMd3 ? md.c("primary_container") : mix(Colors.bg2, Colors.accent, 0.30)
    readonly property color onPrimaryContainer: hasMd3 ? md.c("on_primary_container") : mix(Colors.accent, Colors.fg, 0.65)
    readonly property color secondaryContainer: hasMd3 ? md.c("secondary_container") : mix(Colors.bg2, Colors.accent, 0.16)
    readonly property color onSecondaryContainer: hasMd3 ? md.c("on_secondary_container") : mix(Colors.accent, Colors.fg, 0.65)
    readonly property color tertiary:         hasMd3 ? md.c("tertiary")         : Colors.accent
    readonly property color error:            hasMd3 ? md.c("error")            : Colors.red
    readonly property color onError:          hasMd3 ? md.c("on_error")          : Colors.bg0
    readonly property color errorContainer:   hasMd3 ? md.c("error_container")   : mix(Colors.bg2, Colors.red, 0.30)
    readonly property color surface:                 hasMd3 ? md.c("surface")                  : Colors.bg0
    readonly property color surfaceContainerLow:     hasMd3 ? md.c("surface_container_low")    : Colors.bg1
    readonly property color surfaceContainer:        hasMd3 ? md.c("surface_container")        : Colors.bg2
    readonly property color surfaceContainerHigh:    hasMd3 ? md.c("surface_container_high")   : Colors.bg3
    readonly property color surfaceContainerHighest: hasMd3 ? md.c("surface_container_highest"): Colors.bg4
    readonly property color outline:        hasMd3 ? md.c("outline")         : Colors.grey1
    readonly property color outlineVariant: hasMd3 ? md.c("outline_variant") : mix(Colors.grey1, Colors.fg, 0.25)


    // WCAG-контраст: якщо fg/grey2 контрастні з bg0 — читабельність гарантовано
    function _lin(c) { return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4) }
    function _lum(c) { return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b) }
    function _contrast(a, b) {
        const la = _lum(a), lb = _lum(b)
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
    }
    readonly property color onSurface: {
        if (hasMd3) return md.c("on_surface")
        if (_contrast(Colors.fg, Colors.bg0) >= 4.5) return Colors.fg
        return _lum(Colors.bg0) > 0.5 ? mix(Colors.bg0, "#000000", 0.90) : mix(Colors.bg0, "#ffffff", 0.90)
    }
    readonly property color onSurfaceVariant: {
        if (hasMd3) return md.c("on_surface_variant")
        if (_contrast(Colors.grey2, Colors.bg0) >= 3.0) return Colors.grey2
        return _lum(Colors.bg0) > 0.5 ? mix(Colors.bg0, "#000000", 0.65) : mix(Colors.bg0, "#ffffff", 0.65)
    }


    readonly property real rS: 8
    readonly property real rM: 12
    readonly property real rL: 16
    readonly property real rXL: 28
    readonly property real rFull: 999
    readonly property int durFast: 120
    readonly property int durMed: 200
}
