import "root:/theme"
import "root:/services"
import QtQuick

// Один тег/workspace. Форма й колір — за станом (M3 Expressive):
//   порожній  → крапка;  зайнятий → коло з номером;  активний → широка «пігулка» (primary);  urgent → error
Item {
    id: root

    required property string monitor
    required property int tagIndex      // 1-based номер тега
    property bool vertical: false
    property real size: 24

    readonly property var t: MangoService.tag(monitor, tagIndex)
    readonly property bool active: t.active
    readonly property bool urgent: t.urgent
    readonly property bool occupied: t.occupied

    readonly property real longSide: active ? size * 2.2 : (occupied || urgent ? size : size * 0.55)
    readonly property real shortSide: size

    implicitWidth: vertical ? shortSide : longSide
    implicitHeight: vertical ? longSide : shortSide
    Behavior on implicitWidth  { MotionAnimation { role: "morph" } }
    Behavior on implicitHeight { MotionAnimation { role: "morph" } }

    readonly property bool filled: occupied || active || urgent
    property real fill: filled ? 1 : 0          // 0 = крапка, 1 = повна комірка (плавний перехід)
    Behavior on fill { MotionAnimation { role: "morph" } }
    readonly property real dot: size * 0.4

    Rectangle {
        id: shape
        anchors.centerIn: parent
        width: root.dot + (parent.width - root.dot) * root.fill
        height: root.dot + (parent.height - root.dot) * root.fill
        radius: root.active ? Theme.shape.radius("md", Math.min(width, height)) : Math.min(width, height) / 2
        scale: ma.pressed ? 0.9 : 1
        color: root.urgent ? Theme.color.errorContainer
             : root.active ? Theme.color.primary
             : root.occupied ? Theme.color.secondaryContainer
             : Theme.color.outline
        opacity: root.filled ? 1 : (ma.containsMouse ? 1 : 0.6)

        Behavior on radius  { MotionAnimation { role: "morph" } }
        Behavior on scale   { MotionAnimation { role: "press" } }
        Behavior on opacity { MotionAnimation { role: "hover" } }
        Behavior on color   { MotionColorAnimation { role: "stateChange" } }

        ThemedText {
            anchors.centerIn: parent
            visible: opacity > 0.01
            opacity: (root.occupied || root.active || root.urgent) ? 1 : 0
            text: root.tagIndex
            style: Theme.type.labelMedium
            emphasized: root.active
            color: root.urgent ? Theme.color.fgErrorContainer
                 : root.active ? Theme.color.fgPrimary
                 : Theme.color.fgSecondaryContainer
            Behavior on opacity { MotionAnimation { role: "stateChange" } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: MangoService.switchTag(root.monitor, root.tagIndex)
    }
}
