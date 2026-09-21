import "root:/theme"
import Quickshell
import Quickshell.Io
import QtQuick

// NotificationModule — M3 Expressive сповіщення (SwayNC).
// Клік: відкрити/закрити SwayNC.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

    property int count: 0

    Process {
        id: countProc
        command: ["swaync-client", "-c"]
        stdout: SplitParser {
            onRead: function(line) {
                const n = parseInt(line.trim(), 10)
                root.count = isNaN(n) ? 0 : n
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!countProc.running) countProc.running = true
    }

    Process {
        id: toggleProc
        command: ["swaync-client", "-t", "-sw"]
    }

    implicitWidth: vertical ? cross : (root.count > 0 ? (contentRow.implicitWidth + Theme.space.sm * 2) : cross)
    implicitHeight: vertical ? (root.count > 0 ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross) : cross

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
             : (root.count > 0 ? Theme.color.secondaryContainer : Theme.color.surfaceContainerHigh)

        scale: ma.pressed ? 0.94 : 1.0
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.count > 0 ? "\ue7f5" : "\ue7f4"  // notifications_active vs notifications
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.count > 0 ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
            }

            ThemedText {
                visible: root.count > 0
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.count)
                style: Theme.type.labelSmall
                emphasized: true
                color: Theme.color.fgSecondaryContainer
            }
        }

        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.count > 0 ? "\ue7f5" : "\ue7f4"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.count > 0 ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
            }

            Rectangle {
                visible: root.count > 0
                anchors.horizontalCenter: parent.horizontalCenter
                width: 6; height: 6
                radius: 3
                color: Theme.color.error
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: toggleProc.running = true
    }
}
