import "root:/theme"
import QtQuick

// BarButton — плоский елемент бару (hover / press state layer, форма морфиться при натисканні).
// Контент кладеться всередину (default property → holder).
Item {
    id: root

    property bool accent: false                    // тональна підсвітка (напр. є непрочитані)
    property color stateColor: Theme.color.fgSurface
    property int acceptedButtons: Qt.LeftButton
    default property alias content: holder.data

    readonly property bool hovered: ma.containsMouse
    readonly property bool pressed: ma.pressed

    signal clicked(var mouse)
    signal wheeled(var event)

    Rectangle {
        anchors.fill: parent
        radius: root.pressed ? Theme.shape.radius("md", height) : Theme.shape.radius("full", height)
        color: root.accent ? Theme.color.secondaryContainer : "transparent"
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.stateColor
            opacity: root.pressed ? Theme.components.statePressed
                   : root.hovered ? Theme.components.stateHover : 0
            Behavior on opacity { MotionAnimation { role: "hover" } }
        }
    }

    Item { id: holder; anchors.fill: parent; clip: true }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: root.acceptedButtons
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
    }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => root.wheeled(e)
    }
}
