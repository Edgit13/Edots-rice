import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Workspaces module — Material 3.
// ЧЕСНА межа: активний воркспейс — локальна властивість (compositor IPC
// не підключений, як і в оригіналі); клік оновлює підсвітку.
RowLayout {
    id: root
    spacing: Config.get("workspaces", "spacing")

    property int activeWorkspace: 1

    Repeater {
        model: Config.get("workspaces", "count")
        Rectangle {
            required property int index
            Layout.preferredWidth: Config.get("workspaces", "buttonWidth")
            Layout.preferredHeight: Config.get("workspaces", "buttonHeight")
            radius: Config.get("workspaces", "radius")

            readonly property bool active: index + 1 === root.activeWorkspace
            color: active ? M3.primaryContainer
                : (hover.hovered ? M3.hoverOf(M3.surfaceContainerHigh) : M3.surfaceContainer)
            Behavior on color { ColorAnimation { duration: M3.durFast } }

            Text {
                anchors.centerIn: parent
                visible: Config.get("workspaces", "showNumbers")
                text: index + 1
                color: active ? M3.m3OnPrimaryContainer : M3.m3OnSurfaceVariant
                font: M3.labelLarge
                Behavior on color { ColorAnimation { duration: M3.durFast } }
            }

            HoverHandler { id: hover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activeWorkspace = index + 1
            }
        }
    }
}
