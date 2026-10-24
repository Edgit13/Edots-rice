import "root:/theme"
import QtQuick

// BarButton — ЄДИНА реалізація «кнопки бару»: заливка + hover/press state layer + морф форми при натисканні.
// Раніше те саме писалось окремо в Launcher, Power, Media і Notification (з дрібними відмінностями).
//   fillColor     — колір плашки у спокої (за замовчуванням прозорий; accent → accentColor)
//   stateColor    — колір hover/press-шару (зазвичай «on»-колір до fillColor)
//   stateLayer    — false: без шару (коли hover сам змінює fillColor, як у Power)
//   pressScale    — легке стискання при натисканні (1 = вимкнено)
// Контент кладеться всередину (default property → holder).
Item {
    id: root

    property bool accent: false                    // тональна підсвітка (напр. є непрочитані)
    property color accentColor: Theme.settings.nothing ? Theme.color.surfaceContainerHighest : Theme.color.secondaryContainer
    property color fillColor: accent ? accentColor : "transparent"
    property color stateColor: Theme.color.fgSurface
    property bool stateLayer: true
    property real pressScale: 1.0
    property int acceptedButtons: Qt.LeftButton
    default property alias content: holder.data

    readonly property bool hovered: ma.containsMouse
    readonly property bool pressed: ma.pressed
    readonly property real cornerRadius: shape.radius

    signal clicked(var mouse)
    signal wheeled(var event)

    scale: pressed ? pressScale : 1.0
    Behavior on scale { MotionAnimation { role: "press" } }

    Rectangle {
        id: shape
        anchors.fill: parent
        radius: root.pressed ? Theme.shape.radius("md", height) : Theme.shape.radius("full", height)
        color: root.fillColor
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.stateColor
            opacity: !root.stateLayer ? 0
                   : root.pressed ? Theme.components.statePressed
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
