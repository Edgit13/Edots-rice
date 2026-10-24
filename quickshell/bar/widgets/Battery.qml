pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "root:/theme"

RowLayout {
    id: root
    spacing: 6

    property var battery: UPower.displayDevice
    property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property int level: Math.round((battery?.percentage ?? 0) * 100)

    readonly property string icon: {
        if (charging) return String.fromCodePoint(0xe1a3)
        if (level >= 99) return String.fromCodePoint(0xe1a5)
        if (level < 10) return String.fromCodePoint(0xe19c)
        const bar = Math.min(6, Math.max(1, Math.ceil(level / 100 * 6)))
        return String.fromCodePoint(0xf09c + (bar - 1))
    }

    Text {
        text: root.icon
        color: root.charging ? Colors.green
                              : root.level <= 15 ? Colors.red
                              : root.level <= 30 ? Colors.orange
                              : Colors.green
        font { family: "Material Symbols Rounded"; pixelSize: 13 }
    }

    Text {
        text: root.level + "%"
        color: Colors.fg
        font { family: "SF Pro Display"; weight: 500 }
    }
}
