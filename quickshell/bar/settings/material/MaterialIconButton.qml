pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick

// M3 Expressive IconButton: standard | filled | tonal | outlined.
// Форма: коло → (selected) squircle → (pressed) менший радіус.
Rectangle {
    id: ib

    property string icon: ""
    property string style: "standard"
    property bool selected: false
    property bool enabled_: true
    property string tooltip: ""
    signal clicked()

    width: Theme.components.buttonS
    height: Theme.components.buttonS
    opacity: enabled_ ? 1 : Theme.components.disabledContent

    radius: ma.pressed ? Theme.shape.iconButtonPressed
          : ib.selected ? Theme.shape.radius("lg", height)
          : Theme.shape.radius("full", height)
    Behavior on radius { MotionAnimation { role: "morph" } }

    readonly property color _bg: {
        switch (style) {
        case "filled":   return ib.selected ? Theme.color.primary : Theme.color.surfaceContainerHighest
        case "tonal":    return ib.selected ? Theme.color.secondaryContainer : Theme.color.surfaceContainerHighest
        case "outlined": return ib.selected ? Theme.color.inverseSurface : "transparent"
        default:         return "transparent"
        }
    }
    readonly property color _fg: {
        switch (style) {
        case "filled":   return ib.selected ? Theme.color.fgPrimary : Theme.color.primary
        case "tonal":    return Theme.color.fgSecondaryContainer
        case "outlined": return ib.selected ? Theme.color.inverseOnSurface : Theme.color.fgSurfaceVariant
        default:         return ib.selected ? Theme.color.primary : Theme.color.fgSurfaceVariant
        }
    }

    color: ib._bg
    border.width: style === "outlined" && !ib.selected ? 1 : 0
    border.color: Theme.color.outline
    Behavior on color { MotionColorAnimation { role: "hover" } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: ib._fg
        opacity: ma.pressed ? Theme.components.statePressed
               : ma.containsMouse ? Theme.components.stateHover : 0
        Behavior on opacity { MotionAnimation { role: "hover" } }
    }

    Text {
        anchors.centerIn: parent
        text: ib.icon
        color: ib._fg
        font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
        Behavior on color { MotionColorAnimation { role: "hover" } }
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
        anchors.topMargin: Theme.space.xs
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: tipTxt.implicitWidth + Theme.space.md * 2
        implicitHeight: Theme.components.tooltipHeight
        radius: Theme.shape.tooltip
        color: Theme.color.inverseSurface
        z: 99
        ThemedText {
            id: tipTxt
            anchors.centerIn: parent
            text: ib.tooltip
            style: Theme.type.labelSmall
            color: Theme.color.inverseOnSurface
        }
    }
}
