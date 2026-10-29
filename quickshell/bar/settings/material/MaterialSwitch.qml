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

    readonly property bool nothing: Theme.settings.nothing
    // Nothing: увімкнено — світла доріжка з темним повзунком і червоною крапкою; вимкнено — контурна доріжка
    color: sw.checked ? Theme.color.primary : (nothing ? "transparent" : Theme.color.surfaceContainerHighest)
    border.width: sw.checked ? 0 : (nothing ? 1 : Theme.components.dp(2))
    border.color: nothing ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.40) : Theme.color.outline
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
        width: sw.nothing ? (ma.pressed ? Theme.components.dp(18) : Theme.components.dp(16))
             : ma.pressed ? Theme.components.switchThumbPressed
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
            visible: !sw.nothing
            opacity: sw.checked ? 1 : 0
            Behavior on opacity { MotionAnimation { role: "stateChange" } }
        }
        Rectangle {                                         // Nothing: червона крапка в повзунку
            visible: sw.nothing
            anchors.centerIn: parent
            width: Math.round(parent.width * 0.38); height: width; radius: width / 2
            color: ThemeNothing.red
            opacity: sw.checked ? 1 : 0
            scale: sw.checked ? 1 : 0.2
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
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
