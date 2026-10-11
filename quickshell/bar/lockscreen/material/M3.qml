pragma Singleton
import Quickshell
import "root:/theme"
import QtQuick

// bar/lockscreen/material/M3.qml — compatibility shim over Theme.*
//
// The lock screen used to carry its own M3 color system reading colors.json
// independently. It now shares the bar's Theme; this singleton keeps the
// old M3 property names so LockScreen.qml and ExpressiveDot.qml need no
// changes. Colors, fonts, spacing, shapes and motion all follow the bar.
Singleton {
    id: m3

    // ---- raw palette aliases (some lock files name colors like Colors.qml) ----
    readonly property color bg0:    Theme.color.background
    readonly property color bg1:    Theme.color.surfaceContainerLow
    readonly property color bg2:    Theme.color.surfaceContainer
    readonly property color bg3:    Theme.color.surfaceContainerHigh
    readonly property color bg4:    Theme.color.surfaceContainerHighest
    readonly property color fg:     Theme.color.fgSurface
    readonly property color grey1:  Theme.color.outline
    readonly property color grey2:  Theme.color.fgSurfaceVariant
    readonly property color accent: Theme.color.primary
    readonly property color red:    Theme.color.error
    readonly property color blue:   Theme.color.secondary
    readonly property color purple: Theme.color.tertiary

    // ---- M3 color roles ----
    readonly property color primary:              Theme.color.primary
    readonly property color m3OnPrimary:          Theme.color.fgPrimary
    readonly property color primaryContainer:     Theme.color.primaryContainer
    readonly property color m3OnPrimaryContainer: Theme.color.fgPrimaryContainer

    readonly property color secondary:              Theme.color.secondary
    readonly property color secondaryContainer:     Theme.color.secondaryContainer
    readonly property color m3OnSecondaryContainer: Theme.color.fgSecondaryContainer

    readonly property color tertiary:          Theme.color.tertiary
    readonly property color tertiaryContainer: Theme.color.tertiaryContainer

    readonly property color error:          Theme.color.error
    readonly property color m3OnError:      Theme.color.fgError
    readonly property color errorContainer: Theme.color.errorContainer

    readonly property color surface:                 Theme.color.surface
    readonly property color surfaceContainerLow:     Theme.color.surfaceContainerLow
    readonly property color surfaceContainer:        Theme.color.surfaceContainer
    readonly property color surfaceContainerHigh:    Theme.color.surfaceContainerHigh
    readonly property color surfaceContainerHighest: Theme.color.surfaceContainerHighest

    readonly property color m3OnSurface:        Theme.color.fgSurface
    readonly property color m3OnSurfaceVariant: Theme.color.fgSurfaceVariant

    readonly property color outline:        Theme.color.outline
    readonly property color outlineVariant: Theme.color.outlineVariant
    readonly property color scrim:          Theme.color.scrim

    // ---- state layers ----
    function hoverOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.08) }
    function focusOf(c)   { return Qt.rgba(c.r, c.g, c.b, 0.12) }
    function pressedOf(c) { return Qt.rgba(c.r, c.g, c.b, 0.12) }
    function mix(base, tint, f) {
        return Qt.tint(base, Qt.rgba(tint.r, tint.g, tint.b, f))
    }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function layer(base, on, opacity) {
        return Qt.tint(base, Qt.rgba(on.r, on.g, on.b, opacity))
    }

    // ---- typography: Theme uses .size, Material* expects .pixelSize ----
    readonly property string fontFamily: Theme.type.sans
    readonly property string fontMono:   Theme.type.mono

    function _f(t) {
        return { family: t.family, pixelSize: t.size, weight: t.weight }
    }
    readonly property var labelSmall:    _f(Theme.type.labelSmall)
    readonly property var labelMedium:   _f(Theme.type.labelMedium)
    readonly property var labelLarge:    _f(Theme.type.labelLarge)
    readonly property var bodySmall:     _f(Theme.type.bodySmall)
    readonly property var bodyMedium:    _f(Theme.type.bodyMedium)
    readonly property var bodyLarge:     _f(Theme.type.bodyLarge)
    readonly property var titleSmall:    _f(Theme.type.titleSmall)
    readonly property var titleMedium:   _f(Theme.type.titleMedium)
    readonly property var titleLarge:    _f(Theme.type.titleLarge)
    readonly property var headlineSmall: _f(Theme.type.headlineSmall)
    readonly property var monoLarge:     _f(Theme.type.monoLarge)
    readonly property var monoMedium:    _f(Theme.type.monoMedium)

    // ---- spacing ----
    readonly property real s4:  Theme.space.xs
    readonly property real s8:  Theme.space.sm
    readonly property real s12: Theme.space.md
    readonly property real s16: Theme.space.lg
    readonly property real s24: Theme.space.xl
    readonly property real s32: Theme.space.xxl

    // ---- shape ----
    readonly property real rXS:   Theme.shape.xs
    readonly property real rS:    Theme.shape.sm
    readonly property real rM:    Theme.shape.md
    readonly property real rL:    Theme.shape.lg
    readonly property real rXL:   Theme.shape.xl
    readonly property real rFull: Theme.shape.full

    // ---- motion ----
    readonly property int durFast: Theme.motion.duration("press")
    readonly property int durMed:  Theme.motion.duration("stateChange")
    readonly property real durSlow: Theme.motion.duration("fade")

    readonly property real disabledOpacity: Theme.components.disabledContent
}
