import "root:/theme"
import QtQuick

// DotRing — Nothing-кільце з точок: value 0..1 засвічує відповідну частку точок (по колу, з 12 години).
// Вимкнені точки — тьмяні, увімкнені — ringColor. Використовується в MediaRing, коли theme.design = nothing.
Item {
    id: root

    property real value: 0
    property color color: Theme.color.primary
    property int count: 12
    property real dotSize: Math.max(2, Math.round(Math.min(width, height) * 0.12))

    implicitWidth: Theme.components.dp(26)
    implicitHeight: Theme.components.dp(26)

    readonly property real radiusPx: (Math.min(width, height) - dotSize) / 2
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * count)

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            readonly property real a: -Math.PI / 2 + index * 2 * Math.PI / root.count
            width: root.dotSize; height: width; radius: width / 2
            x: root.width / 2 + Math.cos(a) * root.radiusPx - width / 2
            y: root.height / 2 + Math.sin(a) * root.radiusPx - height / 2
            color: root.color
            opacity: index < root.lit ? ThemeNothing.dotOpacityOn : ThemeNothing.dotOpacityOff
            Behavior on opacity { MotionAnimation { role: "stateChange" } }
        }
    }
}
