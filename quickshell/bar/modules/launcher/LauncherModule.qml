import "root:/theme"
import QtQuick

// LauncherModule — кругла tonal-кнопка (як лівий край бару в end-4); при натисканні форма морфиться.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal activated()

    implicitWidth: cross
    implicitHeight: cross

    Rectangle {
        anchors.fill: parent
        radius: ma.pressed ? Theme.shape.radius("md", height) : Theme.shape.radius("full", height)
        color: Theme.color.primaryContainer
        Behavior on radius { MotionAnimation { role: "morph" } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.color.fgPrimaryContainer
            opacity: ma.pressed ? Theme.components.statePressed : (ma.containsMouse ? Theme.components.stateHover : 0)
            Behavior on opacity { MotionAnimation { role: "hover" } }
        }
        Text {
            anchors.centerIn: parent
            text: "\ue5c3"
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            color: Theme.color.fgPrimaryContainer
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
