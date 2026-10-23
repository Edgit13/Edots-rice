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

    // ---- Nothing: ряд точок, засвічена частка = value ----
    readonly property bool nothing: Theme.settings.nothing
    readonly property real seg: Math.max(3, thickness * 0.8)
    readonly property real pitch: seg + Math.max(2, seg * 0.7)
    readonly property int segCount: Math.max(1, Math.floor((width + (pitch - seg)) / pitch))
    Repeater {
        model: root.nothing ? root.segCount : 0
        Rectangle {
            required property int index
            x: index * root.pitch
            anchors.verticalCenter: parent.verticalCenter
            width: root.seg; height: root.seg; radius: width / 2
            color: root.active
            opacity: (index + 0.5) / root.segCount <= root.shown ? 1 : ThemeNothing.dotOpacityOff
            Behavior on opacity { MotionAnimation { role: "stateChange" } }
        }
    }

    Rectangle {
        visible: !root.nothing && width > 0.5
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
        visible: !root.nothing
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
