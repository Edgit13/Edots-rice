pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Material 3 Button: filled (default) | tonal | outlined | text.
// icon — гліф Material Symbols; tooltip — необов'язковий.
Rectangle {
    id: btn

    property string text: ""
    property string icon: ""
    property string style: "filled"      // filled | tonal | outlined | text
    property bool enabled_: true          // (enabled — зарезервовано Item)
    property string tooltip: ""
    signal clicked()

    implicitWidth: Math.max(64, row.implicitWidth + M3.s24)
    implicitHeight: 36
    radius: M3.rFull
    opacity: enabled_ ? 1.0 : M3.disabledOpacity

    readonly property color _fg: {
        if (!btn.enabled_) return M3.onSurfaceVariant
        switch (style) {
        case "tonal":    return M3.onSecondaryContainer
        case "outlined": return M3.primary
        case "text":     return M3.primary
        default:         return M3.onPrimary       // filled
        }
    }
    color: {
        if (!btn.enabled_) return M3.surfaceContainerHigh
        if (ma.containsMouse && ma.pressed) return M3.pressedOf(btn._bg)
        if (ma.containsMouse) return M3.hoverOf(btn._bg)
        return btn._bg
    }
    readonly property color _bg: {
        switch (style) {
        case "tonal":    return M3.secondaryContainer
        case "outlined": return M3.surfaceContainerLow
        case "text":     return "transparent"
        default:         return M3.primary
        }
    }
    border.width: style === "outlined" ? 1 : 0
    border.color: M3.outline

    Behavior on color { ColorAnimation { duration: M3.durFast } }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: M3.s8

        Text {
            visible: btn.icon.length > 0
            text: btn.icon
            color: btn._fg
            font { family: "Material Symbols Rounded"; pixelSize: 17 }
        }
        Text {
            visible: btn.text.length > 0
            text: btn.text
            color: btn._fg
            font: M3.labelLarge
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: btn.enabled_
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: btn.clicked()
    }

    Rectangle {
        visible: btn.tooltip.length > 0 && ma.containsMouse
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: tipTxt.implicitWidth + 12
        implicitHeight: 22
        radius: M3.rS
        color: M3.surfaceContainerHigh
        z: 99
        Text {
            id: tipTxt
            anchors.centerIn: parent
            text: btn.tooltip
            color: M3.onSurface
            font: M3.labelMedium
        }
    }
}
