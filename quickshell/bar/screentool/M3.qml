pragma Singleton
import "root:/theme"
import Quickshell
import QtQuick

// bar/screentool/M3.qml — shim над bar/theme.
Singleton {
    id: root

    readonly property color surface:              Theme.color.surface
    readonly property color surfaceContainerHigh: Theme.color.surfaceContainerHigh
    readonly property color outlineVariant:       Theme.color.outlineVariant
    readonly property color fgSurface:            Theme.color.fgSurface
    readonly property color fgSurfaceVariant:     Theme.color.fgSurfaceVariant
    readonly property color primary:              Theme.color.primary
    readonly property color fgPrimary:            Theme.color.fgPrimary
    readonly property color primaryContainer:     Theme.color.primaryContainer
    readonly property color fgPrimaryContainer:   Theme.color.fgPrimaryContainer
    readonly property color secondaryContainer:   Theme.color.secondaryContainer
    readonly property color fgSecondaryContainer: Theme.color.fgSecondaryContainer

    readonly property color errorContainer:       Theme.color.errorContainer
    readonly property color fgErrorContainer:     Theme.color.fgErrorContainer

    readonly property color inverseSurface:       Theme.color.inverseSurface
    readonly property color inverseOnSurface:     Theme.color.inverseOnSurface

    readonly property color scrim:      Qt.rgba(Theme.color.scrim.r, Theme.color.scrim.g, Theme.color.scrim.b, 0.6)
    readonly property color scrimLight: Qt.rgba(Theme.color.scrim.r, Theme.color.scrim.g, Theme.color.scrim.b, 0.2)

    readonly property bool nothing: Theme.settings.nothing
    readonly property color red: ThemeNothing.red
    readonly property string monoFont: Theme.type.mono

    readonly property string iconFont: Theme.type.icons
    readonly property bool hasIcons: {
        try { return Qt.fontFamilies().indexOf(Theme.type.icons) >= 0 }
        catch (e) { return false }
    }
}
