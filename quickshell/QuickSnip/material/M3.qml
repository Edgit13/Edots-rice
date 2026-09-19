pragma Singleton
import "root:/"
import Quickshell
import QtQuick

// ==========================================================================
// M3.qml — Material 3 design foundation для Capture (Phase B).
// Джерело кольорів — ТІЛЬКИ EdotsTheme (colors.json, live-watch).
// Жодних хардкод-палітр: ролі вираховуються з Edots-кольорів.
// Також: типографіка, spacing, radii, motion — єдина система.
// ==========================================================================

Singleton {
    id: m3

    // ---------- кольорові ролі (blend = Qt.tint: f — частка кольору) ----------
    function mix(base, tint, f) {
        return Qt.tint(base, Qt.rgba(tint.r, tint.g, tint.b, f))
    }

    readonly property color primary:            EdotsTheme.accent
    readonly property color m3OnPrimary:          EdotsTheme.bg0
    readonly property color primaryContainer:   mix(EdotsTheme.bg2, EdotsTheme.accent, 0.32)
    readonly property color m3OnPrimaryContainer: mix(EdotsTheme.accent, EdotsTheme.fg, 0.65)

    readonly property color secondary:            EdotsTheme.blue
    readonly property color secondaryContainer:   mix(EdotsTheme.bg2, EdotsTheme.blue, 0.28)
    readonly property color m3OnSecondaryContainer: mix(EdotsTheme.blue, EdotsTheme.fg, 0.65)

    readonly property color tertiary:            EdotsTheme.purple
    readonly property color tertiaryContainer:   mix(EdotsTheme.bg2, EdotsTheme.purple, 0.28)

    readonly property color error:            EdotsTheme.red
    readonly property color m3OnError:            EdotsTheme.bg0
    readonly property color errorContainer:     mix(EdotsTheme.bg2, EdotsTheme.red, 0.30)

    readonly property color surface:                  EdotsTheme.bg0
    readonly property color surfaceContainerLowest:   EdotsTheme.bg0
    readonly property color surfaceContainerLow:      mix(EdotsTheme.bg1, EdotsTheme.fg, 0.02)
    readonly property color surfaceContainer:         EdotsTheme.bg1
    readonly property color surfaceContainerHigh:     EdotsTheme.bg2
    readonly property color surfaceContainerHighest:  EdotsTheme.bg3

    readonly property color m3OnSurface:        EdotsTheme.fg
    readonly property color m3OnSurfaceVariant: EdotsTheme.grey2

    readonly property color outline:        EdotsTheme.grey1
    readonly property color outlineVariant: mix(EdotsTheme.grey1, EdotsTheme.fg, 0.25)

    readonly property color scrim: "#000000"

    // state layers (M3: hover 8%, focus 12%, pressed 12%)
    function hoverOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.08) }
    function focusOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.12) }
    function pressedOf(c) { return Qt.rgba(c.r, c.g, c.b, 0.12) }

    // ---------- типографіка (Edots шрифти) ----------
    readonly property string fontFamily: "SF Pro Display"
    readonly property string fontMono:   "SF Mono"

    readonly property font labelSmall:   ({ family: fontFamily, pixelSize: 10, weight: 500 })
    readonly property font labelMedium:  ({ family: fontFamily, pixelSize: 11, weight: 500 })
    readonly property font labelLarge:   ({ family: fontFamily, pixelSize: 12, weight: 500 })
    readonly property font bodySmall:    ({ family: fontFamily, pixelSize: 11, weight: 400 })
    readonly property font bodyMedium:   ({ family: fontFamily, pixelSize: 12, weight: 400 })
    readonly property font bodyLarge:    ({ family: fontFamily, pixelSize: 14, weight: 400 })
    readonly property font titleSmall:   ({ family: fontFamily, pixelSize: 13, weight: 600 })
    readonly property font titleMedium:  ({ family: fontFamily, pixelSize: 15, weight: 600 })
    readonly property font titleLarge:   ({ family: fontFamily, pixelSize: 18, weight: 600 })
    readonly property font headlineSmall:({ family: fontFamily, pixelSize: 21, weight: 700 })

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
