import "root:/theme"
import "root:/services"
import "root:/modules/common"
import QtQuick

// WindowModule — як у end-4: клас застосунку дрібно зверху, заголовок під ним; без власної плашки.
// ЛКМ: floating · СКМ: закрити вікно.
BarModule {
    id: root

    property string monitor: ""

    readonly property var client: MangoService.focusedClient
    readonly property bool activeOnThisScreen: !!(client && client.title && (client.monitor === monitor || monitor === ""))
    readonly property string displayTitle: activeOnThisScreen ? client.title : ""
    readonly property string appName: {
        if (!activeOnThisScreen || !client.appid) return ""
        const id = client.appid.split(".").pop()
        return id.charAt(0).toUpperCase() + id.slice(1)
    }

    shown: activeOnThisScreen
    animate: true
    contentW: Math.min(Theme.components.dp(280), col.implicitWidth + Theme.space.md * 2)
    contentH: Math.min(Theme.components.dp(100), vcol.implicitHeight + Theme.space.sm * 2)

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
