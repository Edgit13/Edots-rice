pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// PillShell.qml (Phase 4) — уся геометрія/стиль/анімації пігулки читаються
// з Config (Config.get). Фабричні значення — Defaults.qml; reset в UI
// повертає саме їх.
//
// Фікси відносно попередньої версії:
//   1) openSurface/toggleSurface перенесено в delegate Variants + коренева
//      властивість activePillWindow — ліквідує "ReferenceError: pill is not
//      defined" під ComponentBehavior: Bound.
//   2) SettingsSurface отримує required rootWindow інлайн при конструюванні
//      (не в onLoaded) — ліквідує warning "Required property rootWindow
//      was not initialized".
// ==========================================================================

ShellRoot {
    id: root

    // IPC: дозволяє прив'язати клавішу напряму (напр. Super+Space у
    // mango/binds.conf) до відкриття лаунчера з фокусом на пошуку одразу.
    IpcHandler {
        target: "launcher"
        function open(): void {
            root.activeSurface = "launcher"
        }
    }

    // Reusable trigger icon used in the hover bar.
    component TriggerIcon: Text {
        required property string glyph
        property color hoverColor: Colors.accent
        signal activated()

        Layout.alignment: Qt.AlignVCenter
        text: glyph
        color: iconHover.hovered ? hoverColor : Colors.grey1
        scale: iconHover.hovered ? 1.18 : 1.0
        font { family: "Material Symbols Rounded"; pixelSize: 15 }

        Behavior on color { ColorAnimation { duration: Anim.ms(120) } }
        Behavior on scale { NumberAnimation { duration: Anim.ms(170); easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

        HoverHandler { id: iconHover }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    // Під ComponentBehavior: Bound id `pill` НЕ видно зі scope ShellRoot
    // (він живе в delegate Variants) — тому перемикання поверхень делегуємо
    // самому вікну, а сюди тримаємо посилання на останній delegate.
    property var activePillWindow: null

    function openSurface(surface) {
        if (activePillWindow)
            activePillWindow.openSurface(surface)
    }

    function toggleSurface(surface) {
        if (activePillWindow)
            activePillWindow.toggleSurface(surface)
    }

    IpcHandler {
        target: "pill"

        function showLauncher(): void { root.openSurface("launcher") }
        function toggleLauncher(): void { root.toggleSurface("launcher") }

        function showWallpaper(): void { root.openSurface("wallpaper") }
        function toggleWallpaper(): void { root.toggleSurface("wallpaper") }

        function showClipboard(): void { root.openSurface("clipboard") }
        function toggleClipboard(): void { root.toggleSurface("clipboard") }

        function showMixer(): void { root.openSurface("mixer") }
        function toggleMixer(): void { root.toggleSurface("mixer") }

        function showWifi(): void { root.openSurface("wifi") }
        function toggleWifi(): void { root.toggleSurface("wifi") }

        function showMedia(): void { root.openSurface("media") }
        function toggleMedia(): void { root.toggleSurface("media") }

        function showLink(): void { root.openSurface("link") }
        function toggleLink(): void { root.toggleSurface("link") }

        function showPower(): void { root.openSurface("power") }
        function togglePower(): void { root.toggleSurface("power") }

        function showNotifications(): void { notificationsProc.running = true }
        function toggleNotifications(): void { notificationsProc.running = true }

        function showSettings(): void { root.openSurface("settings") }
        function toggleSettings(): void { root.toggleSurface("settings") }

        function close(): void { root.activeSurface = "idle" }
    }

    // Full Settings application (Phase 3) — overlay window, not a pill surface.
    SettingsWindow { id: settingsWindow }

    // Великий центр керування (Phase 6)
    DashboardWindow { id: dashboardWindow }

    // Task Manager (Phase 7): порт test-implementions + utimer + upkg
    TaskManagerWindow { id: taskManagerWindow }

    // Примусова інстанціація CompositorFx (blur -> MangoWM config)
    property var compositorFxRef: CompositorFx

    IpcHandler {
        target: "dashboard"
        function open(): void { dashboardWindow.open() }
        function toggle(): void { dashboardWindow.toggle() }
        function close(): void { dashboardWindow.close() }
    }

    IpcHandler {
        target: "tasks"
        function open(): void { taskManagerWindow.open() }
        function toggle(): void { taskManagerWindow.toggle() }
        function close(): void { taskManagerWindow.close() }
    }

    IpcHandler {
        target: "settingsapp"
        function open(): void { settingsWindow.open() }
        function toggle(): void { settingsWindow.toggle() }
        function close(): void { settingsWindow.close() }
    }

    Process {
        id: notificationsProc
        command: ["sh", "-c", "swaync-client -t"]
        running: false
    }

    // "idle" (only clock) | "hover" (workspaces + clock + triggers) | surface name
    property string activeSurface: "idle"

    // ---- pill geometry / style (Phase 4: live from Config) ----
    readonly property int idleHeight: Config.get("pill", "idleHeight")
    readonly property int idleHorizontalPadding: Config.get("pill", "idleHorizontalPadding")
    readonly property int expandedWidth: Config.get("pill", "expandedWidth")
    readonly property int expandedHeight: Config.get("pill", "expandedHeight")

    readonly property int exclusionZoneGap: Config.get("bar", "exclusionZoneGap")
    readonly property bool barOnBottom: Config.get("bar", "position") === "bottom"

    // ---- module system (Phase 5): data-driven hover bar ----
    readonly property var triggerGlyphs: ({
        wallpaper: "\ue1bc", media: "\ue405", wifi: "\ue63e", link: "\ue1a7",
        power: "\uf8c7", mixer: "\ue429", clipboard: "\ue14f",
        notifications: "\ue7f4", launcher: "\ue5c3", settings: "\ue8b8"
    })

    function isTriggerIcon(id) { return root.triggerGlyphs[id] !== undefined }
    function glyphFor(id) { return root.triggerGlyphs[id] || "\ue5c3" }

    function activateModule(id) {
        if (id === "notifications") {
            notificationsProc.running = true
            return
        }
        if (id === "settings") {
            settingsWindow.toggle()
            return
        }
        root.activeSurface = id
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            exclusionMode: ExclusionMode.Normal
            exclusiveZone: root.idleHeight + root.exclusionZoneGap

            anchors {
                top: !root.barOnBottom
                bottom: root.barOnBottom
                left: true
                right: true
            }

            implicitHeight: root.idleHeight + root.exclusionZoneGap
            color: "transparent"
            mask: Region {}
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: pillWindow
            required property var modelData
            screen: modelData

            // Surface switching lives HERE, inside the delegate, because the
            // `pill` id is only in scope within this component.
            function openSurface(surface) {
                root.activeSurface = surface
                // launcher: фокус НЕ віддаємо пігулці — LauncherSurface сам ставить
                // його на searchInput у onCompleted; pill.forceActiveFocus тут
                // викрадав фокус, і доводилось клікати мишкою перед друком.
                if (surface !== "launcher")
                    pill.forceActiveFocus()
            }

            function toggleSurface(surface) {
                if (root.activeSurface === surface)
                    root.activeSurface = "idle"
                else
                    openSurface(surface)
            }

            // Multiple screens -> multiple delegates; the last one to
            // complete wins. Only affects forceActiveFocus target.
            Component.onCompleted: root.activePillWindow = pillWindow

            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0

            // Exclusive, коли відкрито поверхню з полем вводу (launcher), бо
            // OnDemand віддає клавіатуру лише ПІСЛЯ кліку мишкою по вікну.
            WlrLayershell.keyboardFocus: root.activeSurface === "launcher"
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            mask: Region { item: pill }

            Rectangle {
                id: pill
                anchors.top: root.barOnBottom ? undefined : parent.top
                anchors.bottom: root.barOnBottom ? parent.bottom : undefined
                anchors.topMargin: GameModeState.active ? 0 : Config.get("pill", "idleTopMargin")
                anchors.bottomMargin: GameModeState.active ? 0 : Config.get("pill", "idleTopMargin")
                anchors.horizontalCenter: parent.horizontalCenter

                // Central Escape handler — surfaces do not each manage their own.
                focus: true
                Keys.onEscapePressed: (event) => {
                    if (Config.get("behavior", "escapeCloses") && root.activeSurface !== "idle") {
                        root.activeSurface = "idle"
                        event.accepted = true
                    }
                }

                width: {
                    if (root.activeSurface === "idle")
                        return idleClockRow.implicitWidth + root.idleHorizontalPadding * 2
                    if (root.activeSurface === "hover")
                        return hoverRow.implicitWidth + root.idleHorizontalPadding * 2
                    return root.expandedWidth
                }
                height: (root.activeSurface === "idle" || root.activeSurface === "hover")
                    ? root.idleHeight : root.expandedHeight

                // Full stadium in idle/hover; soft corner radius when a surface is open.
                radius: GameModeState.active ? 0
                    : ((root.activeSurface === "idle" || root.activeSurface === "hover")
                        ? height / 2 : Config.get("pill", "expandedRadius"))

                color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b,
                               Config.get("pill", "backgroundOpacity"))
                clip: true

                border.width: GameModeState.active ? 0
                    : (pillHover.hovered ? Config.get("pill", "borderWidthHover")
                                         : Config.get("pill", "borderWidthDefault"))
                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                    pillHover.hovered ? 0.70 : pillGlow.opacity)

                scale: (pillHover.hovered && !GameModeState.active)
                    ? Config.get("pill", "hoverScale") : 1.0
                transformOrigin: Item.Center

                HoverHandler {
                    id: pillHover
                    onHoveredChanged: {
                        if (!Config.get("behavior", "hoverOpens"))
                            return
                        if (hovered && root.activeSurface === "idle") {
                            root.activeSurface = "hover"
                        } else if (!hovered && root.activeSurface === "hover"
                                   && Config.get("behavior", "autoCollapse")) {
                            root.activeSurface = "idle"
                        }
                    }
                }

                SequentialAnimation {
                    running: Config.get("pill", "glowEnabled") && !GameModeState.active
                    loops: Animation.Infinite
                    NumberAnimation { target: pillGlow; property: "opacity";
                        to: Config.get("pill", "glowMaxOpacity");
                        duration: Anim.ms(Config.get("pill", "glowBreathDuration") / 2); easing.type: Easing.InOutSine }
                    NumberAnimation { target: pillGlow; property: "opacity";
                        to: Config.get("pill", "glowMinOpacity");
                        duration: Anim.ms(Config.get("pill", "glowBreathDuration") / 2); easing.type: Easing.InOutSine }
                }
                QtObject {
                    id: pillGlow
                    property real opacity: Config.get("pill", "glowMinOpacity")
                }

                Behavior on width  { NumberAnimation { duration: Anim.ms(Config.get("pill", "morphDuration")); easing.type: Easing.OutBack; easing.overshoot: Config.get("pill", "morphOvershoot") } }
                Behavior on height { NumberAnimation { duration: Anim.ms(Config.get("pill", "morphDuration")); easing.type: Easing.OutBack; easing.overshoot: Config.get("pill", "morphOvershoot") } }
                Behavior on radius { NumberAnimation { duration: Anim.ms(Config.get("pill", "radiusTransitionDuration")) } }
                Behavior on scale  { NumberAnimation { duration: Anim.ms(Config.get("pill", "scaleDuration")); easing.type: Easing.OutBack; easing.overshoot: Config.get("pill", "scaleOvershoot") } }
                Behavior on border.width { NumberAnimation { duration: Anim.ms(Config.get("pill", "borderTransitionDuration")) } }
                Behavior on border.color { ColorAnimation  { duration: Anim.ms(Config.get("pill", "borderTransitionDuration")) } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Config.get("behavior", "clickOutsideCloses")
                            && root.activeSurface !== "idle"
                            && root.activeSurface !== "hover")
                            root.activeSurface = "idle"
                    }
                }

                // ---- idle state: clock only ----
                Item {
                    id: idleClockRow
                    anchors.centerIn: parent
                    implicitWidth: idleClock.implicitWidth
                    implicitHeight: idleClock.implicitHeight
                    visible: root.activeSurface === "idle"
                    opacity: visible ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }

                    Clock {
                        id: idleClock
                        anchors.centerIn: parent
                    }
                }

                // ---- hover state: Workspaces + Clock + trigger icons ----
                RowLayout {
                    id: hoverRow
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.activeSurface === "hover"
                    opacity: visible ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }

                    Repeater {
                        model: Config.get("modules", "order") || []
                        RowLayout {
                            required property var modelData
                            required property int index
                            spacing: 10
                            visible: !!Config.get("modules", modelData)

                            readonly property bool wide: modelData === "workspaces" || modelData === "clock"
                            readonly property bool prevWide: {
                                const order = Config.get("modules", "order") || []
                                if (index <= 0)
                                    return false
                                const p = order[index - 1]
                                return p === "workspaces" || p === "clock"
                            }

                            Rectangle {
                                visible: index > 0 && (wide || prevWide)
                                width: 1
                                Layout.alignment: Qt.AlignVCenter
                                Layout.fillHeight: true
                                Layout.topMargin: 4
                                Layout.bottomMargin: 4
                                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)
                            }

                            Workspaces {
                                visible: modelData === "workspaces"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            Clock {
                                visible: modelData === "clock"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            TriggerIcon {
                                visible: root.isTriggerIcon(modelData)
                                glyph: root.glyphFor(modelData)
                                hoverColor: modelData === "power" ? Colors.red : Colors.accent
                                onActivated: root.activateModule(modelData)
                            }
                        }
                    }
                }

                // ---- surfaces — loaded on demand, unloaded when closed ----
                // margins: Config "surfaces.margins"

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "wallpaper"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: WallpaperSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "media"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: MediaSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "power"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: PowerSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "mixer"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: MixerSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "clipboard"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: ClipboardSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "launcher"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: LauncherSurface {}
                    onLoaded: item.appLaunched.connect(function() {
                        if (Config.get("behavior", "closeOnLaunch"))
                            root.activeSurface = "idle"
                    })
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "wifi"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: WifiSurface {}
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "settings"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    // required property передається ІНЛАЙН при конструюванні —
                    // присвоєння в onLoaded давало warning про required prop.
                    sourceComponent: SettingsSurface { rootWindow: root }
                }

                Loader {
                    anchors.fill: parent; anchors.margins: Config.get("surfaces", "margins")
                    active: root.activeSurface === "link"
                    opacity: active ? 1 : 0
                    scale: active ? 1.0 : 0.985
                    Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }
                    Behavior on scale { NumberAnimation { duration: Anim.ms(200); easing.type: Easing.OutCubic } }
                    sourceComponent: LinkSurface {}
                }
            }
        }
    }
}
