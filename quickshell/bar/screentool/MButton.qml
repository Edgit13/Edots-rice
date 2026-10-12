import QtQuick
import QtQuick.Layouts

// M3 Expressive-style button: shape morphs on toggle / hover / press
Rectangle {
    id: root

    property string label: ""
    property string icon: ""
    property string fallback: ""          // text shown for icon-only buttons when icon font is missing
    property bool toggled: false
    property string variant: "text"       // text | primary
    signal clicked()

    readonly property bool isPrimary: variant === "primary"
    readonly property color fg: isPrimary ? M3.fgPrimaryContainer : (toggled ? M3.fgSecondaryContainer : M3.fgSurfaceVariant)

    implicitHeight: 44
    implicitWidth: Math.max(44, content.implicitWidth + 32)

    color: isPrimary ? M3.primaryContainer : (toggled ? M3.secondaryContainer : "transparent")
    radius: mouse.pressed ? 10 : ((toggled || (isPrimary && mouse.containsMouse)) ? height / 2 : 16)

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
    opacity: enabled ? 1 : 0.38

    // state layer
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fg
        opacity: mouse.pressed ? 0.12 : (mouse.containsMouse ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: root.icon !== "" && M3.hasIcons
            text: root.icon
            color: root.fg
            font.family: M3.iconFont
            font.pixelSize: 22
        }
        Text {
            visible: text !== ""
            text: root.label !== "" ? root.label : (M3.hasIcons ? "" : root.fallback)
            color: root.fg
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
