import "root:/theme"
import QtQuick

// PowerModule — M3 Expressive кнопка керування живленням / сесією.
// Лівий клік: Power menu; Правий клік: Налаштування.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal powerRequested()
    signal settingsRequested()

    implicitWidth: cross
    implicitHeight: cross

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.error, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.error, Theme.components.stateHover)
             : Theme.color.surfaceContainerHigh

        scale: ma.pressed ? 0.92 : (ma.containsMouse ? 1.05 : 1.0)
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        Text {
            anchors.centerIn: parent
            text: "\ue8ac"  // power_settings_new
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            color: ma.containsMouse ? Theme.color.error : Theme.color.fgSurfaceVariant
            Behavior on color { MotionColorAnimation { role: "hover" } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.settingsRequested()
            } else {
                root.powerRequested()
            }
        }
    }
}
