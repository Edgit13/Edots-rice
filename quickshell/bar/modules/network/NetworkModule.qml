import "root:/theme"
import Quickshell
import Quickshell.Networking
import QtQuick

// NetworkModule — M3 Expressive статус мережі (Wi-Fi / Ethernet / Offline).
// Клік: відкриває Wi-Fi panel / менеджер мереж.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal wifiRequested()

    readonly property var wifiDevice: {
        if (!Networking.devices || !Networking.devices.values) return null
        return Networking.devices.values.find(d => d.type === DeviceType.wifi || d.type === 2)
    }

    readonly property var activeNetwork: {
        if (!wifiDevice) return null
        if (wifiDevice.connectedNetwork) return wifiDevice.connectedNetwork
        if (wifiDevice.networks && wifiDevice.networks.values) {
            return wifiDevice.networks.values.find(n => n.connected || n.state === 100)
        }
        return null
    }

    readonly property bool isOnline: (Networking.connected === true) || (activeNetwork !== null)
    readonly property bool isWifi: wifiDevice !== null && (Networking.wifiEnabled === true)
    readonly property string ssid: activeNetwork && activeNetwork.name ? activeNetwork.name : (isOnline ? "Online" : "Offline")

    readonly property string iconGlyph: {
        if (!isOnline) return "\ue1da"       // signal_wifi_off
        if (isWifi) return "\ue63e"          // wifi
        return "\ue0be"                      // lan
    }

    implicitWidth: vertical ? cross : (contentRow.implicitWidth + Theme.space.sm * 2)
    implicitHeight: vertical ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHigh

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
                text: root.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.isOnline ? Theme.color.primary : Theme.color.outline
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.ssid
                style: Theme.type.labelMedium
                color: root.isOnline ? Theme.color.fgSurface : Theme.color.outline
                elide: Text.ElideRight
                width: Math.min(90, implicitWidth)
            }
        }

        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.isOnline ? Theme.color.primary : Theme.color.outline
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.wifiRequested()
    }
}
