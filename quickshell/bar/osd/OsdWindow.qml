import "root:/theme"
import "root:/settings"
import "root:/services"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// OsdWindow — компактна M3 Expressive OSD-пігулка (гучність / яскравість).
// Позиція, відступ, розмір і тривалість — Settings → OSD. На лівому/правому краї пігулка стає вертикальною.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    // ---- позиція ----
    readonly property string pos: OsdService.position
    readonly property bool atTop: pos.indexOf("top") === 0
    readonly property bool atBottom: pos.indexOf("bottom") === 0
    readonly property bool atLeft: pos === "left" || pos.indexOf("-left") > 0
    readonly property bool atRight: pos === "right" || pos.indexOf("-right") > 0
    readonly property bool vertical: pos === "left" || pos === "right"

    // ---- розмір: одиниця u = uiScale × налаштування "Size" ----
    readonly property real u: Theme.space.k * OsdService.size
    function d(v) { return Math.round(v * u) }
    readonly property real pad: d(24)                       // запас під тінь і зсув
    readonly property real edge: Math.max(0, Math.round(OsdService.margin * Theme.space.k) - pad)

    readonly property bool target: OsdService.isTarget(win.screen)
    visible: target && OsdService.enabled && (OsdService.shown || card.opacity > 0.01)

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: win.atTop; bottom: win.atBottom; left: win.atLeft; right: win.atRight }
    margins { top: win.edge; bottom: win.edge; left: win.edge; right: win.edge }
    implicitWidth: card.width + pad * 2
    implicitHeight: card.height + pad * 2
    mask: Region {}                                         // клік проходить наскрізь

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "m3-osd"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Item {
        id: card
        width: win.vertical ? win.d(52) : win.d(264)
        height: win.vertical ? win.d(200) : win.d(52)

        // зсув при появі: від краю екрана
        readonly property real dirX: win.vertical ? (win.atLeft ? -1 : 1) : 0
        readonly property real dirY: win.vertical ? 0 : (win.atTop ? -1 : 1)
        property real slide: open ? 0 : win.d(16)
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: dirX * slide
        anchors.verticalCenterOffset: dirY * slide

        // ---- похідний стан ----
        readonly property bool open: OsdService.shown
        readonly property bool isVol: OsdService.kind === "volume"
        readonly property bool muted: isVol && OsdService.muted
        readonly property bool over: isVol && !muted && OsdService.value > 1.0005
        readonly property real pct: muted ? 0 : Math.round(OsdService.value * 100)
        property real dispPct: pct
        Behavior on dispPct { MotionAnimation { role: "stateChange" } }

        readonly property color accent: muted ? Theme.color.outline
                                      : over ? Theme.color.error
                                      : isVol ? Theme.color.primary : Theme.color.tertiary
        readonly property color badgeBg: muted ? Theme.color.errorContainer
                                       : isVol ? Theme.color.primaryContainer : Theme.color.tertiaryContainer
        readonly property color badgeFg: muted ? Theme.color.fgErrorContainer
                                       : isVol ? Theme.color.fgPrimaryContainer : Theme.color.fgTertiaryContainer
        readonly property string glyph: {
            if (isVol) {
                if (muted) return "\ue04f"                     // volume_off
                if (OsdService.value <= 0.001) return "\ue04e" // volume_mute
                return OsdService.value < 0.5 ? "\ue04d" : "\ue050"
            }
            return OsdService.value < 0.34 ? "\ue1ad" : (OsdService.value < 0.67 ? "\ue1ae" : "\ue1ac")
        }
        onGlyphChanged: iconBump.restart()

        // ---- поява / зникнення ----
        opacity: open ? 1 : 0
        scale: open ? 1 : 0.86
        Behavior on slide   { MotionAnimation { role: card.open ? "move" : "exit" } }
        Behavior on opacity { MotionAnimation { role: card.open ? "enter" : "exit" } }
        Behavior on scale   { MotionAnimation { role: card.open ? "expand" : "collapse" } }

        Connections {
            target: OsdService
            function onPulse() { ringAnim.restart(); badgePulse.restart() }
        }

        ElevationShadow {
            anchors.fill: parent
            level: 0.5
            radius: Math.min(width, height) / 2
            color: Theme.color.surfaceContainerHigh
        }

        GridLayout {
            anchors.fill: parent
            anchors.margins: win.d(6)
            rows: win.vertical ? 3 : 1
            columns: win.vertical ? 1 : 3
            rowSpacing: win.d(8)
            columnSpacing: win.d(10)

            // ---- бейдж ----
            Item {
                Layout.row: win.vertical ? 2 : 0
                Layout.column: 0
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: win.d(40)
                Layout.preferredHeight: win.d(40)

                Rectangle {                       // хвиля від бейджа
                    id: ring
                    anchors.fill: parent
                    radius: badge.radius
                    color: "transparent"
                    border.width: Math.max(1, win.d(2))
                    border.color: card.accent
                    opacity: 0
                }
                Rectangle {
                    id: badge
                    anchors.fill: parent
                    color: card.badgeBg
                    radius: card.muted ? Theme.shape.radius("lg", height) : height / 2
                    Behavior on color { MotionColorAnimation { role: "stateChange" } }
                    Behavior on radius { MotionAnimation { role: "morph" } }

                    Text {
                        id: iconText
                        anchors.centerIn: parent
                        text: card.glyph
                        color: card.badgeFg
                        font { family: Theme.type.icons; pixelSize: win.d(20) }
                        rotation: card.isVol ? 0 : OsdService.value * 120     // сонце крутиться
                        Behavior on rotation { MotionAnimation { role: "move" } }
                        Behavior on color { MotionColorAnimation { role: "stateChange" } }
                    }
                }
            }

            // ---- повзунок (у вертикальному режимі — повернутий на -90°) ----
            Item {
                id: barWrap
                Layout.row: win.vertical ? 1 : 0
                Layout.column: win.vertical ? 0 : 1
                Layout.fillWidth: !win.vertical
                Layout.fillHeight: win.vertical
                Layout.preferredWidth: win.vertical ? win.d(24) : -1
                Layout.preferredHeight: win.vertical ? -1 : win.d(24)
                Layout.alignment: Qt.AlignCenter

                Item {
                    id: bar
                    anchors.centerIn: parent
                    width: win.vertical ? barWrap.height : barWrap.width
                    height: win.vertical ? barWrap.width : barWrap.height
                    rotation: win.vertical ? -90 : 0

                    readonly property real trackH: win.d(12)
                    readonly property real handleW: Math.max(2, win.d(4))
                    readonly property real gap: win.d(5)
                    readonly property real frac: card.muted ? 0 : Math.max(0, Math.min(1, OsdService.value))
                    property real shown: frac
                    Behavior on shown { MotionAnimation { role: "move" } }
                    readonly property real hx: width * Math.max(0, Math.min(1, shown))

                    Rectangle {                   // активна частина
                        y: (bar.height - bar.trackH) / 2
                        width: Math.max(0, bar.hx - bar.handleW / 2 - bar.gap)
                        height: bar.trackH
                        color: card.accent
                        topLeftRadius: height / 2
                        bottomLeftRadius: height / 2
                        topRightRadius: Theme.shape.xs
                        bottomRightRadius: Theme.shape.xs
                        Behavior on color { MotionColorAnimation { role: "stateChange" } }
                    }
                    Rectangle {                   // неактивна частина
                        x: Math.min(bar.width, bar.hx + bar.handleW / 2 + bar.gap)
                        y: (bar.height - bar.trackH) / 2
                        width: Math.max(0, bar.width - x)
                        height: bar.trackH
                        color: Theme.color.secondaryContainer
                        topLeftRadius: Theme.shape.xs
                        bottomLeftRadius: Theme.shape.xs
                        topRightRadius: height / 2
                        bottomRightRadius: height / 2
                    }
                    Rectangle {                   // handle
                        width: bar.handleW
                        height: bar.trackH + win.d(10)
                        radius: width / 2
                        x: Math.max(0, Math.min(bar.width - width, bar.hx - width / 2))
                        y: (bar.height - height) / 2
                        color: card.accent
                        Behavior on color { MotionColorAnimation { role: "stateChange" } }
                    }
                }
            }

            // ---- число ----
            ThemedText {
                Layout.row: 0
                Layout.column: win.vertical ? 0 : 2
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: win.d(44)
                Layout.rightMargin: win.vertical ? 0 : win.d(6)
                horizontalAlignment: win.vertical ? Text.AlignHCenter : Text.AlignRight
                text: card.muted ? Lang.t("ui.osd.mute") : Math.round(card.dispPct) + "%"
                style: Theme.type.monoSmall
                font.pixelSize: win.d(12)
                emphasized: true
                color: card.muted ? Theme.color.outline : (card.over ? Theme.color.error : Theme.color.fgSurface)
                Behavior on color { MotionColorAnimation { role: "stateChange" } }
            }
        }
    }

    // ---- ефекти ----
    ParallelAnimation {
        id: ringAnim
        MotionAnimation { target: ring; property: "opacity"; from: 0.55; to: 0; role: "fade" }
        MotionAnimation { target: ring; property: "scale"; from: 1; to: 1.7; role: "fade" }
    }
    SequentialAnimation {
        id: badgePulse
        MotionAnimation { target: badge; property: "scale"; to: 1.12; role: "press" }
        MotionAnimation { target: badge; property: "scale"; to: 1; role: "morph" }
    }
    SequentialAnimation {
        id: iconBump
        MotionAnimation { target: iconText; property: "scale"; to: 0.65; role: "press" }
        MotionAnimation { target: iconText; property: "scale"; to: 1; role: "morph" }
    }
}
