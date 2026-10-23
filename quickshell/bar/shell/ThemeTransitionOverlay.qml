import "root:/theme"
import Quickshell
import Quickshell.Wayland
import QtQuick

// ThemeTransitionOverlay — повноекранний click-through шар для переходу між темами.
// Екран покритий точками кольору СТАРОЇ теми; під ними тема перемикається; потім точки зменшуються
// хвилею (від верху по центру або лінією-сканером), а на фронті хвилі світяться точки нового акценту.
PanelWindow {
    id: win

    required property var modelData
    screen: modelData

    property bool running: false
    property string style: "dots"
    property string cover: "#000000"
    property color edge: "#ffffff"
    property real p: 0                    // 0 = повністю закрито, 1 = відкрито

    readonly property int pitch: Math.max(16, Math.round(width / 90))   // крок сітки точок (більше = швидше)

    visible: running
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "edots-theme-transition"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    mask: Region {}                       // порожня маска → кліки проходять крізь

    onPChanged: canvas.requestPaint()

    Connections {
        target: ThemeSwitch
        function onBegin(cover, style) {
            reveal.stop()
            hold.stop()
            win.cover = cover
            win.style = style
            win.p = 0
            win.running = true
            canvas.requestPaint()
        }
        function onApplied() {
            if (!win.running) return
            win.edge = ThemeSettings.nothing ? ThemeNothing.red : ThemeColors.primary
            hold.restart()                 // дати новій темі відрендеритись під покриттям
        }
    }

    Timer { id: hold; interval: 140; onTriggered: reveal.restart() }

    NumberAnimation {
        id: reveal
        target: win
        property: "p"
        from: 0
        to: 1
        duration: Math.max(1, ThemeMotion.scaled(950, true))
        easing.type: Easing.InOutSine
        onFinished: { win.running = false; ThemeSwitch.busy = false }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (!win.running) return

            const W = width, H = height, P = win.pitch
            const maxR = P * 0.76                       // > P/√2 → кола при p=0 повністю перекривають екран
            const scan = win.style === "scan"
            const ox = W / 2, oy = 0
            const maxD = scan ? H : Math.sqrt(Math.max(ox, W - ox) * Math.max(ox, W - ox) + H * H)
            const spread = scan ? 0.30 : 0.55
            const p = win.p
            const TAU = Math.PI * 2

            const edgeDots = []
            ctx.fillStyle = win.cover
            ctx.beginPath()
            for (let y = 0; y <= H + P; y += P) {
                for (let x = 0; x <= W + P; x += P) {
                    const d = scan ? y / maxD
                                   : Math.sqrt((x - ox) * (x - ox) + (y - oy) * (y - oy)) / maxD
                    let q = (p - Math.min(1, d) * spread) / (1 - spread)
                    if (q >= 1) continue
                    q = Math.max(0, q)
                    const e = q * q * (3 - 2 * q)         // smoothstep
                    const r = maxR * (1 - e)
                    if (r < 0.4) continue
                    if (q > 0 && q < 0.22) { edgeDots.push(x, y, r); continue }   // фронт хвилі
                    ctx.moveTo(x + r, y)
                    ctx.arc(x, y, r, 0, TAU)
                }
            }
            ctx.fill()

            if (edgeDots.length > 0) {
                ctx.fillStyle = String(win.edge)
                ctx.beginPath()
                for (let i = 0; i < edgeDots.length; i += 3) {
                    ctx.moveTo(edgeDots[i] + edgeDots[i + 2], edgeDots[i + 1])
                    ctx.arc(edgeDots[i], edgeDots[i + 1], edgeDots[i + 2], 0, TAU)
                }
                ctx.fill()
            }
        }
    }
}
