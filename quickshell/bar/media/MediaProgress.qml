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

    // ---- Nothing: шкала з точок; пройдена частина світла, «голова» — червона й пульсує, поки грає ----
    readonly property bool nothing: Theme.settings.nothing
    readonly property real seg: Theme.components.dp(4)
    readonly property real pitch: seg * 2
    readonly property int segCount: Math.max(1, Math.floor((width + seg) / pitch))

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

    Repeater {
        model: root.nothing ? root.segCount : 0
        delegate: Rectangle {
            id: dotSeg
            required property int index
            readonly property bool lit: (index + 0.5) / root.segCount <= root.shown
            readonly property bool head: lit && (index + 1.5) / root.segCount > root.shown
            property real pulse: 1.0
            x: index * root.pitch + (root.width - (root.segCount * root.pitch - root.seg)) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: root.seg; height: root.seg; radius: width / 2
            color: head ? ThemeNothing.red : Theme.color.fgSurface
            opacity: lit ? 1.0 : ThemeNothing.dotOpacityOff
            scale: head ? pulse : (ma.pressed && lit ? 1.25 : 1.0)
            Behavior on opacity { NumberAnimation { duration: 120 } }
            Behavior on scale   { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            SequentialAnimation on pulse {
                running: dotSeg.head && root.playing && root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 1.7; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
            }
        }
    }

    Canvas {
        id: canvas
        visible: !root.nothing
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
        visible: root.seekable && !root.nothing
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
