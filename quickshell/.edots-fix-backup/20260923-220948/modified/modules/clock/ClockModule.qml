import "root:/theme"
import "root:/shell"
import "root:/services"
import Quickshell
import QtQuick

// ClockModule — компактна пігулка годинника (M3 Expressive).
// Клік відкриває Dashboard (ShellState.toggleDashboard) замість розгорнутого годинника.
// Формат/пояс — з ClockSettings (як і раніше).
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

    SystemClock {
        id: sysClock
        precision: ClockSettings.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
    readonly property date shown: ClockSettings.displayDate(sysClock.date)

    function _timeFormat() {
        const h = ClockSettings.hour12 ? "h:mm" : "HH:mm"
        const s = ClockSettings.showSeconds ? ":ss" : ""
        const ap = ClockSettings.hour12 ? " AP" : ""
        return h + s + ap
    }
    readonly property string timeStr: Qt.formatDateTime(shown, _timeFormat())
    readonly property string timeStrVertical: Qt.formatDateTime(shown, ClockSettings.hour12 ? "h\nmm" : "HH\nmm")
    readonly property string dateStr: Qt.formatDateTime(shown, ClockSettings.dateFormat)

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

        // Horizontal layout
        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            ThemedText { anchors.verticalCenter: parent.verticalCenter; text: root.timeStr
                         style: Theme.type.monoMedium; emphasized: true; color: Theme.color.fgSurface }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 3; radius: 1.5; color: Theme.color.outlineVariant }
            ThemedText { anchors.verticalCenter: parent.verticalCenter; text: root.dateStr
                         style: Theme.type.labelSmall; color: Theme.color.fgSurfaceVariant }
        }

        // Vertical layout
        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeStrVertical
                style: Theme.type.monoSmall
                emphasized: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.color.fgSurface
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: ShellState.toggleDashboard()
    }
}
