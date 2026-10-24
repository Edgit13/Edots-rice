import "root:/theme"
import "root:/services"
import "root:/modules/common"
import QtQuick

// ResourcesModule — кільця CPU / RAM з відсотками (як Resources в end-4). Вмикається: Settings → Бар → Модулі.
BarModule {
    id: root

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

    contentW: grid.implicitWidth + Theme.space.md * 2
    contentH: grid.implicitHeight + Theme.space.xs * 2

    BarButton {
        anchors.fill: parent
        onClicked: root.resourcesRequested()          // відкриває/закриває BarWindow (onResourcesRequested) — тут не дублюємо

        Grid {
            id: grid
            anchors.centerIn: parent
            columns: root.vertical ? 1 : 2
            spacing: root.vertical ? Theme.space.xs : Theme.space.md
            verticalItemAlignment: Grid.AlignVCenter

            BarRingStat {
                vertical: root.vertical
                ringSize: root.ringSize
                value: root.cpu / 100
                glyph: "\ue322"
                ringColor: root.cpu > 85 ? Theme.color.error : Theme.color.primary
                iconColor: Theme.color.fgSurfaceVariant
                text: Math.round(root.cpu) + "%"
            }
            BarRingStat {
                vertical: root.vertical
                ringSize: root.ringSize
                value: root.ram / 100
                glyph: "\ue1db"
                ringColor: root.ram > 85 ? Theme.color.error : Theme.color.tertiary
                iconColor: Theme.color.fgSurfaceVariant
                text: Math.round(root.ram) + "%"
            }
        }
    }
}
