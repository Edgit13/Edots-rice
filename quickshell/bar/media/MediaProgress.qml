import "root:/theme"
import "root:/services"
import QtQuick

// MediaProgress — M3 Expressive «хвиляста» шкала прогресу (як у end-4):
// активна частина хвилиться, поки грає, і випрямляється на паузі; thumb — вертикальна «пігулка».
Item {
    id: root

    property real value: 0               // 0..1
    property bool playing: false
    property bool seekable: true
    property color activeColor: Theme.color.primary
    property color trackColor: Theme.color.secondaryContainer
    property real lineWidth: Theme.components.dp(4)
    property real waveLength: Theme.components.dp(26)
    property real phase: 0
    property real waveAmp: playing ? 2.4 * Theme.space.k : 0
    Behavior on waveAmp { MotionAnimation { role: "morph" } }

    readonly property real shown: ma.active ? ma.frac : value
    signal seeked(real fraction)

    implicitHeight: Theme.components.sliderS
    implicitWidth: 200

    onShownChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onWaveAmpChanged: canvas.requestPaint()
    onActiveColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    FrameAnimation {
        running: root.playing && root.visible
        onTriggered: {
            root.phase = (root.phase + frameTime * 3.2) % (Math.PI * 2)
            canvas.requestPaint()
        }
    }
    // позиція в MPRIS сама не оновлюється
    Timer {
        interval: 200
        repeat: true
        running: root.playing && root.visible
        onTriggered: MediaService.poll()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const lw = root.lineWidth
            const cy = height / 2
            const x = Math.max(0, Math.min(width, width * root.shown))
            const gap = Theme.components.dp(6)
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.lineWidth = lw

            // неактивна частина — пряма
            const tStart = x + gap
            if (tStart < width - lw) {
                ctx.beginPath()
                ctx.strokeStyle = root.trackColor
                ctx.moveTo(tStart, cy)
                ctx.lineTo(width - lw / 2, cy)
                ctx.stroke()
            }

            // активна частина — хвиля
            const end = x - gap
            if (end > lw) {
                ctx.beginPath()
                ctx.strokeStyle = root.activeColor
                const k = Math.PI * 2 / root.waveLength
                for (let px = lw / 2; px <= end; px += 1.5) {
                    const ramp = Math.min(1, (px - lw / 2) / Theme.components.dp(10))      // плавний старт хвилі
                    const y = cy + root.waveAmp * ramp * Math.sin(px * k - root.phase)
                    if (px === lw / 2) ctx.moveTo(px, y); else ctx.lineTo(px, y)
                }
                ctx.stroke()
            }
        }
    }

    // thumb
    Rectangle {
        id: thumb
        width: ma.pressed ? Theme.components.sliderHandleW - 1 : Theme.components.sliderHandleW
        height: Theme.components.dp(ma.pressed ? 28 : 22)
        radius: width / 2
        color: root.activeColor
        x: Math.max(0, Math.min(root.width - width, root.width * root.shown - width / 2))
        y: (root.height - height) / 2
        visible: root.seekable
        Behavior on width { MotionAnimation { role: "press" } }
        Behavior on height { MotionAnimation { role: "press" } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.seekable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        property bool active: false
        property real frac: 0
        function setFrac(mx) { frac = Math.max(0, Math.min(1, mx / width)) }
        onPressed: mouse => { active = true; setFrac(mouse.x) }
        onPositionChanged: mouse => { if (pressed) setFrac(mouse.x) }
        onReleased: { active = false; root.seeked(frac) }
        onCanceled: active = false
    }
}
