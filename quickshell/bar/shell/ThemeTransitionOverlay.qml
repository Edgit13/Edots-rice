import "root:/theme"
import Quickshell
import Quickshell.Wayland
import QtQuick

// ThemeTransitionOverlay — повноекранний click-through шар для переходу між темами.
// Раніше: Canvas малював ~4500 кіл на КОЖЕН кадр у JS (повільно, чорний екран на ~1с+ на кожному моніторі).
// Тепер: лише кілька Rectangle у scene graph (GPU) — без Canvas, і набагато коротше.
//   fade — старий колір плавно розчиняється;
//   dots — коло-хвиля від верху по центру розкриває нову тему (кільце з акцентною кромкою);
//   scan — лінія-сканер зверху вниз.
// Потік: begin (шар одразу покриває екран кольором старої теми) → applied (тема перемкнена під ним) → розкриття.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    property bool running: false
    property string style: "dots"
    property string cover: "#000000"
    property color edge: "#ffffff"
    property real p: 0                    // 0 = повністю закрито, 1 = відкрито

    visible: running
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "edots-theme-transition"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {}                       // порожня маска → кліки проходять крізь

    Connections {
        target: ThemeSwitch
        function onBegin(cover, style) {
            reveal.stop()
            hold.stop()
            win.cover = cover
            win.style = style
            win.p = 0
            win.running = true
        }
        function onApplied() {
            if (!win.running) return
            win.edge = ThemeSettings.nothing ? ThemeNothing.red : ThemeColors.primary
            hold.restart()                 // дати новій темі відрендеритись під покриттям
        }
    }

    Timer { id: hold; interval: 50; onTriggered: reveal.restart() }

    NumberAnimation {
        id: reveal
        target: win
        property: "p"
        from: 0
        to: 1
        duration: Math.max(1, ThemeMotion.scaled(win.style === "fade" ? 300 : 460, true))
        easing.type: Easing.InOutQuad
        onFinished: { win.running = false; ThemeSwitch.busy = false }
    }

    Item {
        id: stage
        anchors.fill: parent
        clip: true

        // ---- fade ----
        Rectangle {
            anchors.fill: parent
            visible: win.style === "fade"
            color: win.cover
            opacity: 1 - win.p
        }

        // ---- dots: розширюване коло від верху по центру (кільце-покриття навколо «дірки») ----
        Item {
            id: circle
            visible: win.style === "dots"
            readonly property real ox: stage.width / 2
            readonly property real maxD: Math.sqrt(ox * ox + stage.height * stage.height) + 12
            readonly property real r: win.p * maxD
            readonly property real bw: maxD                       // товщина покриття: перекриває кути при будь-якому r

            Rectangle {                                           // покриття старою темою
                width: 2 * (circle.r + circle.bw); height: width
                x: circle.ox - width / 2; y: -height / 2
                radius: width / 2
                color: "transparent"
                border.width: circle.bw
                border.color: win.cover
            }
            Rectangle {                                           // акцентна кромка на фронті
                readonly property real ew: 4
                width: 2 * (circle.r + ew); height: width
                x: circle.ox - width / 2; y: -height / 2
                radius: width / 2
                color: "transparent"
                border.width: ew
                border.color: win.edge
                opacity: 1 - win.p * win.p
            }
        }

        // ---- scan: лінія зверху вниз ----
        Item {
            anchors.fill: parent
            visible: win.style === "scan"
            readonly property real lineY: win.p * (stage.height + 4)

            Rectangle {
                x: 0; y: parent.lineY
                width: stage.width; height: Math.max(0, stage.height - parent.lineY)
                color: win.cover
            }
            Rectangle {
                x: 0; y: parent.lineY - 2
                width: stage.width; height: 3
                color: win.edge
                opacity: 1 - win.p * win.p
            }
        }
    }
}
