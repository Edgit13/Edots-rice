import "root:/theme"
import "root:/widgets"
import QtQuick

// MediaRing — круговий прогрес із іконкою в центрі (для бару).
Item {
    id: root

    property real value: 0
    property string icon: ""
    property color ringColor: Theme.color.fgTertiaryContainer
    property color trackColor: Qt.rgba(ringColor.r, ringColor.g, ringColor.b, 0.25)
    property color iconColor: ringColor
    property real lineWidth: 2.5 * Theme.space.k

    implicitWidth: Theme.components.dp(26)
    implicitHeight: Theme.components.dp(26)

    onValueChanged: canvas.requestPaint()
    onRingColorChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()

    readonly property bool nothing: Theme.settings.nothing

    DotRing {
        anchors.fill: parent
        visible: root.nothing
        value: root.value
        color: root.ringColor
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        visible: !root.nothing
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const r = (Math.min(width, height) - root.lineWidth) / 2
            const cx = width / 2, cy = height / 2
            ctx.lineWidth = root.lineWidth
            ctx.lineCap = "round"

            ctx.beginPath()
            ctx.strokeStyle = root.trackColor
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            if (root.value > 0.005) {
                ctx.beginPath()
                ctx.strokeStyle = root.ringColor
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, root.value))
                ctx.stroke()
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.icon
        font { family: Theme.type.icons; pixelSize: Math.round(root.width * (root.nothing ? 0.4 : 0.62)) }
        color: root.iconColor
    }
}
