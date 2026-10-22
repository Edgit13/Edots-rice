import "root:/theme"
import QtQuick

// Смуга використання: активна частина + прогалина + неактивна (як слайдер M3E).
Item {
    id: root

    property real value: 0
    property color active: Theme.color.primary
    property color track: Theme.color.secondaryContainer
    property real thickness: Theme.components.dp(10)
    implicitHeight: thickness

    property real shown: value
    Behavior on shown { MotionAnimation { role: "move" } }
    readonly property real gap: Theme.components.dp(4)
    readonly property real cut: width * Math.max(0, Math.min(1, shown))

    Rectangle {
        visible: width > 0.5
        width: Math.max(0, root.cut - root.gap / 2)
        height: root.height
        color: root.active
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: Theme.shape.xs
        bottomRightRadius: Theme.shape.xs
        Behavior on color { MotionColorAnimation { role: "stateChange" } }
    }
    Rectangle {
        x: Math.min(root.width, root.cut + root.gap / 2)
        width: Math.max(0, root.width - x)
        height: root.height
        color: root.track
        topLeftRadius: Theme.shape.xs
        bottomLeftRadius: Theme.shape.xs
        topRightRadius: height / 2
        bottomRightRadius: height / 2
        Behavior on color { MotionColorAnimation { role: "stateChange" } }
    }
}
