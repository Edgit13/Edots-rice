import "root:/theme"
import "root:/services"
import QtQuick

// WindowModule — показує заголовок / назву активного вікна MangoWM на цьому моніторі.
// Клік: перемикання floating; середній клік: закрити вікно.
Item {
    id: root

    property string monitor: ""
    property bool vertical: false
    property int cross: Theme.components.islandCompact

    readonly property var client: MangoService.focusedClient
    readonly property bool activeOnThisScreen: client && client.title && (client.monitor === monitor || monitor === "")
    readonly property string displayTitle: activeOnThisScreen ? client.title : ""
    readonly property string appName: {
        if (!activeOnThisScreen || !client.appid) return ""
        const id = client.appid.split(".").pop()
        return id.charAt(0).toUpperCase() + id.slice(1)
    }

    visible: opacity > 0.01
    opacity: activeOnThisScreen ? 1 : 0
    implicitWidth: activeOnThisScreen ? (vertical ? cross : Math.min(260, textItem.implicitWidth + Theme.space.md * 2)) : 0
    implicitHeight: activeOnThisScreen ? (vertical ? Math.min(100, textItem.implicitHeight + Theme.space.sm * 2) : cross) : 0

    Behavior on opacity { MotionAnimation { role: "stateChange" } }
    Behavior on implicitWidth { MotionAnimation { role: "morph" } }
    Behavior on implicitHeight { MotionAnimation { role: "morph" } }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHigh
        border.width: client && client.floating ? 1 : 0
        border.color: Theme.color.outlineVariant

        Behavior on color { MotionColorAnimation { role: "hover" } }

        Row {
            id: textItem
            anchors.centerIn: parent
            spacing: Theme.space.xs
            visible: !root.vertical

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: client && client.floating ? "\ue3c6" : "\ue890"  // open_in_new vs tab
                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                color: Theme.color.fgSurfaceVariant
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayTitle
                style: Theme.type.labelMedium
                color: Theme.color.fgSurface
                elide: Text.ElideRight
                width: Math.min(180, implicitWidth)
            }
        }

        // Vertical variant: app initials / icon
        Column {
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "\ue890"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                color: Theme.color.fgSurfaceVariant
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.appName.slice(0, 2).toUpperCase()
                style: Theme.type.labelSmall
                color: Theme.color.fgSurface
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                MangoService.closeFocusedClient()
            } else {
                MangoService.toggleFloatingFocusedClient()
            }
        }
    }
}
