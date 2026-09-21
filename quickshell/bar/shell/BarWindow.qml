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

    readonly property bool debug: Quickshell.env("EDOTS_BAR_DEBUG") === "1"

    WlrLayershell.namespace: "edots-bar"
    color: "transparent"

    // Вікно прилягає до краю екрана: 3 якорі (вздовж осі + сам край)
    anchors {
        top: position === "top" || vertical
        bottom: position === "bottom" || vertical
        left: position === "left" || !vertical
        right: position === "right" || !vertical
    }
    implicitWidth: vertical ? reserve : 0
    implicitHeight: vertical ? 0 : reserve
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: reserve

    // Клікабельна лише сама смуга; решта вікна прозора для вказівника
    mask: Region { item: surface }

    // Геометрія рахується явно (x/y/width/height), а не якорями
    Item {
        id: surface
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
                    vertical: win.vertical
                    cross: win.cross
                    onClicked: ShellState.toggleDashboard()
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
