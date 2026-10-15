import "root:/theme"
import "root:/media"
import "root:/modules/common"
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// BatteryModule — кільце заряду з іконкою всередині + відсоток (як у end-4). Ховається без батареї.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

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

    visible: isPresent
    implicitWidth: isPresent ? (vertical ? cross : (row.implicitWidth + Theme.space.md * 2)) : 0
    implicitHeight: isPresent ? (vertical ? (col.implicitHeight + Theme.space.xs * 2) : cross) : 0

    BarButton {
        anchors.fill: parent

        Row {
            id: row
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs
            MediaRing {
                anchors.verticalCenter: parent.verticalCenter
                width: root.ringSize; height: root.ringSize
                value: root.level / 100
                icon: root.iconGlyph
                ringColor: root.stateColor
                iconColor: root.stateColor
            }
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.level + "%"
                style: Theme.type.labelMedium
                color: root.level <= 15 && !root.charging ? Theme.color.error : Theme.color.fgSurface
            }
        }

        Column {
            id: col
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2
            MediaRing {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.ringSize; height: root.ringSize
                value: root.level / 100
                icon: root.iconGlyph
                ringColor: root.stateColor
                iconColor: root.stateColor
            }
            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(root.level)
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
            }
        }
    }
}
