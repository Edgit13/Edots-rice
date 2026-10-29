import "root:/theme"
import "root:/shell"
import "root:/modules/common"
import "root:/modules/workspace"
import "root:/modules/resources"
import "root:/modules/gamemode"
import "root:/modules/record"
import "root:/modules/launcher"
import "root:/modules/window"
import "root:/modules/clock"
import "root:/modules/volume"
import "root:/modules/network"
import "root:/modules/battery"
import "root:/modules/media"
import "root:/modules/notifications"
import "root:/modules/power"
import "root:/surfaces"
import "root:/states"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string monitorName: modelData.name
    readonly property string configuredPosition: BarConfig.positionFor(monitorName)
    // pill — горизонтальний острів: для left/right (де його обрізало б по ширині вікна) падаємо на top
    readonly property string position: (pill && (configuredPosition === "left" || configuredPosition === "right")) ? "top" : configuredPosition
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int thickness: BarConfig.thicknessFor(monitorName)
    readonly property bool pill: BarConfig.style === "pill"
    readonly property bool pillMorph: BarConfig.pillMorph

    // відкрити панель з пілла: морф — всередині пілла; інші режими — загальна поверхня (вікно/spotlight/шторка)
    function openPanel(name) {
        if (pillMorph) {
            pillSurface.activePanel = name
            pillSurface.surfaceState = "expanded"
        } else if (name === "dashboard") {
            ShellState.toggleDashboard(win.monitorName)
        } else {
            ShellState.toggleSurface(name, win.monitorName)
        }
    }
    // ігровий режим + «плоский бар»: без заокруглень, зовнішніх відступів і тіні (лише повний бар)
    readonly property bool flat: !pill && GameModeState.active && GameModeState.optFlatBar
    readonly property int gap: pill ? BarConfig.pillEdgeGap : (flat ? 0 : Theme.space.screenMargin)
    readonly property int reserve: thickness + gap * 2
    readonly property int cross: thickness - Theme.space.xs * 2
    readonly property int inner: cross - Theme.space.xxs * 2

    readonly property var morphModules: [dashboardSurface, pillSurface]

    // панелі, що морфяться з пілла: [ширина, висота] (dashboard рахується окремо)
    readonly property var pillPanelSize: ({
        wifi: [460, 440], mixer: [480, 420], media: [460, 320], power: [360, 290], launcher: [560, 520],
        wallpaper: [620, 480], clipboard: [540, 480], binds: [700, 620], resources: [560, 620]
    })
    readonly property var pillPanelIds: ["wifi", "mixer", "media", "power", "launcher", "wallpaper", "clipboard", "binds", "resources"]
    readonly property var pillComponents: ({
        dashboard: pDashboard, wifi: pWifi, mixer: pMixer, media: pMedia, power: pPower, launcher: pLauncher,
        wallpaper: pWallpaper, clipboard: pClipboard, binds: pBinds, resources: pResources
    })
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

    WlrLayershell.namespace: "edots-bar"
    WlrLayershell.keyboardFocus: (dashOpen || (pill && pillSurface.surfaceState === "expanded")) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
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
        Region {
            x: 0; y: 0
            width: (win.pill && pillSurface.surfaceState === "expanded") ? win.width : 0
            height: (win.pill && pillSurface.surfaceState === "expanded") ? win.height : 0
        }
        Region { item: win.pill ? pillSurface.bodyItem : surface }
        Region { item: win.dashOpen ? dashboardSurface : null }
    }

    // зміна режиму відкриття — закрити все відкрите
    Connections {
        target: BarConfig
        function onOpenModeChanged() { pillSurface.collapse(); ShellState.closeSurfaces() }
    }

    function _forThisMonitor(monitor) { return !monitor || monitor === "" || monitor === win.monitorName }

    Connections {
        target: ShellState

        // pill-режим: IPC/кнопки дашборду керують піллом, а не окремою поверхнею
        function onOpenDashboardRequested(monitor) {
            if (!win.pillMorph || !win._forThisMonitor(monitor)) return
            pillSurface.activePanel = "dashboard"
            pillSurface.surfaceState = "expanded"
        }
        function onToggleDashboardRequested(monitor) {
            if (!win.pillMorph || !win._forThisMonitor(monitor)) return
            if (pillSurface.surfaceState === "expanded" && pillSurface.activePanel === "dashboard") {
                pillSurface.collapse()
            } else {
                pillSurface.activePanel = "dashboard"
                pillSurface.surfaceState = "expanded"
            }
        }
        function onCloseDashboardRequested() {
            if (win.pillMorph && pillSurface.activePanel === "dashboard") pillSurface.collapse()
        }

        function onActiveSurfaceChanged() {
            if (!win.pillMorph) return
            const s = ShellState.activeSurface
            if (s === "idle" || s === "") {
                pillSurface.collapse()
            } else if (win.pillPanelIds.includes(s)) {
                if (ShellState.activeMonitor === win.monitorName || !ShellState.activeMonitor || ShellState.activeMonitor === "") {
                    pillSurface.activePanel = s
                    pillSurface.surfaceState = "expanded"
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: win.pill && pillSurface.surfaceState === "expanded"
        z: 1
        onClicked: {
            pillSurface.collapse()
            ShellState.closeSurfaces()
        }
    }

    DashboardSurface {
        id: dashboardSurface
        z: 1
        listenShell: !win.pill          // у pill-режимі дашборд живе всередині пілла
        hostMonitor: win.monitorName
        revealDirection: win.position

        readonly property real stripEnd: win.gap + win.thickness + Theme.space.sm
        readonly property real targetWidth: win.vertical ? Math.min(800, win.width - stripEnd - win.gap * 2)
                                                         : Math.min(920, win.width - win.gap * 4)

        maxHeight: {
            const sh = win.screen ? win.screen.height : 1080
            const se = win.gap + win.thickness + Theme.space.sm
            return win.vertical ? sh - win.gap * 2 : sh - se - win.gap
        }

        width: targetWidth
        // Вікно росте від краю бару, тож для right/bottom відступ рахуємо від протилежного краю вікна
        x: win.position === "right" ? win.width - stripEnd - width
           : win.position === "left" ? stripEnd
           : Math.round((win.width - width) / 2)
        y: win.position === "bottom" ? win.height - stripEnd - height
           : win.position === "top" ? stripEnd
           : Math.round((win.height - height) / 2)
    }

    // ---- ПОВНИЙ БАР (Full Mode) ----
    Item {
        id: surface
        z: 2
        
        // ВИПРАВЛЕНО: використовуємо ТІЛЬКИ opacity та enabled, без visible: false
        opacity: win.pill ? 0 : 1
        enabled: !win.pill
        scale: win.pill ? 0.88 : 1.0
        transformOrigin: Item.Center

        Behavior on opacity { MotionAnimation { role: "fade" } }
        Behavior on scale { MotionAnimation { role: "morph" } }

        x: win.position === "right" ? win.width - win.gap - win.thickness : win.gap
        y: win.position === "bottom" ? win.height - win.gap - win.thickness : win.gap
        width: win.vertical ? win.thickness : Math.max(0, win.width - win.gap * 2)
        height: win.vertical ? Math.max(0, win.height - win.gap * 2) : win.thickness

        ElevationShadow {
            anchors.fill: parent
            level: win.flat ? 0 : 0.5
            radius: win.flat ? 0 : Theme.shape.radius("full", win.thickness)
            color: Theme.settings.nothing ? Theme.color.surface : Theme.color.surfaceContainer
        }

        BarLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Theme.space.xs
            vertical: win.vertical

            leading: [
                LauncherModule {
                    vertical: win.vertical; cross: win.cross
                    enabledByConfig: BarConfig.moduleEnabled("launcher")
                    onActivated: ShellState.toggleSurface("launcher", win.monitorName)
                },
                WindowModule {
                    monitor: win.monitorName; vertical: win.vertical; cross: win.cross
                    enabledByConfig: BarConfig.moduleEnabled("window")
                },
                BarGroup {
                    vertical: win.vertical
                    MediaModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("media")
                        onMediaRequested: ShellState.toggleSurface("media", win.monitorName)
                    }
                }
            ]

            center: [
                BarGroup {
                    vertical: win.vertical
                    ResourcesModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("resources")
                        onResourcesRequested: ShellState.toggleSurface("resources", win.monitorName)
                    }
                },
                BarGroup {
                    vertical: win.vertical
                    WorkspaceStrip {
                        monitor: win.monitorName; vertical: win.vertical; itemSize: win.inner
                        visible: BarConfig.moduleEnabled("workspaces")
                    }
                },
                BarGroup {
                    vertical: win.vertical
                    ClockModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("clock")
                        onClicked: ShellState.toggleDashboard(win.monitorName)
                    }
                }
            ]

            trailing: [
                BarGroup {
                    vertical: win.vertical
                    RecordModule { vertical: win.vertical; cross: win.inner }
                    GameModeModule { vertical: win.vertical; cross: win.inner }
                    VolumeModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("mixer")
                        onMixerRequested: ShellState.toggleSurface("mixer", win.monitorName)
                    }
                    NetworkModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("wifi")
                        onWifiRequested: ShellState.toggleSurface("wifi", win.monitorName)
                    }
                    BatteryModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("battery")
                    }
                    NotificationModule {
                        vertical: win.vertical; cross: win.inner
                        enabledByConfig: BarConfig.moduleEnabled("notifications")
                    }
                },
                PowerModule {
                    vertical: win.vertical; cross: win.cross
                    enabledByConfig: BarConfig.moduleEnabled("power")
                    onPowerRequested: ShellState.toggleSurface("power", win.monitorName)
                    onSettingsRequested: ShellState.toggleSettings()
                }
            ]
        }
    }

    // ---- ПІГУЛКА (Pill Mode) ----
    MorphSurface {
        id: pillSurface
        z: 2

        opacity: win.pill ? 1 : 0
        enabled: win.pill
        scale: win.pill ? 1.0 : 0.88
        transformOrigin: Item.Center

        Behavior on opacity { MotionAnimation { role: "fade" } }
        Behavior on scale { MotionAnimation { role: "morph" } }

        x: win.vertical ? (win.position === "right" ? win.width - win.gap - win.thickness : win.gap)
                        : Math.round((win.width - width) / 2)
        y: win.vertical ? Math.round((win.height - height) / 2)
                        : (win.position === "bottom" ? win.height - win.gap - win.thickness : win.gap)

        property string activePanel: ""

        onSurfaceStateChanged: {
            if (surfaceState === "compact") {
                activePanel = ""
                ShellState.closeSurfaces()
            }
        }
        onVisibleChanged: if (!visible) { surfaceState = "compact"; activePanel = "" }

        originX: 0.5
        originY: win.position === "bottom" ? 1.0 : 0.0

        closeOnEscape: BarConfig.pillCloseOnEscape
        baseColor: Theme.settings.nothing ? Theme.color.surface : Theme.color.surfaceContainer

        compactWidth: compactRow.implicitWidth + Theme.space.lg * 2
        compactHeight: win.thickness

        hoverWidth: BarConfig.pillHover ? hoverRow.implicitWidth + Theme.space.lg * 2 : 0
        hoverHeight: win.thickness

        expandedWidth: {
            if (activePanel === "dashboard") return Math.min(920, screen.width - win.gap * 4)
            const s = win.pillPanelSize[activePanel]
            if (s) return Math.min(s[0], screen.width - win.gap * 4)
            return hoverRow.implicitWidth + Theme.space.lg * 2
        }
        expandedHeight: {
            if (activePanel === "dashboard") return Math.min(760, screen.height - win.thickness - win.gap * 4)
            const s = win.pillPanelSize[activePanel]
            if (s) return Math.min(s[1], screen.height - win.thickness - win.gap * 4)
            return win.thickness
        }

        onClicked: {
            if (surfaceState === "expanded") {
                activePanel = ""
                surfaceState = "compact"
                ShellState.closeSurfaces()
            }
        }

        compact: [
            RowLayout {
                id: compactRow
                anchors.centerIn: parent
                spacing: Theme.space.md

                WorkspaceStrip {
                    Layout.alignment: Qt.AlignVCenter
                    monitor: win.monitorName; itemSize: win.inner; compact: true
                    visible: BarConfig.moduleEnabled("workspaces")
                }
                ClockModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("clock")
                    onClicked: win.openPanel("dashboard")
                }
                // з'являються лише під час запису / ігрового режиму; клік зупиняє
                RecordModule   { Layout.alignment: Qt.AlignVCenter; cross: win.inner }
                GameModeModule { Layout.alignment: Qt.AlignVCenter; cross: win.inner }
            }
        ]

        hover: [
            RowLayout {
                id: hoverRow
                anchors.centerIn: parent
                spacing: Theme.space.sm

                LauncherModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("launcher")
                    onActivated: win.openPanel("launcher")
                }
                WindowModule {
                    Layout.alignment: Qt.AlignVCenter
                    monitor: win.monitorName; cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("window")
                }
                WorkspaceStrip {
                    Layout.alignment: Qt.AlignVCenter
                    monitor: win.monitorName; itemSize: win.inner; compact: true
                    visible: BarConfig.moduleEnabled("workspaces")
                }
                ClockModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("clock")
                    onClicked: win.openPanel("dashboard")
                }
                ResourcesModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("resources")
                    onResourcesRequested: win.openPanel("resources")
                }
                MediaModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("media")
                    onMediaRequested: win.openPanel("media")
                }
                VolumeModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("mixer")
                    onMixerRequested: win.openPanel("mixer")
                }
                NetworkModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("wifi")
                    onWifiRequested: win.openPanel("wifi")
                }
                BatteryModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("battery")
                }
                RecordModule   { Layout.alignment: Qt.AlignVCenter; cross: win.inner }
                GameModeModule { Layout.alignment: Qt.AlignVCenter; cross: win.inner }
                PowerModule {
                    Layout.alignment: Qt.AlignVCenter
                    cross: win.inner
                    enabledByConfig: BarConfig.moduleEnabled("power")
                    onPowerRequested: win.openPanel("power")
                }
            }
        ]

        expanded: [
            Item {
                anchors.fill: parent
                Loader {
                    anchors.fill: parent
                    active: pillSurface.activePanel !== ""
                    opacity: active ? 1 : 0
                    Behavior on opacity { MotionAnimation { role: "fade" } }
                    sourceComponent: win.pillComponents[pillSurface.activePanel] || null
                }
            }
        ]
    }

    Component { id: pDashboard; DashboardSurface { anchors.fill: parent; occupies: true; listenShell: false; hostMonitor: win.monitorName; revealDirection: win.position } }
    Component { id: pWifi; WifiSurface { anchors.fill: parent } }
    Component { id: pMixer; MixerSurface { anchors.fill: parent } }
    Component { id: pMedia; MediaSurface { anchors.fill: parent } }
    Component { id: pPower; PowerSurface { anchors.fill: parent } }
    Component { id: pWallpaper; WallpaperSurface { anchors.fill: parent } }
    Component { id: pClipboard; ClipboardSurface { anchors.fill: parent } }
    Component { id: pBinds; BindsSurface { anchors.fill: parent } }
    Component { id: pResources; ResourcesSurface { anchors.fill: parent; onRequestClose: pillSurface.collapse() } }
    Component { id: pLauncher; LauncherSurface { anchors.fill: parent; onAppLaunched: pillSurface.collapse() } }
}
