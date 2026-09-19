pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick

// LoadingIndicator.qml — Material 3 Expressive (Android 16/17): морфінг M3-фігур.
// СПІЛЬНИЙ компонент: будь-яка surface використовує LoadingIndicator { anchors... }.
Item {
    id: li
    property real size: 40
    property color color: Md.primary
    property int steps: 4
    property int shapeA: 0
    property int shapeB: 1
    property real t: 0
    property real rotFrom: 0
    property real rotTo: 90

    width: size
    height: size

    readonly property int seg: 48

    function radiusFor(shape, theta) {
        if (shape >= li.steps - 1) return 1
        const n = shape + 3
        const s = (2 * Math.PI) / n
        const local = ((theta % s) + s) % s
        return Math.cos(Math.PI / n) / Math.cos(local - s / 2)
    }
    function easeInOutCubic(x) {
        return x < 0.5 ? 4 * x * x * x : 1 - Math.pow(-2 * x + 2, 3) / 2
    }

    Timer {
        interval: 16
        repeat: true
        running: true
        onTriggered: {
            li.t += 16 / 560
            if (li.t >= 1) {
                li.t = 0
                li.shapeA = li.shapeB
                li.shapeB = (li.shapeB + 1) % li.steps
                li.rotFrom = li.rotTo
                li.rotTo = li.rotTo + 90
            }
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = li.color
            const e = li.easeInOutCubic(li.t)
            const rot = (li.rotFrom + (li.rotTo - li.rotFrom) * e) * Math.PI / 180
            const cx = width / 2, cy = height / 2
            const R = width / 2 - 2
            ctx.beginPath()
            for (let i = 0; i <= li.seg; i++) {
                const th = (i / li.seg) * 2 * Math.PI + rot
                const rA = li.radiusFor(li.shapeA, th)
                const rB = li.radiusFor(li.shapeB, th)
                const r = (rA + (rB - rA) * e) * R
                const x = cx + Math.cos(th) * r
                const y = cy + Math.sin(th) * r
                if (i === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
            }
            ctx.closePath()
            ctx.fill()
        }
    }
}
