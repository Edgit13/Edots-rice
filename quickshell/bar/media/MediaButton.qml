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
    readonly property bool nothing: Theme.settings.nothing
    readonly property bool outlined: nothing && (variant === "tonal" || variant === "toggle")

    readonly property color bg: {
        switch (variant) {
        case "filled": return Theme.color.primary
        case "tonal":  return nothing ? "transparent" : Theme.color.secondaryContainer
        case "toggle": return nothing ? (toggled ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.10) : "transparent")
                                      : (toggled ? Theme.color.secondaryContainer : Theme.color.surfaceContainerHighest)
        default:       return "transparent"
        }
    }
    readonly property color fg: {
        switch (variant) {
        case "filled": return Theme.color.fgPrimary
        case "tonal":  return nothing ? Theme.color.fgSurface : Theme.color.fgSecondaryContainer
        case "toggle": return nothing ? (toggled ? Theme.color.fgSurface : Theme.color.fgSurfaceVariant)
                                      : (toggled ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant)
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
        // Nothing: tonal/toggle — контурні (hairline), toggled — яскравіший контур
        border.width: root.outlined ? 1 : 0
        border.color: Qt.rgba(root.fg.r, root.fg.g, root.fg.b, root.toggled ? 0.75 : 0.28)
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
