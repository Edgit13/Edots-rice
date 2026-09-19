pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick

// Ripple.qml — M3 ripple від точки натискання. Поклади всередину кнопки:
// Ripple { id: rip; anchors.fill: parent; color: Md.onSurface }
// у MouseArea: onPressed: (m) => rip.burst(m.x, m.y)
Item {
    id: rip
    property color color: Md.onSurface
    property real maxScale: 3.0

    function burst(x, y) {
        const d = Qt.createQmlObject(
            "import QtQuick 2.15; Rectangle {\n" +
            "  property real px: 0; property real py: 0\n" +
            "  x: px - width / 2; y: py - height / 2\n" +
            "  width: 20; height: 20; radius: 10\n" +
            "  color: \"" + rip.color + "\"\n" +
            "  opacity: 0.35\n" +
            "  scale: 0.2\n" +
            "  NumberAnimation on scale { to: " + rip.maxScale + "; duration: 550; easing.type: Easing.OutCubic }\n" +
            "  NumberAnimation on opacity { to: 0; duration: 550; easing.type: Easing.OutCubic }\n" +
            "  Timer { interval: 600; onTriggered: parent.destroy() }\n" +
            "}",
            rip, "rippleWave")
        d.px = x
        d.py = y
        d.x = Qt.binding(function() { return d.px - d.width / 2 })
        d.y = Qt.binding(function() { return d.py - d.height / 2 })
    }
}
