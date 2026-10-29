import "root:/theme"
import QtQuick
import QtQuick.Shapes

// ExpressiveShape — M3 Expressive форми: cookie | flower | sunny (полігон) та circle | squircle | pill | rounded.
Item {
    id: root

    property string shapeName: "cookie"
    property color fillColor: "transparent"
    property color strokeColor: "transparent"
    property real strokeWidth: 0

    readonly property bool poly: shapeName === "cookie" || shapeName === "flower" || shapeName === "sunny"
    readonly property real _minSide: Math.min(width, height)

    readonly property var points: {
        if (!poly || width <= 0 || height <= 0) return []
        const n = shapeName === "cookie" ? 9 : 8
        const cx = width / 2, cy = height / 2
        const rx = width / 2 - strokeWidth / 2, ry = height / 2 - strokeWidth / 2
        const steps = 240
        const out = []
        for (let i = 0; i <= steps; i++) {
            const t = (i % steps) / steps * Math.PI * 2
            let k
            if (shapeName === "cookie")      k = 0.955 + 0.045 * Math.cos(n * t)
            else if (shapeName === "flower") k = 0.89 + 0.11 * Math.cos(n * t)
            else { const s = (Math.cos(n * t) + 1) / 2; k = 0.86 + 0.14 * Math.pow(s, 2.2) }
            out.push(Qt.point(cx + rx * k * Math.sin(t), cy - ry * k * Math.cos(t)))
        }
        return out
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.poly
        color: root.fillColor
        border.width: root.strokeWidth
        border.color: root.strokeColor
        radius: root.shapeName === "circle" || root.shapeName === "pill" ? root._minSide / 2
              : root.shapeName === "squircle" ? root._minSide * 0.34
              : Math.min(Theme.shape.token("xxl"), root._minSide / 2)
    }

    Shape {
        anchors.fill: parent
        visible: root.poly
        layer.enabled: root.poly
        layer.samples: 4
        ShapePath {
            fillColor: root.fillColor
            strokeColor: root.strokeWidth > 0 ? root.strokeColor : "transparent"
            strokeWidth: root.strokeWidth
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: root.points }
        }
    }
}
