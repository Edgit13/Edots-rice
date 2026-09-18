import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    spacing: 6
    property int activeWorkspace: 1

    Repeater {
        model: 9
        Rectangle {
            required property int index
            Layout.preferredWidth: 24
            Layout.preferredHeight: 22
            radius: 6
            color: index + 1 === root.activeWorkspace ? Colors.accent : Colors.bg3
            Behavior on color { ColorAnimation { duration: 120 } }
            Text {
                anchors.centerIn: parent
                text: index + 1
                color: index + 1 === root.activeWorkspace ? Colors.bg0 : Colors.fg
                font { family: "SF Mono"; pixelSize: 11 }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activeWorkspace = index + 1
            }
        }
    }
}
