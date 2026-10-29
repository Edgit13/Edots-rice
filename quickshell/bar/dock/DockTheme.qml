pragma Singleton
import Quickshell
import "root:/theme"
import QtQuick

// bar/dock/DockTheme.qml — compatibility shim over Theme.*.
//
// Historically the dock had its own M3 color system reading dock-colors.json
// (written by wallcolors.py alongside colors.json). The dock now shares the
// bar's Theme; this singleton keeps the old property names so no dock file
// needed to change. Colors refresh live because ThemeColors watches
// colors.json itself.
Singleton {
    id: root

    readonly property string fontFamily: Theme.type.sans
    readonly property string monoFamily: Theme.type.mono
    readonly property bool nothing: Theme.settings.nothing
    readonly property color red: ThemeNothing.red

    readonly property color background:             Theme.color.background
    readonly property color on_primary:             Theme.color.fgPrimary
    readonly property color on_surface:             Theme.color.fgSurface
    readonly property color on_surface_variant:     Theme.color.fgSurfaceVariant
    readonly property color outline_variant:        Theme.color.outlineVariant
    readonly property color primary:                Theme.color.primary
    readonly property color shadow:                 Theme.color.shadow
    readonly property color surface_container_high: Theme.color.surfaceContainerHigh
    readonly property color primary_container:      Theme.color.primaryContainer
    readonly property color on_primary_container:   Theme.color.fgPrimaryContainer
    readonly property color secondary_container:    Theme.color.secondaryContainer
    readonly property color on_secondary_container: Theme.color.fgSecondaryContainer

    function stateLayer(baseColor, opacity) {
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, opacity)
    }

    readonly property string defaultColorsFile: ""
    readonly property string colorsFile: ""
    function applyColors(text) {}
    function reload() {}
}
