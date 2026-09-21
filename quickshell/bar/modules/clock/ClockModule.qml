import "root:/theme"
import Quickshell
import QtQuick

// ClockModule — M3 Expressive годинник і дата.
// Адаптується під horizontal (HH:mm) та vertical (HH\nmm).
// Клік відкриває Dashboard / календар.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal clicked()

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    readonly property string timeStr: Qt.formatDateTime(sysClock.date, vertical ? "HH\nmm" : "HH:mm")
    readonly property string dateStr: Qt.formatDateTime(sysClock.date, "dd.MM")
    readonly property string fullDateStr: Qt.formatDateTime(sysClock.date, "dddd, d MMMM")

    implicitWidth: vertical ? cross : (contentRow.implicitWidth + Theme.space.md * 2)
    implicitHeight: vertical ? (contentCol.implicitHeight + Theme.space.sm * 2) : cross

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHigh

        scale: ma.pressed ? 0.95 : (ma.containsMouse ? 1.03 : 1.0)
        transformOrigin: Item.Center

        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        // Horizontal Layout
        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeStr
                style: Theme.type.monoMedium
                emphasized: true
                color: Theme.color.fgSurface
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 3; height: 3
                radius: 1.5
                color: Theme.color.outlineVariant
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateStr
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
            }
        }

        // Vertical Layout
        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 0

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeStr
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
        onClicked: root.clicked()
    }
}
