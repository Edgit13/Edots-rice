import "root:/theme"
import QtQuick

// RecDot — червона крапка запису: пульсує, а при hover стає квадратом «стоп».
Rectangle {
    id: dot

    property bool hovered: false
    property bool pulsing: false

    implicitWidth: Theme.components.dp(10)
    implicitHeight: implicitWidth
    radius: hovered ? Theme.components.dp(2) : width / 2
    color: Theme.color.error
    Behavior on radius { MotionAnimation { role: "morph" } }

    SequentialAnimation on opacity {
        running: dot.pulsing
        loops: Animation.Infinite
        NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
    }
    onHoveredChanged: if (hovered) opacity = 1
}
