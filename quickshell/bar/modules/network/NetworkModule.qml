import "root:/theme"
import "root:/modules/common"
import Quickshell
import Quickshell.Networking
import QtQuick

// NetworkModule — іконка з'єднання; назва мережі виїжджає при hover. Клік: Wi-Fi.
BarRevealButton {
    id: root

    signal wifiRequested()

    readonly property var wifiDevice: {
        if (!Networking.devices || !Networking.devices.values) return null
        return Networking.devices.values.find(d => d.type === DeviceType.Wifi) || null
    }
    readonly property var wiredDevice: {
        if (!Networking.devices || !Networking.devices.values) return null
        return Networking.devices.values.find(d => d.type === DeviceType.Wired) || null
    }
    readonly property var activeNetwork: {
        if (!wifiDevice || !wifiDevice.networks || !wifiDevice.networks.values) return null
        return wifiDevice.networks.values.find(n => n.connected) || null
    }

    readonly property bool wifiConnected: activeNetwork !== null
    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected
    readonly property bool isOnline: wifiConnected || wiredConnected
    readonly property bool isWifi: wifiDevice !== null && Networking.wifiEnabled === true
    readonly property string ssid: wifiConnected ? activeNetwork.name : (isOnline ? "Online" : "Offline")

    readonly property string iconGlyphValue: {
        if (!isOnline) return "\ue1da"
        if (isWifi) return "\ue63e"
        return "\ue0be"
    }
    glyph: iconGlyphValue
    glyphColor: isOnline ? Theme.color.fgSurface : Theme.color.outline
    label: ssid
    labelColor: isOnline ? Theme.color.fgSurface : Theme.color.outline

    onClicked: root.wifiRequested()
}
