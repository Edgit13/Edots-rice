import "root:/theme"
import "root:/modules/common"
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// BatteryModule — кільце заряду з іконкою всередині + відсоток (як у end-4). Ховається без батареї.
BarModule {
    id: root

    property var battery: UPower.displayDevice
    readonly property bool isPresent: battery !== null && battery.isPresent && (battery.type === UPowerDeviceType.Battery || battery.percentage > 0)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property int level: Math.round((battery?.percentage ?? 0) * 100)
    readonly property real ringSize: Math.max(Theme.components.dp(20), cross - Theme.space.sm)

    readonly property string iconGlyph: {
        if (charging) return "\ue1a3"
        if (level >= 95) return "\ue1a5"
        if (level < 15) return "\ue19c"
        const bar = Math.min(6, Math.max(1, Math.ceil(level / 100 * 6)))
        return String.fromCodePoint(0xf09c + (bar - 1))
    }
    readonly property color stateColor: {
        if (charging) return Theme.color.primary
        if (level <= 15) return Theme.color.error
        if (level <= 30) return Theme.color.warning
        return Theme.color.primary
    }

    shown: isPresent
    contentW: stat.implicitWidth + Theme.space.md * 2
    contentH: stat.implicitHeight + Theme.space.xs * 2

    BarButton {
        anchors.fill: parent

        BarRingStat {
            id: stat
            anchors.centerIn: parent
            vertical: root.vertical
            ringSize: root.ringSize
            value: root.level / 100
            glyph: root.iconGlyph
            ringColor: root.stateColor
            iconColor: root.stateColor
            text: root.level + "%"
            textColor: root.level <= 15 && !root.charging ? Theme.color.error : Theme.color.fgSurface
            verticalText: String(root.level)
        }
    }
}
