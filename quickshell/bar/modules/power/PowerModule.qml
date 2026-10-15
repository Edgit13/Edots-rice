import "root:/theme"
import QtQuick

// PowerModule — кругла кнопка живлення; при hover підсвічується error-кольором, при натисканні форма морфиться.
// ЛКМ: Power menu · ПКМ: Налаштування.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal powerRequested()
    signal settingsRequested()

    implicitWidth: cross
    implicitHeight: cross

    Rectangle {
        anchors.fill: parent
        radius: ma.pressed ? Theme.shape.radius("md", height) : Theme.shape.radius("full", height)
        color: ma.containsMouse ? Theme.color.errorContainer : Theme.color.surfaceContainerHigh
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Text {
            anchors.centerIn: parent
            text: "\ue8ac"
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            color: ma.containsMouse ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
            Behavior on color { MotionColorAnimation { role: "hover" } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) root.settingsRequested()
            else root.powerRequested()
        }
    }
}
