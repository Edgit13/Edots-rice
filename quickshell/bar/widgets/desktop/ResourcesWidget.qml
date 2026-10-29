import "root:/theme"
import "root:/services"
import QtQuick

// ResourcesWidget — три концентричні кільця: CPU (зовнішнє) · RAM · диск. Опитує PerformanceService лише поки видимий.
WidgetFrame {
    id: root
    kind: "resources"

    property real unit: 200

    property bool wanted: visible
    onWantedChanged: wanted ? PerformanceService.subscribe() : PerformanceService.unsubscribe()
    Component.onCompleted: if (wanted) PerformanceService.subscribe()
    Component.onDestruction: if (wanted) PerformanceService.unsubscribe()

    readonly property real _d: Math.min(contentItem.width, contentItem.height)
    readonly property real _t: Math.max(5, unit * 0.045)

    ArcGauge {
        anchors.centerIn: parent
        width: root._d; height: width; thickness: root._t
        value: PerformanceService.cpuPercent / 100
        trackColor: Theme.alpha(root.onColor, 0.16); valueColor: root.accentColor
    }
    ArcGauge {
        anchors.centerIn: parent
        width: root._d * 0.76; height: width; thickness: root._t
        value: PerformanceService.ramPercent / 100
        trackColor: Theme.alpha(root.onColor, 0.16); valueColor: root.onColor
    }
    ArcGauge {
        anchors.centerIn: parent
        width: root._d * 0.52; height: width; thickness: root._t
        value: PerformanceService.diskPercent / 100
        trackColor: Theme.alpha(root.onColor, 0.16); valueColor: Theme.alpha(root.onColor, 0.6)
    }
    Column {
        anchors.centerIn: parent
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Math.round(PerformanceService.cpuPercent) + "%"
            style: Theme.type.titleLarge
            font.pixelSize: root.unit * 0.1
            emphasized: true
            color: root.onColor
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "CPU"
            style: Theme.type.labelSmall
            font.pixelSize: root.unit * 0.05
            color: Theme.alpha(root.onColor, 0.65)
        }
    }
}
