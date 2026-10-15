import "root:/config"
import "root:/theme"
import "root:/shell"
import "root:/modules/common"
import "root:/modules/workspace"
import "root:/modules/resources"
import "root:/modules/launcher"
import "root:/modules/window"
import "root:/modules/clock"
import "root:/modules/volume"
import "root:/modules/network"
import "root:/modules/battery"
import "root:/modules/media"
import "root:/modules/notifications"
import "root:/modules/power"
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string monitorName: modelData.name
    readonly property string position: BarConfig.positionFor(monitorName)
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int thickness: BarConfig.thicknessFor(monitorName)
    readonly property int gap: Theme.space.screenMargin
    readonly property int reserve: thickness + gap * 2
    readonly property int cross: thickness - Theme.space.xs * 2
    readonly property int inner: cross - Theme.space.xxs * 2          // висота елементів усередині BarGroup

    readonly property var morphModules: [dashboardSurface]
    readonly property bool dashOpen: dashboardSurface.occupies

    function _maxOverflow(dir) {
        let m = 0
        for (const mod of morphModules) m = Math.max(m, mod[dir] || 0)
        return m
    }
    readonly property real freeOverflow: {
        if (position === "top") return _maxOverflow("overflowBottom")
        if (position === "bottom") return _maxOverflow("overflowTop")
        if (position === "left") return _maxOverflow("overflowRight")
        return _maxOverflow("overflowLeft")
    }

    readonly property bool debug: Quickshell.env("EDOTS_BAR_DEBUG") === "1"

    Connections {
        target: Config
        function onCurrentChanged() {
            const pos = Config.get("bar", "position")
            if (pos && pos !== BarConfig.position)
                BarConfig.set("position", pos)
        }
    }

    WlrLayershell.namespace: "edots-bar"
    WlrLayershell.keyboardFocus: dashOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    color: "transparent"

    anchors {
        top: position === "top" || vertical
        bottom: position === "bottom" || vertical
        left: position === "left" || !vertical
        right: position === "right" || !vertical
    }
    implicitWidth: vertical ? reserve + freeOverflow : 0
    implicitHeight: vertical ? 0 : reserve + freeOverflow
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: reserve

    mask: Region {
        Region { item: surface }
        Region { item: win.dashOpen ? dashboardSurface : null }
    }

    // ---- Dashboard: морфиться з смуги ----
    DashboardSurface {
        id: dashboardSurface
        z: 1
        hostMonitor: win.monitorName
        revealDirection: win.position       // ← FIX: анімація з боку бару

        readonly property real stripEnd: win.gap + win.thickness + Theme.space.sm
        readonly property real targetWidth: win.vertical ? Math.min(800, win.width - stripEnd - win.gap * 2)
                                                         : Math.min(920, win.width - win.gap * 4)

        // FIX: SCREEN height, а не win.height — інакше цикл:
        // win.height ← freeOverflow ← overflow ← effectiveHeight ← maxHeight ← win.height
        maxHeight: {
            const sh = win.screen ? win.screen.height : 1080
            const se = win.gap + win.thickness + Theme.space.sm
            return win.vertical ? sh - win.gap * 2
                                : sh - se - win.gap
        }

        width: targetWidth

        x: win.position === "right" ? win.gap - width - Theme.space.sm
           : win.position === "left" ? stripEnd
           : Math.round((win.width - width) / 2)
        y: win.position === "bottom" ? win.gap - height - Theme.space.sm
           : win.position === "top" ? stripEnd
           : Math.round((win.height - height) / 2)
    }

    Item {
        id: surface
        z: 2
        x: win.position === "right" ? win.width - win.gap - win.thickness : win.gap
        y: win.position === "bottom" ? win.height - win.gap - win.thickness : win.gap
        width: win.vertical ? win.thickness : Math.max(0, win.width - win.gap * 2)
        height: win.vertical ? Math.max(0, win.height - win.gap * 2) : win.thickness

        ElevationShadow {
            anchors.fill: parent
            level: 0.5
            radius: Theme.shape.radius("full", win.thickness)
            color: Theme.color.surfaceContainer
        }

        BarLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Theme.space.xs
            vertical: win.vertical

            leading: [
                LauncherModule {
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "launcher") !== false
                    onActivated: ShellState.toggleSurface("launcher")
                },
                WindowModule {
                    monitor: win.monitorName
                    vertical: win.vertical
                    cross: win.cross
                },
                BarGroup {
                    vertical: win.vertical
                    MediaModule {
                        vertical: win.vertical
                        cross: win.inner
                        visible: Config.get("modules", "media") !== false
                        onMediaRequested: ShellState.toggleSurface("media")
                    }
                }
            ]

            center: [
                BarGroup {
                    vertical: win.vertical
                    ResourcesModule {
                        vertical: win.vertical
                        cross: win.inner
                        visible: Config.get("modules", "resources") !== false
                    }
                },
                BarGroup {
                    vertical: win.vertical
                    WorkspaceStrip {
                        monitor: win.monitorName
                        vertical: win.vertical
                        itemSize: win.inner
                        visible: Config.get("modules", "workspaces") !== false
                    }
                },
                BarGroup {
                    vertical: win.vertical
                    ClockModule {
                        id: clockModule
                        vertical: win.vertical
                        cross: win.inner
                        visible: Config.get("modules", "clock") !== false
                        onClicked: ShellState.toggleDashboard(win.monitorName)
                    }
                }
            ]

            trailing: [
                BarGroup {
                    vertical: win.vertical
                    VolumeModule {
                        vertical: win.vertical
                        cross: win.inner
                        visible: Config.get("modules", "mixer") !== false
                        onMixerRequested: ShellState.toggleSurface("mixer")
                    }
                    NetworkModule {
                        vertical: win.vertical
                        cross: win.inner
                        visible: Config.get("modules", "wifi") !== false
                        onWifiRequested: ShellState.toggleSurface("wifi")
                    }
                    BatteryModule {
                        vertical: win.vertical
                        cross: win.inner
                    }
                    NotificationModule {
                        vertical: win.vertical
                        cross: win.inner
                        visible: Config.get("modules", "notifications") !== false
                    }
                },
                PowerModule {
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "power") !== false
                    onPowerRequested: ShellState.toggleSurface("power")
                    onSettingsRequested: ShellState.toggleSettings()
                }
            ]
        }

        Rectangle {
            anchors.fill: parent
            z: 100
            visible: win.debug
            color: "transparent"
            border.width: 2
            border.color: "red"
        }
    }
}
