import "root:/"
import "root:/theme"
import "root:/shell"
import "root:/modules/workspace"
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

// BarWindow — один PanelWindow на монітор. Позиція (top/bottom/left/right) береться з BarConfig
// (глобально або override для цього монітора); layout перебудовується автоматично.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string monitorName: modelData.name
    readonly property string position: BarConfig.positionFor(monitorName)
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int thickness: BarConfig.thicknessFor(monitorName)
    readonly property int gap: Theme.space.screenMargin
    readonly property int reserve: thickness + gap * 2          // відступ від краю + смуга + відступ до вікон
    readonly property int cross: thickness - Theme.space.xs * 2 // розмір контенту впоперек осі смуги

    // Dashboard живе всередині цього вікна. Поки він occupies —
    // вікно розширюється вниз/вбік на freeOverflow, тайлінг не рухається,
    // бо exclusiveZone лишається постійним (reserve).
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
        return _maxOverflow("overflowLeft")   // right
    }

    readonly property bool debug: Quickshell.env("EDOTS_BAR_DEBUG") === "1"

    // Sync Config bar.position → BarConfig so the settings dropdown moves the bar
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

    // Вікно прилягає до краю екрана (3 якорі: вздовж осі + сам край).
    // Розмір розширюється на freeOverflow, коли відкривається дашборд.
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

    // Клікабельні: смуга + (коли дашборд відкритий) сама картка дашборда
    mask: Region {
        Region { item: surface }
        Region { item: win.dashOpen ? dashboardSurface : null }
    }

    // ---- Dashboard: морфиться з смуги (закріплений під/над/збоку смуги) ----
    DashboardSurface {
        id: dashboardSurface
        z: 1
        hostMonitor: win.monitorName

        readonly property real stripEnd: win.gap + win.thickness + Theme.space.sm
        readonly property real targetWidth: win.vertical ? Math.min(800, win.width - stripEnd - win.gap * 2)
                                                         : Math.min(920, win.width - win.gap * 4)

        maxHeight: win.vertical ? win.height - win.gap * 2
                                : win.height - stripEnd - win.gap

        width: targetWidth

        x: win.position === "right" ? win.gap - width - Theme.space.sm
           : win.position === "left" ? stripEnd
           : Math.round((win.width - width) / 2)
        y: win.position === "bottom" ? win.gap - height - Theme.space.sm
           : win.position === "top" ? stripEnd
           : Math.round((win.height - height) / 2)
    }

    // Геометрія рахується явно (x/y/width/height), а не якорями
    Item {
        id: surface
        z: 2
        x: win.position === "right" ? win.width - win.gap - win.thickness : win.gap
        y: win.position === "bottom" ? win.height - win.gap - win.thickness : win.gap
        width: win.vertical ? win.thickness : Math.max(0, win.width - win.gap * 2)
        height: win.vertical ? Math.max(0, win.height - win.gap * 2) : win.thickness

        ElevationShadow {
            anchors.fill: parent
            level: BarConfig.elevation
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
                WorkspaceStrip {
                    monitor: win.monitorName
                    vertical: win.vertical
                    itemSize: win.cross - Theme.space.sm
                    visible: Config.get("modules", "workspaces") !== false
                },
                WindowModule {
                    monitor: win.monitorName
                    vertical: win.vertical
                    cross: win.cross
                }
            ]

            center: [
                ClockModule {
                    id: clockModule
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "clock") !== false
                    onClicked: ShellState.toggleDashboard(win.monitorName)
                }
            ]

            trailing: [
                MediaModule {
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "media") !== false
                    onMediaRequested: ShellState.toggleSurface("media")
                },
                VolumeModule {
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "mixer") !== false
                    onMixerRequested: ShellState.toggleSurface("mixer")
                },
                NetworkModule {
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "wifi") !== false
                    onWifiRequested: ShellState.toggleSurface("wifi")
                },
                BatteryModule {
                    vertical: win.vertical
                    cross: win.cross
                },
                NotificationModule {
                    vertical: win.vertical
                    cross: win.cross
                    visible: Config.get("modules", "notifications") !== false
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

        Rectangle {   // діагностика: контур смуги при EDOTS_BAR_DEBUG=1
            anchors.fill: parent
            z: 100
            visible: win.debug
            color: "transparent"
            border.width: 2
            border.color: "red"
        }
    }
}
