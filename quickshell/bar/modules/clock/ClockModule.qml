import "root:/theme"
import "root:/shell"
import "root:/services"
import "root:/modules/common"
import Quickshell
import QtQuick

// ClockModule — час жирним + дата світліше (як у end-4), плоский, у BarGroup.
// Клік відкриває Dashboard.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal clicked()

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

    implicitWidth: vertical ? cross : (contentRow.implicitWidth + Theme.space.md * 2)
    implicitHeight: vertical ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross

    BarButton {
        anchors.fill: parent
        onClicked: root.clicked()

        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.timeStr
                style: Theme.type.clockBar
                emphasized: !Theme.settings.nothing
                color: Theme.color.fgSurface
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 3; height: 3; radius: 1.5
                color: Theme.settings.nothing ? ThemeNothing.red : Theme.color.outline
            }
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.dateStr
                style: Theme.type.labelMedium
                color: Theme.color.fgSurfaceVariant
            }
        }

        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeStrVertical
                style: Theme.type.monoSmall
                emphasized: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
