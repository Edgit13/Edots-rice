import "root:/"
import "root:/theme"
import "root:/shell"
import "root:/services"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// SurfaceOverlay — M3 Expressive плаваюче спливаюче вікно для поверхонь
// (Launcher, Wifi, Mixer, Clipboard, Media, Power, Wallpaper).
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string monitorName: modelData.name
    readonly property bool isCurrentMonitor: {
        const focusedMon = MangoService.focusedClient.monitor
        if (focusedMon && focusedMon.length > 0) return focusedMon === monitorName
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === monitorName
    }

    readonly property string activeSurface: ShellState.activeSurface
    readonly property bool isOpen: activeSurface !== "idle" && (isCurrentMonitor || Quickshell.screens.length === 1)

    visible: isOpen
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (isOpen && activeSurface === "launcher")
        ? WlrKeyboardFocus.Exclusive
        : (isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None)

    mask: Region {
        item: isOpen ? scrim : null
    }

    // Scrim backdrop
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Theme.color.scrim
        opacity: win.isOpen ? 0.45 : 0
        Behavior on opacity { MotionAnimation { role: win.isOpen ? "enter" : "exit" } }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeSurfaces()
        }

        // Центральна картка поверхні (M3 Expressive)
        Item {
            id: cardContainer
            anchors.centerIn: parent

            property real cardW: {
                if (win.activeSurface === "launcher") return 560
                if (win.activeSurface === "wallpaper") return 620
                if (win.activeSurface === "clipboard") return 540
                if (win.activeSurface === "mixer") return 480
                if (win.activeSurface === "wifi") return 460
                if (win.activeSurface === "media") return 460
                if (win.activeSurface === "power") return 360
                return 480
            }
            property real cardH: {
                if (win.activeSurface === "launcher") return 520
                if (win.activeSurface === "wallpaper") return 480
                if (win.activeSurface === "clipboard") return 480
                if (win.activeSurface === "mixer") return 420
                if (win.activeSurface === "wifi") return 440
                if (win.activeSurface === "media") return 320
                if (win.activeSurface === "power") return 290
                return 400
            }

            width: cardW
            height: cardH
            scale: win.isOpen ? 1.0 : 0.92
            opacity: win.isOpen ? 1.0 : 0.0

            Behavior on width { MotionAnimation { role: "morph" } }
            Behavior on height { MotionAnimation { role: "morph" } }
            Behavior on scale { MotionAnimation { role: "press" } }
            Behavior on opacity { MotionAnimation { role: win.isOpen ? "enter" : "exit" } }

            ElevationShadow {
                anchors.fill: parent
                level: 4
                radius: Theme.shape.dialog
                color: Theme.color.surfaceContainerHigh
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: Theme.shape.dialog
                color: Theme.color.surfaceContainerHigh
                border.width: 1
                border.color: Theme.color.outlineVariant
                clip: true

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.lg
                    spacing: Theme.space.md

                    // Заголовок поверхні з кнопкою закриття
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        Text {
                            text: {
                                if (win.activeSurface === "launcher") return "\ue5c3"
                                if (win.activeSurface === "wallpaper") return "\ue1bc"
                                if (win.activeSurface === "clipboard") return "\ue14f"
                                if (win.activeSurface === "mixer") return "\ue429"
                                if (win.activeSurface === "wifi") return "\ue63e"
                                if (win.activeSurface === "media") return "\ue405"
                                if (win.activeSurface === "power") return "\ue8ac"
                                return "\ue8b8"
                            }
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                            color: Theme.color.primary
                        }

                        ThemedText {
                            text: {
                                if (win.activeSurface === "launcher") return "Applications"
                                if (win.activeSurface === "wallpaper") return "Wallpapers"
                                if (win.activeSurface === "clipboard") return "Clipboard History"
                                if (win.activeSurface === "mixer") return "Volume Mixer"
                                if (win.activeSurface === "wifi") return "Wi-Fi Networks"
                                if (win.activeSurface === "media") return "Media Control"
                                if (win.activeSurface === "power") return "Power Options"
                                return "Controls"
                            }
                            style: Theme.type.titleMedium
                            emphasized: true
                            color: Theme.color.fgSurface
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: 32; height: 32
                            radius: 16
                            color: closeMa.containsMouse ? Theme.color.surfaceContainerHighest : "transparent"
                            Behavior on color { MotionColorAnimation { role: "hover" } }

                            Text {
                                anchors.centerIn: parent
                                text: "\ue5cd"
                                font { family: Theme.type.icons; pixelSize: 18 }
                                color: Theme.color.fgSurfaceVariant
                            }

                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ShellState.closeSurfaces()
                            }
                        }
                    }

                    // Контент поверхні
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "launcher"
                            visible: active
                            sourceComponent: LauncherSurface {}
                            onLoaded: {
                                if (item && item.appLaunched) {
                                    item.appLaunched.connect(function() { ShellState.closeSurfaces() })
                                }
                            }
                        }

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "wallpaper"
                            visible: active
                            sourceComponent: WallpaperSurface {}
                        }

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "clipboard"
                            visible: active
                            sourceComponent: ClipboardSurface {}
                        }

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "mixer"
                            visible: active
                            sourceComponent: MixerSurface {}
                        }

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "wifi"
                            visible: active
                            sourceComponent: WifiSurface {}
                        }

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "media"
                            visible: active
                            sourceComponent: MediaSurface {}
                        }

                        Loader {
                            anchors.fill: parent
                            active: win.activeSurface === "power"
                            visible: active
                            sourceComponent: PowerSurface {}
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: function(e) {
        if (win.activeSurface !== "idle") {
            ShellState.closeSurfaces()
            e.accepted = true
        }
    }
}
