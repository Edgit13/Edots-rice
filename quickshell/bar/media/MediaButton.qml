import "root:/theme"
import QtQuick

// MediaButton — M3 Expressive icon button.
//  • форма морфиться: коло ↔ squircle (morphed), при натисканні радіус стискається, кнопка трохи розширюється
//  • variant: filled | tonal | toggle | standard
Item {
    id: root

    property string icon: ""
    property string variant: "standard"
    property real size: Theme.components.buttonS
    property bool morphed: false       // true → squircle (напр. «грає»)
    property bool toggled: false       // для variant: toggle
    signal clicked()

    readonly property bool pressed: ma.pressed

    readonly property color bg: {
        switch (variant) {
        case "filled": return Theme.color.primary
        case "tonal":  return Theme.color.secondaryContainer
        case "toggle": return toggled ? Theme.color.secondaryContainer : Theme.color.surfaceContainerHighest
        default:       return "transparent"
        }
    }
    readonly property color fg: {
        switch (variant) {
        case "filled": return Theme.color.fgPrimary
        case "tonal":  return Theme.color.fgSecondaryContainer
        case "toggle": return toggled ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
        default:       return Theme.color.fgSurface
        }
    }

    implicitHeight: size
    implicitWidth: size + (pressed ? Math.round(size * 0.2) : 0)
    opacity: enabled ? 1 : 0.38
    Behavior on implicitWidth { MotionAnimation { role: "press" } }

    Rectangle {
        id: shape
        anchors.fill: parent
        color: root.bg
        radius: root.pressed ? Theme.shape.radius("md", height)
              : root.morphed ? Theme.shape.radius("lg", height)
              : height / 2
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on radius { MotionAnimation { role: "morph" } }

        // state layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.fg
            opacity: ma.pressed ? Theme.components.statePressed
                   : ma.containsMouse ? Theme.components.stateHover : 0
            Behavior on opacity { MotionAnimation { role: "hover" } }
        }

        Text {
            anchors.centerIn: parent
            text: root.icon
            font { family: Theme.type.icons; pixelSize: Math.round(root.size * 0.5) }
            color: root.fg
            Behavior on color { MotionColorAnimation { role: "hover" } }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
