pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick

// Material 3 IconButton: standard | filled | tonal | outlined.
Rectangle {
    id: ib
    property string icon: ""
    property string style: "standard"     // standard | filled | tonal | outlined
    property bool selected: false
    property bool enabled_: true
    property string tooltip: ""
    signal clicked()

    width: 38
    height: 38
    radius: M3.rFull
    opacity: enabled_ ? 1.0 : M3.disabledOpacity

    readonly property color _fg: {
        if (style === "filled") return ib.selected ? M3.onPrimary : M3.primary
        if (style === "tonal")  return M3.onSecondaryContainer
        if (style === "outlined") return M3.primary
        return ib.selected ? M3.primary : M3.onSurfaceVariant
    }
    readonly property color _bg: {
        if (style === "filled") return ib.selected ? M3.primary : M3.surfaceContainerHighest
        if (style === "tonal")  return M3.secondaryContainer
        return M3.surfaceContainerHigh
    }
    color: {
        if (!enabled_) return M3.surfaceContainerHigh
        if (ma.pressed) return M3.pressedOf(_bg)
        if (ma.containsMouse || ib.selected) return M3.hoverOf(_bg)
        return style === "standard" && !ib.selected ? "transparent" : _bg
    }
    border.width: style === "outlined" ? 1 : 0
    border.color: M3.outline
    Behavior on color { ColorAnimation { duration: M3.durFast } }

    Text {
        anchors.centerIn: parent
        text: ib.icon
        color: ib._fg
        font { family: "Material Symbols Rounded"; pixelSize: 19 }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: ib.enabled_
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: ib.clicked()
    }

    Rectangle {
        visible: ib.tooltip.length > 0 && ma.containsMouse
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
            text: ib.tooltip
            color: M3.onSurface
            font: M3.labelMedium
        }
    }
}
