pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick

// MorphShape.qml — Canvas, що малює БУДЬ-ЯКУ з 7 M3E-форм (або морф між двома).
// Використання: MorphShape { shape: 3; size: 40; color: Md.primary }
Item {
    id: ms
    property int shape: 0            // 0..6
    property int shapeTo: -1         // якщо >=0 — морф shape->shapeTo за progress
    property real progress: 0
    property real size: 40
    property color color: Md.primary
    property int samples: 96
    property real rotationDeg: 0

    width: size
    height: size

    onShapeChanged: canvas.requestPaint()
    onShapeToChanged: canvas.requestPaint()
    onProgressChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()
    onRotationDegChanged: canvas.requestPaint()

    readonly property var shapeArrays: {
        const fns = M3X.shapeFns()
        const out = []
        for (let f = 0; f < fns.length; f++) {
            const arr = new Array(ms.samples)
            let mx = 0
            for (let i = 0; i < ms.samples; i++) {
                const r = fns[f]((i / ms.samples) * 2 * Math.PI)
                arr[i] = r
                if (r > mx) mx = r
            }
            for (let i = 0; i < ms.samples; i++) arr[i] /= mx
            out.push(arr)
        }
        return out
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const cx = width / 2, cy = height / 2
            const A = ms.shapeArrays[ms.shape % 7]
            const B = ms.shapeTo >= 0 ? ms.shapeArrays[ms.shapeTo % 7] : A
            const p = ms.shapeTo >= 0 ? ms.progress : 0
            const R = width / 2 - 1
            const rot = ms.rotationDeg * Math.PI / 180
            ctx.save()
            ctx.translate(cx, cy)
            ctx.rotate(rot)
            ctx.fillStyle = ms.color
            ctx.beginPath()
            const N = ms.samples
            for (let i = 0; i <= N; i++) {
                const k = i % N
                const r = (A[k] + (B[k] - A[k]) * p) * R
                const th = (k / N) * 2 * Math.PI
                const px = Math.cos(th) * r
                const py = Math.sin(th) * r
                if (i === 0) ctx.moveTo(px, py)
                else ctx.lineTo(px, py)
            }
            ctx.closePath()
            ctx.fill()
            ctx.restore()
        }
    }
}
