pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

// ResetDot — кнопка ↺ збоку опції. Видима лише коли значення != default.
Rectangle {
    id: rd
    required property string cat
    required property string key

    readonly property bool dirty: Settings.isDirty(rd.cat, rd.key)
    visible: rd.dirty
    implicitWidth: Theme.components.dp(32)
    implicitHeight: Theme.components.dp(32)
    radius: ma.pressed ? Theme.shape.iconButtonPressed : Theme.shape.radius("full", height)
    color: "transparent"
    Behavior on radius { MotionAnimation { role: "morph" } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.color.primary
        opacity: ma.pressed ? Theme.components.statePressed
               : ma.containsMouse ? Theme.components.stateHover : 0
        Behavior on opacity { MotionAnimation { role: "hover" } }
    }
    Text {
        anchors.centerIn: parent
        text: "restart_alt"
        color: Theme.color.primary
        font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Settings.resetKey(rd.cat, rd.key)
    }
}
