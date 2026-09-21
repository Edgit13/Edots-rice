import "root:/theme"
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// BatteryModule — M3 Expressive статус батареї через UPower.
// Автоматично ховається на стаціонарних ПК без батареї.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

    property var battery: UPower.displayDevice
    readonly property bool isPresent: battery !== null && battery.isPresent && (battery.type === UPowerDeviceType.Battery || battery.percentage > 0)
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging
    readonly property int level: Math.round((battery?.percentage ?? 0) * 100)

    readonly property string iconGlyph: {
        if (charging) return "\ue1a3"        // battery_charging_full
        if (level >= 95) return "\ue1a5"     // battery_full
        if (level < 15) return "\ue19c"      // battery_alert
        const bar = Math.min(6, Math.max(1, Math.ceil(level / 100 * 6)))
        return String.fromCodePoint(0xf09c + (bar - 1))
    }

    readonly property color stateColor: {
        if (charging) return Theme.color.primary
        if (level <= 15) return Theme.color.error
        if (level <= 30) return Theme.color.warning
        return Theme.color.fgSurface
    }

    visible: isPresent
    implicitWidth: isPresent ? (vertical ? cross : (contentRow.implicitWidth + Theme.space.sm * 2)) : 0
    implicitHeight: isPresent ? (vertical ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross) : 0

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
                color: root.stateColor
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.level + "%"
                style: Theme.type.labelMedium
                color: root.stateColor
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
                color: root.stateColor
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: String(root.level)
                style: Theme.type.labelSmall
                color: root.stateColor
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
    }
}
