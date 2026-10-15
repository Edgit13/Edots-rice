pragma Singleton
import "root:/theme"
import Quickshell
import QtQuick

// M3.qml — compat-шар. Власного M3 більше немає: усе (кольори, типографіка, відступи, форми, рух)
// береться з Theme. Лишається, щоб старі контроли (RowColor, ExpressiveDot, pages.bak) не ламались.
Singleton {
    id: m3

    // ---- colors ----
    readonly property color primary: Theme.color.primary
    readonly property color m3OnPrimary: Theme.color.fgPrimary
    readonly property color primaryContainer: Theme.color.primaryContainer
    readonly property color m3OnPrimaryContainer: Theme.color.fgPrimaryContainer
    readonly property color secondary: Theme.color.secondary
    readonly property color secondaryContainer: Theme.color.secondaryContainer
    readonly property color m3OnSecondaryContainer: Theme.color.fgSecondaryContainer
    readonly property color tertiary: Theme.color.tertiary
    readonly property color tertiaryContainer: Theme.color.tertiaryContainer
    readonly property color error: Theme.color.error
    readonly property color m3OnError: Theme.color.fgError
    readonly property color errorContainer: Theme.color.errorContainer
    readonly property color surface: Theme.color.surface
    readonly property color surfaceContainerLow: Theme.color.surfaceContainerLow
    readonly property color surfaceContainer: Theme.color.surfaceContainer
    readonly property color surfaceContainerHigh: Theme.color.surfaceContainerHigh
    readonly property color surfaceContainerHighest: Theme.color.surfaceContainerHighest
    readonly property color m3OnSurface: Theme.color.fgSurface
    readonly property color m3OnSurfaceVariant: Theme.color.fgSurfaceVariant
    readonly property color outline: Theme.color.outline
    readonly property color outlineVariant: Theme.color.outlineVariant
    readonly property color scrim: Theme.color.scrim

    function mix(base, tint, f) { return Qt.tint(base, Qt.rgba(tint.r, tint.g, tint.b, f)) }
    function hoverOf(c)   { return Qt.rgba(c.r, c.g, c.b, Theme.components.stateHover) }
    function focusOf(c)   { return Qt.rgba(c.r, c.g, c.b, Theme.components.stateFocus) }
    function pressedOf(c) { return Qt.rgba(c.r, c.g, c.b, Theme.components.statePressed) }

    // ---- typography ----
    function _f(t) { return ({ family: t.family, pixelSize: t.size, weight: t.weight }) }
    readonly property font labelSmall:    _f(Theme.type.labelSmall)
    readonly property font labelMedium:   _f(Theme.type.labelMedium)
    readonly property font labelLarge:    _f(Theme.type.labelLarge)
    readonly property font bodySmall:     _f(Theme.type.bodySmall)
    readonly property font bodyMedium:    _f(Theme.type.bodyMedium)
    readonly property font bodyLarge:     _f(Theme.type.bodyLarge)
    readonly property font titleSmall:    _f(Theme.type.titleSmall)
    readonly property font titleMedium:   _f(Theme.type.titleMedium)
    readonly property font titleLarge:    _f(Theme.type.titleLarge)
    readonly property font headlineSmall: _f(Theme.type.headlineSmall)
    readonly property font monoLarge:     _f(Theme.type.monoLarge)
    readonly property font monoMedium:    _f(Theme.type.monoMedium)

    // ---- spacing / shape / motion ----
    readonly property real s4: Theme.space.xs
    readonly property real s8: Theme.space.sm
    readonly property real s12: Theme.space.md
    readonly property real s16: Theme.space.lg
    readonly property real s24: Theme.space.xl
    readonly property real s32: Theme.space.xxl

    readonly property real rXS: Theme.shape.xs
    readonly property real rS: Theme.shape.sm
    readonly property real rM: Theme.shape.md
    readonly property real rL: Theme.shape.lg
    readonly property real rXL: Theme.shape.xl
    readonly property real rFull: 9999

    readonly property int durFast: Theme.motion.duration("hover")
    readonly property int durMed: Theme.motion.duration("stateChange")
    readonly property int durSlow: Theme.motion.duration("fade")

    readonly property real disabledOpacity: Theme.components.disabledContent
}
