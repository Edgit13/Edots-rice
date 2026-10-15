pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick

// M3 Expressive Switch: thumb росте off→on→pressed, їде з overshoot, усередині галочка.
Rectangle {
    id: sw

    property bool checked: false
    property bool enabled_: true
    signal toggled()

    width: Theme.components.switchTrackW
    height: Theme.components.switchTrackH
    radius: height / 2
    opacity: enabled_ ? 1 : Theme.components.disabledContent

    color: sw.checked ? Theme.color.primary : Theme.color.surfaceContainerHighest
    border.width: sw.checked ? 0 : Theme.components.dp(2)
    border.color: Theme.color.outline
    Behavior on color { MotionColorAnimation { role: "stateChange" } }

    // state layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: sw.checked ? Theme.color.fgPrimary : Theme.color.fgSurface
        opacity: ma.pressed ? Theme.components.statePressed
               : ma.containsMouse ? Theme.components.stateHover : 0
        Behavior on opacity { MotionAnimation { role: "hover" } }
    }

    Rectangle {
        id: thumb
        width: ma.pressed ? Theme.components.switchThumbPressed
             : sw.checked ? Theme.components.switchThumbOn
             : Theme.components.switchThumbOff
        height: width
        radius: width / 2
        x: (sw.checked ? sw.width - sw.height / 2 : sw.height / 2) - width / 2
        y: (sw.height - height) / 2
        color: sw.checked ? Theme.color.fgPrimary : Theme.color.outline

        Behavior on x { MotionAnimation { role: "move" } }
        Behavior on width { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "stateChange" } }

        Text {
            anchors.centerIn: parent
            text: "check"
            font { family: Theme.type.icons; pixelSize: Math.round(thumb.width * 0.7) }
            color: Theme.color.primary
            opacity: sw.checked ? 1 : 0
            Behavior on opacity { MotionAnimation { role: "stateChange" } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: sw.enabled_
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: sw.toggled()
    }
}
