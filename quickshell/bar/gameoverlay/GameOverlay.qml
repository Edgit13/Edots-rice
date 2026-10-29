import "root:/theme"
import "root:/services"
import "root:/states"
import Quickshell
import Quickshell.Wayland
import QtQuick

// GameOverlay — компактний монітор продуктивності (FPS · CPU · GPU) на шарі Overlay:
// видно поверх усіх вікон, зокрема повноекранних ігор. Клік проходить наскрізь.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    readonly property string pos: GameModeState.optOverlayPos
    readonly property bool onThisScreen: Quickshell.screens.length === 1 || MangoService.focusedMonitor === modelData.name
    readonly property bool shouldShow: GameModeState.active && GameModeState.optOverlay && onThisScreen

    visible: shouldShow
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "edots-gameoverlay"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}                      // порожня область вводу → повністю наскрізний

    anchors {
        top: pos.startsWith("top")
        bottom: pos.startsWith("bottom")
        left: pos.endsWith("left")
        right: pos.endsWith("right")
    }
    margins { top: 14; bottom: 14; left: 14; right: 14 }
    implicitWidth: Math.ceil(card.width * GameModeState.optOverlayScale)
    implicitHeight: Math.ceil(card.height * GameModeState.optOverlayScale)

    onVisibleChanged: visible ? GameMonitorService.subscribe() : GameMonitorService.unsubscribe()
    Component.onCompleted: if (visible) GameMonitorService.subscribe()
    Component.onDestruction: if (visible) GameMonitorService.unsubscribe()

    // вимірювання частоти кадрів дисплея + «серцебиття», що тримає сцену динамічною (щоб кадри йшли на кожен vsync)
    FrameAnimation {
        id: frames
        running: win.visible
        property int count: 0
        property real t0: 0
        onTriggered: {
            count++
            const now = Date.now()
            if (t0 === 0) { t0 = now; return }
            if (now - t0 >= 1000) {
                GameMonitorService.displayFps = count * 1000 / (now - t0)
                count = 0; t0 = now
            }
        }
    }

    Rectangle {
        id: card
        scale: GameModeState.optOverlayScale
        transformOrigin: win.pos.startsWith("top") ? (win.pos.endsWith("left") ? Item.TopLeft : Item.TopRight)
                                                   : (win.pos.endsWith("left") ? Item.BottomLeft : Item.BottomRight)
        width: row.implicitWidth + 24
        height: row.implicitHeight + 16
        radius: 12
        color: Qt.rgba(0.05, 0.05, 0.06, GameModeState.optOverlayOpacity)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14

            // FPS
            Row {
                visible: GameModeState.optOverlayFps
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {   // індикатор «живий» (обертається щокадру)
                    width: 5; height: 5; radius: 2.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: GameMonitorService.useMangoHud ? "#4ade80" : "#94a3b8"
                    rotation: frames.elapsedTime * 90
                }
                Text {
                    text: Math.round(GameMonitorService.fps)
                    font { family: "monospace"; pixelSize: 20; bold: true }
                    color: "white"
                }
                Text {
                    text: GameMonitorService.fpsUnit
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 3
                    font { family: "monospace"; pixelSize: 10 }
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
            }
            // CPU
            Column {
                visible: GameModeState.optOverlayCpu
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: "CPU " + Math.round(GameMonitorService.cpuLoad) + "%"
                    font { family: "monospace"; pixelSize: 12; bold: true }
                    color: "white"
                }
                Text {
                    visible: GameModeState.optOverlayTemps && GameMonitorService.cpuTemp > 0
                    text: Math.round(GameMonitorService.cpuTemp) + "°C"
                    font { family: "monospace"; pixelSize: 10 }
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
            }
            // GPU
            Column {
                visible: GameModeState.optOverlayGpu && GameMonitorService.gpuLoad >= 0
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: "GPU " + Math.round(GameMonitorService.gpuLoad) + "%"
                    font { family: "monospace"; pixelSize: 12; bold: true }
                    color: "white"
                }
                Text {
                    visible: GameModeState.optOverlayTemps && GameMonitorService.gpuTemp > 0
                    text: Math.round(GameMonitorService.gpuTemp) + "°C"
                    font { family: "monospace"; pixelSize: 10 }
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
            }
        }
    }
}
