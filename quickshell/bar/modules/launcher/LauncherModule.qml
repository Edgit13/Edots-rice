import "root:/theme"
import QtQuick

// LauncherModule — M3 Expressive trigger для відкриття лаунчера / головного меню.
// На клік відправляє сигнал activated.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal activated()

    implicitWidth: vertical ? cross : (contentRow.implicitWidth + Theme.space.sm * 2)
    implicitHeight: vertical ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.primary, Theme.color.fgPrimary, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.primaryContainer, Theme.color.fgPrimaryContainer, Theme.components.stateHover)
             : Theme.color.primaryContainer

        scale: ma.pressed ? 0.92 : (ma.containsMouse ? 1.05 : 1.0)
        transformOrigin: Item.Center

        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        // Horizontal layout
        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\ue5c3"   // apps / grid icon
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgPrimaryContainer
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: "Mango"
                style: Theme.type.labelLarge
                emphasized: true
                color: Theme.color.fgPrimaryContainer
            }
        }

        // Vertical layout
        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xxs

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\ue5c3"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgPrimaryContainer
            }
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
