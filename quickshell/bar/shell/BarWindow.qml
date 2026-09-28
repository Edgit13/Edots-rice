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

    // Dashboard тепер живе всередині цього вікна (не окреме вікно!). Поки він occupies —
    // вікно розширюється (або йде на весь екран для scrim), тайлінг не рухається,
    // бо exclusiveZone лишається тонким.
    readonly property var morphModules: [dashboardSurface]
    readonly property bool dashOpen: dashboardSurface.occupies
    readonly property bool fillScreen: dashOpen && !vertical    // горизонтальний бар: scrim на весь екран

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

    WlrLayershell.namespace: "edots-bar"
    WlrLayershell.keyboardFocus: dashOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"

    // Вікно прилягає до краю екрана: 3 якорі (вздовж осі + сам край).
    // Коли дашборд відкритий — горизонтальний бар розтягується на весь екран (прозорий,
    // клікабельність обмежена mask), щоб scrim міг ловити кліки поза карткою.
    anchors {
        top: position === "top" || vertical || fillScreen
        bottom: position === "bottom" || vertical || fillScreen
        left: position === "left" || !vertical || fillScreen
        right: position === "right" || !vertical || fillScreen
    }
    implicitWidth: vertical ? reserve + freeOverflow : 0
    implicitHeight: vertical ? 0 : (fillScreen ? 0 : reserve + freeOverflow)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: reserve

    // Клікабельні: смуга + (коли дашборд відкритий) scrim і сама картка дашборда
    mask: Region {
        Region { item: surface }
        Region { item: win.dashOpen ? scrim : null }
        Region { item: win.dashOpen ? dashboardSurface : null }
    }

    Keys.onEscapePressed: ShellState.closeSurfaces()

    // ---- Scrim: клік поза дашбордом закриває його (лише поки dashOpen) ----
    Rectangle {
        id: scrim
        z: 0
        anchors.fill: parent
        visible: win.dashOpen
        color: Theme.color.scrim
        opacity: visible ? 0.45 : 0
        Behavior on opacity { MotionAnimation { role: "enter" } }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeSurfaces()
        }
    }

    // ---- Dashboard: морфиться з смуги (закріплений під/над/збоку смуги) ----
    DashboardSurface {
        id: dashboardSurface
        z: 1
        hostMonitor: win.monitorName

        readonly property real stripEnd: win.gap + win.thickness + Theme.space.sm
        maxHeight: win.vertical ? win.height - win.gap * 2
                                : win.height - stripEnd - win.gap

        x: win.position === "right" ? win.gap - width - Theme.space.sm
           : win.position === "left" ? stripEnd
           : win.gap
        y: win.position === "bottom" ? win.gap - height - Theme.space.sm
           : win.position === "top" ? stripEnd
           : win.gap
        width: win.vertical ? Math.min(900, win.width - stripEnd - win.gap)
                            : win.width - win.gap * 2
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
                    onActivated: ShellState.toggleSurface("launcher")
                },
                WorkspaceStrip {
                    monitor: win.monitorName
                    vertical: win.vertical
                    itemSize: win.cross - Theme.space.sm
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
                }
            ]

            trailing: [
                MediaModule {
                    vertical: win.vertical
                    cross: win.cross
                    onMediaRequested: ShellState.toggleSurface("media")
                },
                VolumeModule {
                    vertical: win.vertical
                    cross: win.cross
                    onMixerRequested: ShellState.toggleSurface("mixer")
                },
                NetworkModule {
                    vertical: win.vertical
                    cross: win.cross
                    onWifiRequested: ShellState.toggleSurface("wifi")
                },
                BatteryModule {
                    vertical: win.vertical
                    cross: win.cross
                },
                NotificationModule {
                    vertical: win.vertical
                    cross: win.cross
                },
                PowerModule {
                    vertical: win.vertical
                    cross: win.cross
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
