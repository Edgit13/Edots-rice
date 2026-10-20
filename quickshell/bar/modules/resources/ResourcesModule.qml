import "root:/theme"
import "root:/services"
import "root:/media"
import "root:/modules/common"
import "root:/shell"
import QtQuick

// ResourcesModule — кільця CPU / RAM з відсотками (як Resources в end-4). Вмикається: Settings → Бар → Модулі.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

    signal resourcesRequested()

    readonly property real ringSize: Math.max(Theme.components.dp(20), cross - Theme.space.sm)
    readonly property real cpu: PerformanceService.cpuPercent
    readonly property real ram: PerformanceService.ramPercent

    // підписка на PerformanceService лише поки модуль видимий
    property bool _sub: false
    function _syncSub() {
        if (visible && !_sub) { PerformanceService.subscribe(); _sub = true }
        else if (!visible && _sub) { PerformanceService.unsubscribe(); _sub = false }
    }
    onVisibleChanged: _syncSub()
    Component.onCompleted: _syncSub()
    Component.onDestruction: if (_sub) PerformanceService.unsubscribe()

    implicitWidth: vertical ? cross : (row.implicitWidth + Theme.space.md * 2)
    implicitHeight: vertical ? (col.implicitHeight + Theme.space.xs * 2) : cross

    BarButton {
        anchors.fill: parent
        onClicked: {
            root.resourcesRequested()
            ShellState.toggleSurface("resources")
        }

        Row {
            id: row
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.md

            Row {
                spacing: Theme.space.xs
                anchors.verticalCenter: parent.verticalCenter
                MediaRing {
                    width: root.ringSize; height: root.ringSize
                    value: root.cpu / 100
                    icon: "\ue322"
                    ringColor: root.cpu > 85 ? Theme.color.error : Theme.color.primary
                    iconColor: Theme.color.fgSurfaceVariant
                }
                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.cpu) + "%"
                    style: Theme.type.labelMedium
                    color: Theme.color.fgSurface
                }
            }
            Row {
                spacing: Theme.space.xs
                anchors.verticalCenter: parent.verticalCenter
                MediaRing {
                    width: root.ringSize; height: root.ringSize
                    value: root.ram / 100
                    icon: "\ue1db"
                    ringColor: root.ram > 85 ? Theme.color.error : Theme.color.tertiary
                    iconColor: Theme.color.fgSurfaceVariant
                }
                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(root.ram) + "%"
                    style: Theme.type.labelMedium
                    color: Theme.color.fgSurface
                }
            }
        }

        Column {
            id: col
            visible: root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs
            MediaRing {
                width: root.ringSize; height: root.ringSize
                value: root.cpu / 100
                icon: "\ue322"
                ringColor: root.cpu > 85 ? Theme.color.error : Theme.color.primary
                iconColor: Theme.color.fgSurfaceVariant
            }
            MediaRing {
                width: root.ringSize; height: root.ringSize
                value: root.ram / 100
                icon: "\ue1db"
                ringColor: root.ram > 85 ? Theme.color.error : Theme.color.tertiary
                iconColor: Theme.color.fgSurfaceVariant
            }
        }
    }
}
