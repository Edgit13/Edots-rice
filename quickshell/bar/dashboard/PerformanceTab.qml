import "root:/theme"
import "root:/services"
import QtQuick
import QtQuick.Layouts

// PerformanceTab — CPU/RAM/диск наживо (/proc, df).
Item {
    id: root

    Component.onCompleted: PerformanceService.subscribe()
    Component.onDestruction: PerformanceService.unsubscribe()

    component Meter: ColumnLayout {
        property string label: ""
        property real percent: 0
        property string sub: ""
        spacing: Theme.space.xs
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            ThemedText { text: label; style: Theme.type.titleSmall; Layout.fillWidth: true }
            ThemedText { text: Math.round(percent) + "%"; style: Theme.type.titleSmall; color: Theme.color.primary }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.settings.nothing ? 14 : 8
            radius: 4
            color: Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainerHighest
            Rectangle {
                visible: !Theme.settings.nothing
                width: parent.width * Math.max(0, Math.min(1, percent / 100))
                height: parent.height
                radius: 4
                color: percent > 85 ? Theme.color.error : Theme.color.primary
                Behavior on width { MotionAnimation { role: "stateChange" } }
            }
            // Nothing: сегментована шкала (ряд смужок)
            Row {
                id: segRow
                visible: Theme.settings.nothing
                anchors.fill: parent
                spacing: 4
                readonly property int cnt: Math.max(10, Math.floor((width + 4) / 9))
                Repeater {
                    model: Theme.settings.nothing ? segRow.cnt : 0
                    delegate: Rectangle {
                        required property int index
                        readonly property bool lit: (index + 0.5) / segRow.cnt <= Math.max(0, Math.min(1, percent / 100))
                        width: (segRow.width - (segRow.cnt - 1) * 4) / segRow.cnt
                        height: parent.height
                        radius: width / 2
                        color: lit ? (percent > 85 ? ThemeNothing.red : Theme.color.primary) : Theme.color.fgSurface
                        opacity: lit ? 1.0 : ThemeNothing.dotOpacityOff
                        Behavior on opacity { NumberAnimation { duration: 90 } }
                    }
                }
            }
        }
        ThemedText {
            visible: sub.length > 0
            text: sub
            style: Theme.type.labelSmall
            color: Theme.color.fgSurfaceVariant
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.lg
        spacing: Theme.space.xl

        Meter { label: "Процесор"; percent: PerformanceService.cpuPercent }
        Meter { label: "Пам'ять"; percent: PerformanceService.ramPercent
                sub: PerformanceService.ramUsedGiB.toFixed(1) + " / " + PerformanceService.ramTotalGiB.toFixed(1) + " ГіБ" }
        Meter { label: "Диск (/)"; percent: PerformanceService.diskPercent
                sub: PerformanceService.diskUsedGiB.toFixed(0) + " / " + PerformanceService.diskTotalGiB.toFixed(0) + " ГіБ" }

        Item { Layout.fillHeight: true }
    }
}
