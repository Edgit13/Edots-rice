import QtQuick
import QtQuick.Shapes
import "root:/theme"

// ArcGauge — кільцевий індикатор 0..1, старт зверху, плавна анімація.
Item {
    id: g

    property real value: 0
    property real thickness: 8
    property color trackColor: "#33ffffff"
    property color valueColor: "white"

    property real shown: Math.max(0, Math.min(1, value))
    Behavior on shown { MotionAnimation { role: "morphIn" } }

    readonly property real _r: Math.max(1, (Math.min(width, height) - thickness) / 2)

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        ShapePath {
            fillColor: "transparent"
            strokeColor: g.trackColor
            strokeWidth: g.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: g.width / 2; centerY: g.height / 2; radiusX: g._r; radiusY: g._r; startAngle: -90; sweepAngle: 359.9 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: g.valueColor
            strokeWidth: g.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: g.width / 2; centerY: g.height / 2; radiusX: g._r; radiusY: g._r; startAngle: -90; sweepAngle: Math.max(0.1, 360 * g.shown) }
        }
    }
}
