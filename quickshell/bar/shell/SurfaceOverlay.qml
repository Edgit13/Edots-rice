import "root:/surfaces"
import "root:/theme"
import "root:/shell"
import "root:/services"
import "root:/settings"
import "root:/settings/material"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// SurfaceOverlay — поверхні (Launcher, Wifi, Mixer, Clipboard, Media, Power, Wallpaper) у стилі end-4:
// просто плаваюча панель біля бару — без scrim, без повноекранної поверхні (отже й без блюру).
//  • launcher / clipboard / wallpaper — по центру краю бару, як пошук в end-4
//  • mixer / wifi / media / power — ближче до кута (кінець бару)
//  • вікно = лише картка; закриття: повторний клік по модулю, Esc, ✕
// "dashboard" тут ігнорується: він морфиться з самої смуги (DashboardSurface у BarWindow).
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string monitorName: modelData.name
    readonly property bool isCurrentMonitor: {
        if (ShellState.activeMonitor && ShellState.activeMonitor.length > 0)
            return ShellState.activeMonitor === monitorName
        return MangoService.focusedMonitor === monitorName
    }

    readonly property var overlaySurfaces: ["launcher", "wallpaper", "clipboard", "mixer", "wifi", "media", "power", "binds", "resources"]
    readonly property string activeSurface: ShellState.activeSurface
    readonly property bool isAllowedSurface: overlaySurfaces.indexOf(activeSurface) >= 0
    readonly property bool isOpen: isAllowedSurface
        && (isCurrentMonitor || Quickshell.screens.length === 1)

    // тримаємо поверхню, поки грає анімація закриття
    property string shownSurface: "idle"
    // не покладаємось на isAllowedSurface: його binding може оновитись ПІСЛЯ цього обробника
    onActiveSurfaceChanged: if (overlaySurfaces.indexOf(activeSurface) >= 0) shownSurface = activeSurface
    onVisibleChanged: if (!visible) shownSurface = "idle"
    Component.onCompleted: if (overlaySurfaces.indexOf(activeSurface) >= 0) shownSurface = activeSurface

    readonly property var meta: ({
        launcher:  { icon: "\ue5c3", title: "ui.surface.launcher",  w: 560, h: 520, end: false, typing: true },
        wallpaper: { icon: "\ue1bc", title: "ui.surface.wallpaper", w: 620, h: 480, end: false, typing: false },
        clipboard: { icon: "\ue14f", title: "ui.surface.clipboard", w: 540, h: 480, end: false, typing: true },
        mixer:     { icon: "\ue429", title: "ui.surface.mixer",     w: 480, h: 420, end: true,  typing: false },
        wifi:      { icon: "\ue63e", title: "ui.surface.wifi",      w: 460, h: 440, end: true,  typing: false },
        media:     { icon: "\ue405", title: "ui.surface.media",     w: 460, h: 320, end: true,  typing: false },
        power:     { icon: "\ue8ac", title: "ui.surface.power",     w: 360, h: 290, end: true,  typing: false },
        binds:     { icon: "\ue312", title: "ui.surface.binds",     w: 700, h: 620, end: false, typing: true },
        resources: { icon: "\ue322", title: "ui.surface.resources", w: 560, h: 620, end: false, typing: false }
    })
    readonly property var m: meta[shownSurface] || meta.launcher

    // ---- розташування відносно бару ----
    readonly property string bar: BarConfig.positionFor(monitorName)
    readonly property bool vertical: bar === "left" || bar === "right"
    readonly property real pad: Theme.components.dp(16)                       // запас під тінь і зсув
    readonly property real reserve: BarConfig.thicknessFor(monitorName) + Theme.space.md * 2
    readonly property real edgeM: Math.max(0, reserve - pad)                  // від краю екрана до картки = reserve
    readonly property real sideM: Math.max(0, Theme.space.lg - pad)
    readonly property real startM: Math.max(0, Theme.space.md - pad)

    visible: isOpen || card.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: win.bar === "top" || win.vertical
        bottom: win.bar === "bottom"
        left: win.bar === "left"
        right: win.bar === "right" || (!win.vertical && win.m.end)
    }
    margins {
        top: win.bar === "top" ? win.edgeM : (win.vertical ? win.startM + pad : 0)
        bottom: win.bar === "bottom" ? win.edgeM : 0
        left: win.bar === "left" ? win.edgeM : 0
        right: win.bar === "right" ? win.edgeM : ((!win.vertical && win.m.end) ? win.sideM : 0)
    }

    implicitWidth: card.width + pad * 2
    implicitHeight: card.height + pad * 2
    mask: Region { item: card }                                               // клік повз картку проходить наскрізь

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "m3-surface"
    WlrLayershell.keyboardFocus: isOpen
        ? (m.typing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
        : WlrKeyboardFocus.None

    onIsOpenChanged: if (isOpen) card.forceActiveFocus()

    Item {
        id: card
        width: Theme.components.dp(win.m.w)
        height: Theme.components.dp(win.m.h)
        anchors.centerIn: parent
        focus: true

        // виїзд з боку бару
        readonly property real dirX: win.bar === "left" ? -1 : (win.bar === "right" ? 1 : 0)
        readonly property real dirY: win.bar === "top" ? -1 : (win.bar === "bottom" ? 1 : 0)
        property real slide: win.isOpen ? 0 : Theme.components.dp(14)
        anchors.horizontalCenterOffset: dirX * slide
        anchors.verticalCenterOffset: dirY * slide

        scale: win.isOpen ? 1 : 0.92
        opacity: win.isOpen ? 1 : 0
        transformOrigin: win.bar === "bottom" ? Item.Bottom : (win.bar === "top" ? Item.Top : (win.bar === "left" ? Item.Left : Item.Right))
        Behavior on slide   { MotionAnimation { role: win.isOpen ? "move" : "exit" } }
        Behavior on scale   { MotionAnimation { role: win.isOpen ? "expand" : "collapse" } }
        Behavior on opacity { MotionAnimation { role: win.isOpen ? "enter" : "exit" } }

        Keys.onEscapePressed: function (e) {
            ShellState.closeSurfaces()
            e.accepted = true
        }

        ElevationShadow {
            anchors.fill: parent
            level: 0.5
            radius: Theme.shape.dialog
            color: Theme.color.surfaceContainerHigh
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.dialog
            color: Theme.color.surfaceContainerHigh
            border.width: 1
            border.color: Theme.color.outlineVariant
            clip: true

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.lg
                spacing: Theme.space.md

                // заголовок
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.sm

                    Rectangle {
                        implicitWidth: Theme.components.dp(36)
                        implicitHeight: implicitWidth
                        radius: Theme.shape.radius("lg", height)
                        color: Theme.color.primaryContainer
                        Text {
                            anchors.centerIn: parent
                            text: win.m.icon
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                            color: Theme.color.fgPrimaryContainer
                        }
                    }
                    ThemedText {
                        text: Lang.t(win.m.title)
                        style: Theme.type.titleMedium
                        emphasized: true
                    }
                    Item { Layout.fillWidth: true }
                    MaterialIconButton {
                        icon: "close"
                        onClicked: ShellState.closeSurfaces()
                    }
                }

                // вміст
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "launcher"
                        visible: active
                        sourceComponent: LauncherSurface {}
                        onLoaded: {
                            if (item && item.appLaunched)
                                item.appLaunched.connect(function () { ShellState.closeSurfaces() })
                        }
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "wallpaper"
                        visible: active
                        sourceComponent: WallpaperSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "clipboard"
                        visible: active
                        sourceComponent: ClipboardSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "mixer"
                        visible: active
                        sourceComponent: MixerSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "wifi"
                        visible: active
                        sourceComponent: WifiSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "media"
                        visible: active
                        sourceComponent: MediaSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "power"
                        visible: active
                        sourceComponent: PowerSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "binds"
                        visible: active
                        sourceComponent: BindsSurface {}
                    }
                    Loader {
                        anchors.fill: parent
                        active: win.shownSurface === "resources"
                        visible: active
                        sourceComponent: ResourcesSurface {}
                        onLoaded: {
                            if (item && item.requestClose)
                                item.requestClose.connect(function () { ShellState.closeSurfaces() })
                        }
                    }
                }
            }
        }
    }
}
