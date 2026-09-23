import "root:/theme"
import "root:/services"
import QtQuick
import QtQuick.Layouts

// PerformanceTab — CPU/RAM/диск наживо (/proc, df). Опитування йде лише поки вкладка видима.
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
            implicitHeight: 10
            radius: 5
            color: Theme.color.surfaceContainerHighest
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, percent / 100))
                height: parent.height
                radius: 5
                color: percent > 85 ? Theme.color.error : Theme.color.primary
                Behavior on width { MotionAnimation { role: "stateChange" } }
            }
        }
        ThemedText { visible: sub.length > 0; text: sub; style: Theme.type.labelSmall; color: Theme.color.fgSurfaceVariant }
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
