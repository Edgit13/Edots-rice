pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick

// LoadingIndicator.qml — Material 3 Expressive: справжній морфінг фігур.
//
// Кожна фігура — радіальна функція r(θ), семпльована в N точок. Морф = покрокова
// інтерполяція радіусів між сусідніми фігурами послідовності (як Morph у
// androidx.graphics.shapes), з пружинним (spring) прогресом і безперервним обертанням.
// Послідовність M3: SoftBurst → Cookie9 → Pentagon → Pill → Sunny → Cookie4 → Oval.
//
// API: size, color, contained (кружок-контейнер), running, stepMs, spinMs.
Item {
    id: li

    property real size: 40
    property color color: Md.primary
    property bool contained: false
    property color containerColor: Md.primaryContainer
    property color containedColor: Md.onPrimaryContainer
    property bool running: true
    property real stepMs: 650      // тривалість одного морфу
    property real spinMs: 4666     // повний оберт
    property real elapsed: 0       // мс; можна задавати вручну, коли running: false

    width: size
    height: size

    readonly property int samples: 144
    // фігура займає ~66% контейнера, як у M3 (contained) — інакше майже весь розмір
    readonly property real fill: contained ? 0.66 : 0.92

    // ---------- геометрія фігур ----------
    function lobed(n, amp, kPeak, kValley) {
        return function(th) {
            const c = Math.cos(n * th)
            const v = c >= 0 ? Math.pow(c, kPeak) : -Math.pow(-c, kValley)
            return 1 + amp * v
        }
    }
    function roundedPolygon(n, roundness) {
        const s = (2 * Math.PI) / n
        return function(th) {
            const local = (((th % s) + s) % s) - s / 2
            const poly = Math.cos(Math.PI / n) / Math.cos(local)
            return poly * (1 - roundness) + roundness
        }
    }
    function stadium(a, b) {
        const h = a - b // півдовжина відрізка
        return function(th) {
            const dx = Math.cos(th), dy = Math.sin(th)
            const ay = Math.abs(dy)
            if (ay > 1e-6) {
                const r = b / ay
                if (Math.abs(r * dx) <= h) return r
            }
            const cx = h * (dx >= 0 ? 1 : -1)
            const cd = cx * dx
            return cd + Math.sqrt(Math.max(0, cd * cd - (h * h - b * b)))
        }
    }
    function ellipse(a, b) {
        return function(th) {
            const c = Math.cos(th), s = Math.sin(th)
            return (a * b) / Math.sqrt(b * b * c * c + a * a * s * s)
        }
    }

    // нормалізовані масиви радіусів (макс = 1)
    readonly property var shapes: {
        const fns = [
            lobed(10, 0.11, 1.0, 1.0),   // SoftBurst
            lobed(9, 0.075, 0.8, 1.5),   // Cookie 9-sided
            roundedPolygon(5, 0.45),     // Pentagon (закруглений)
            stadium(1.0, 0.56),          // Pill
            lobed(8, 0.16, 1.7, 0.8),    // Sunny
            lobed(4, 0.17, 0.7, 1.4),    // Cookie 4-sided
            ellipse(1.0, 0.74)           // Oval
        ]
        const out = []
        for (let f = 0; f < fns.length; f++) {
            const arr = new Array(li.samples)
            let mx = 0
            for (let i = 0; i < li.samples; i++) {
                const r = fns[f]((i / li.samples) * 2 * Math.PI)
                arr[i] = r
                if (r > mx) mx = r
            }
            for (let i = 0; i < li.samples; i++) arr[i] /= mx
            out.push(arr)
        }
        return out
    }

    // ---------- час ----------
    // пружинний прогрес: легкий overshoot (expressive spatial spring)
    function spring(t) {
        if (t >= 1) return 1
        return 1 - Math.exp(-6.5 * t) * Math.cos(8.5 * t)
    }

    FrameAnimation {
        running: li.running && li.visible
        onTriggered: li.elapsed += frameTime * 1000
    }
    onElapsedChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onContainedChanged: canvas.requestPaint()
    onContainerColorChanged: canvas.requestPaint()
    onContainedColorChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width, h = height
            if (w <= 0 || h <= 0) return
            const cx = w / 2, cy = h / 2

            if (li.contained) {
                ctx.fillStyle = li.containerColor
                ctx.beginPath()
                ctx.arc(cx, cy, w / 2, 0, 2 * Math.PI)
                ctx.fill()
            }

            const n = li.shapes.length
            const stepF = li.elapsed / li.stepMs
            const idx = Math.floor(stepF)
            const p = li.spring(stepF - idx)
            const A = li.shapes[idx % n]
            const B = li.shapes[(idx + 1) % n]

            // безперервне обертання + додатковий "докрут" на кожному морфі
            const rot = (li.elapsed / li.spinMs) * 2 * Math.PI + (idx + p) * (Math.PI / 6)
            const R = (w / 2) * li.fill

            ctx.save()
            ctx.translate(cx, cy)
            ctx.rotate(rot)
            ctx.fillStyle = li.contained ? li.containedColor : li.color
            ctx.beginPath()
            const N = li.samples
            for (let i = 0; i <= N; i++) {
                const k = i % N
                const r = (A[k] + (B[k] - A[k]) * p) * R
                const th = (k / N) * 2 * Math.PI
                const x = Math.cos(th) * r
                const y = Math.sin(th) * r
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.closePath()
            ctx.fill()
            ctx.restore()
        }
    }
}
