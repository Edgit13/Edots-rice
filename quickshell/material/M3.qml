pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// ==========================================================================
// M3.qml — SHARED Material 3 foundation для ВСІЄЇ Edots (Bar + Capture).
// Єдина точка: ~/.config/quickshell/material/M3.qml
// (symlink: bar/material, QuickSnip/material).
// Колір — НАПРЯМУ з ~/.config/quickshell/colors.json (live-watch):
// зміна шпалер → увесь M3 (і бар, і Capture) перефарбовується миттєво.
// ==========================================================================

Singleton {
    id: m3

    // ---------- source colors (Edots colors.json) ----------
    property var data: ({})
    FileView {
        id: colorsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: m3.parse()
        Component.onCompleted: m3.parse()
    }
    function parse() {
        try { m3.data = JSON.parse(colorsFile.text()) } catch (e) { m3.data = {} }
    }
    function v(k, fb) { return m3.data[k] !== undefined ? m3.data[k] : fb }

    readonly property color bg0: v("bg0", "#060f0c")
    readonly property color bg1: v("bg1", "#0a1a16")
    readonly property color bg2: v("bg2", "#0f2922")
    readonly property color bg3: v("bg3", "#15372e")
    readonly property color bg4: v("bg4", "#1c4a3d")
    readonly property color fg:    v("fg", "#dae7e3")
    readonly property color grey1: v("grey1", "#31816c")
    readonly property color grey2: v("grey2", "#90d5c2")
    readonly property color accent:  v("accent", "#74e7c8")
    readonly property color red:    v("red", "#d27c79")
    readonly property color blue:   v("blue", "#d27c79")
    readonly property color purple: v("purple", "#d1df9f")

    // ---------- M3 roles ----------
    function mix(base, tint, f) {
        return Qt.tint(base, Qt.rgba(tint.r, tint.g, tint.b, f))
    }

    readonly property color primary:            accent
    readonly property color onPrimary:          bg0
    readonly property color primaryContainer:   mix(bg2, accent, 0.32)
    readonly property color onPrimaryContainer: mix(accent, fg, 0.65)

    readonly property color secondary:            blue
    readonly property color secondaryContainer:   mix(bg2, blue, 0.28)
    readonly property color onSecondaryContainer: mix(blue, fg, 0.65)

    readonly property color tertiary:            purple
    readonly property color tertiaryContainer:   mix(bg2, purple, 0.28)

    readonly property color error:            red
    readonly property color onError:          bg0
    readonly property color errorContainer:   mix(bg2, red, 0.30)

    readonly property color surface:                 bg0
    readonly property color surfaceContainerLow:     mix(bg1, fg, 0.02)
    readonly property color surfaceContainer:        bg1
    readonly property color surfaceContainerHigh:    bg2
    readonly property color surfaceContainerHighest: bg3

    readonly property color onSurface:        fg
    readonly property color onSurfaceVariant: grey2

    readonly property color outline:        grey1
    readonly property color outlineVariant: mix(grey1, fg, 0.25)

    readonly property color scrim: "#000000"

    // state layers (M3: hover 8%, focus/pressed 12%)
    function hoverOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.08) }
    function focusOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.12) }
    function pressedOf(c) { return Qt.rgba(c.r, c.g, c.b, 0.12) }

    // ---------- typography ----------
    readonly property string fontFamily: "SF Pro Display"
    readonly property string fontMono:   "SF Mono"
    readonly property font labelSmall:    ({ family: fontFamily, pixelSize: 10, weight: 500 })
    readonly property font labelMedium:   ({ family: fontFamily, pixelSize: 11, weight: 500 })
    readonly property font labelLarge:    ({ family: fontFamily, pixelSize: 12, weight: 500 })
    readonly property font bodySmall:     ({ family: fontFamily, pixelSize: 11, weight: 400 })
    readonly property font bodyMedium:    ({ family: fontFamily, pixelSize: 12, weight: 400 })
    readonly property font bodyLarge:     ({ family: fontFamily, pixelSize: 14, weight: 400 })
    readonly property font titleSmall:    ({ family: fontFamily, pixelSize: 13, weight: 600 })
    readonly property font titleMedium:   ({ family: fontFamily, pixelSize: 15, weight: 600 })
    readonly property font titleLarge:    ({ family: fontFamily, pixelSize: 18, weight: 600 })
    readonly property font headlineSmall: ({ family: fontFamily, pixelSize: 21, weight: 700 })
    readonly property font monoLarge:     ({ family: fontMono, pixelSize: 15, weight: 600 })
    readonly property font monoMedium:    ({ family: fontMono, pixelSize: 12, weight: 500 })

    // ---------- spacing / shape / motion ----------
    readonly property real s4: 4
    readonly property real s8: 8
    readonly property real s12: 12
    readonly property real s16: 16
    readonly property real s24: 24

    readonly property real rXS: 4
    readonly property real rS: 8
    readonly property real rM: 12
    readonly property real rL: 16
    readonly property real rXL: 28
    readonly property real rFull: 999

    readonly property int durFast: 120
    readonly property int durMed: 200
    readonly property int durSlow: 350

    readonly property real disabledOpacity: 0.38
}
