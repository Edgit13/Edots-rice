import "root:/theme"
import QtQuick
import QtQuick.Layouts

// Велика плитка: значок, назва, велике значення, підпис, графік.
Rectangle {
    id: tile

    property string icon: ""
    property string title: ""
    property real percent: 0
    property string sub: ""
    property var hist: []
    property color base: Theme.color.primaryContainer
    property color fgBase: Theme.color.fgPrimaryContainer
    readonly property bool hot: percent > 85
    readonly property color fg: hot ? (Theme.settings.nothing ? Theme.color.fgError : Theme.color.fgErrorContainer) : fgBase

    implicitHeight: Theme.components.dp(150)
    radius: Theme.shape.cardLarge
    color: hot ? (Theme.settings.nothing ? Theme.color.error : Theme.color.errorContainer) : base
    Behavior on color { MotionColorAnimation { role: "stateChange" } }

    Connections {
        target: tile
        function onHistChanged() { Qt.callLater(function () { if (spark) spark.requestPaint() }) }
        function onFgChanged()   { Qt.callLater(function () { if (spark) spark.requestPaint() }) }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.md
        spacing: Theme.space.xs

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            Rectangle {
                implicitWidth: Theme.components.dp(34)
                implicitHeight: implicitWidth
                radius: tile.hot ? height / 2 : Theme.shape.radius("lg", height)
                color: Qt.rgba(tile.fg.r, tile.fg.g, tile.fg.b, 0.16)
                Behavior on radius { MotionAnimation { role: "morph" } }

                Text {
                    anchors.centerIn: parent
                    text: tile.icon
                    color: tile.fg
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                }
            }

            ThemedText {
                Layout.fillWidth: true
                text: tile.title
                style: Theme.type.titleSmall
                emphasized: true
                color: tile.fg
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true

            ThemedText {
                text: Math.round(tile.percent) + "%"
                style: Theme.type.displaySmall
                emphasized: true
                color: tile.fg
            }
            Item { Layout.fillWidth: true }
            ThemedText {
                visible: tile.sub.length > 0
                text: tile.sub
                style: Theme.type.labelMedium
                color: tile.fg
                opacity: 0.8
            }
        }

        UsageBar {
            Layout.fillWidth: true
            value: tile.percent / 100
            active: tile.fg
            track: Qt.rgba(tile.fg.r, tile.fg.g, tile.fg.b, 0.22)
        }

        Canvas {
            id: spark
            Layout.fillWidth: true
            Layout.fillHeight: true
            onWidthChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                const h = tile.hist
                if (!h || h.length < 2) return
                const step = width / 39
                const x0 = width - (h.length - 1) * step
                const col = tile.fg
                ctx.beginPath()
                ctx.moveTo(x0, height)
                for (let i = 0; i < h.length; i++)
                    ctx.lineTo(x0 + i * step, height - Math.max(0, Math.min(1, h[i] / 100)) * (height - 3))
                ctx.lineTo(width, height)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(col.r, col.g, col.b, 0.16)
                ctx.fill()
                ctx.beginPath()
                for (let j = 0; j < h.length; j++) {
                    const y = height - Math.max(0, Math.min(1, h[j] / 100)) * (height - 3)
                    if (j === 0) ctx.moveTo(x0, y); else ctx.lineTo(x0 + j * step, y)
                }
                ctx.lineWidth = 2
                ctx.lineJoin = "round"
                ctx.strokeStyle = Qt.rgba(col.r, col.g, col.b, 0.9)
                ctx.stroke()
            }
        }
    }
}
