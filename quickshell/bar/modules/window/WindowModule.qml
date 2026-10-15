import "root:/theme"
import "root:/services"
import "root:/modules/common"
import QtQuick

// WindowModule — як у end-4: клас застосунку дрібно зверху, заголовок під ним; без власної плашки.
// ЛКМ: floating · СКМ: закрити вікно.
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
    implicitWidth: activeOnThisScreen ? (vertical ? cross : Math.min(Theme.components.dp(280), col.implicitWidth + Theme.space.md * 2)) : 0
    implicitHeight: activeOnThisScreen ? (vertical ? Math.min(Theme.components.dp(100), vcol.implicitHeight + Theme.space.sm * 2) : cross) : 0

    Behavior on opacity { MotionAnimation { role: "stateChange" } }
    Behavior on implicitWidth { MotionAnimation { role: "morph" } }
    Behavior on implicitHeight { MotionAnimation { role: "morph" } }

    BarButton {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) MangoService.closeFocusedClient()
            else MangoService.toggleFloatingFocusedClient()
        }

        Column {
            id: col
            visible: !root.vertical
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.space.md
            spacing: 0
            ThemedText {
                text: root.appName + (root.client && root.client.floating ? "  ·  float" : "")
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
                elide: Text.ElideRight
                width: Math.min(implicitWidth, Theme.components.dp(250))
            }
            ThemedText {
                text: root.displayTitle
                style: Theme.type.labelMedium
                emphasized: true
                color: Theme.color.fgSurface
                elide: Text.ElideRight
                width: Math.min(implicitWidth, Theme.components.dp(250))
            }
        }

        Column {
            id: vcol
            visible: root.vertical
            anchors.centerIn: parent
            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.appName.slice(0, 2).toUpperCase()
                style: Theme.type.labelSmall
                emphasized: true
            }
        }
    }
}
