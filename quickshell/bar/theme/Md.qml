pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// Md — сумісний шар для старих M3-токенів (Wifi/Mixer/LoadingIndicator), на базі ThemeColors.
Singleton {
    id: root

    readonly property color primary:            ThemeColors.primary
    readonly property color onPrimary:          ThemeColors.fgPrimary
    readonly property color primaryContainer:   ThemeColors.primaryContainer
    readonly property color onPrimaryContainer: ThemeColors.fgPrimaryContainer
    readonly property color error:              ThemeColors.error
    readonly property color outline:            ThemeColors.outline
    readonly property color outlineVariant:     ThemeColors.outlineVariant
    readonly property color surfaceContainerLow:     ThemeColors.surfaceContainerLow
    readonly property color surfaceContainerHigh:    ThemeColors.surfaceContainerHigh
    readonly property color surfaceContainerHighest: ThemeColors.surfaceContainerHighest

    readonly property color m3OnSurface:          ThemeColors.fgSurface
    readonly property color m3OnSurfaceVariant:   ThemeColors.fgSurfaceVariant
    readonly property color m3OnPrimary:          ThemeColors.fgPrimary
    readonly property color m3OnPrimaryContainer: ThemeColors.fgPrimaryContainer

    readonly property int rS: ThemeSettings.nothing ? ThemeNothing.corners.sm : 8
    readonly property int rM: ThemeSettings.nothing ? ThemeNothing.corners.md : 12
    readonly property int durFast: 120
    readonly property int durMed:  220

    function hoverOf(c) { return ThemeColors.layer(c, ThemeColors.fgSurface, 0.08) }
}
