import "root:/theme"
import QtQuick

Rectangle {
    id: c

    property string text: ""
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 34
    radius: height / 2
    color: primary ? ThemeColors.primary
         : Theme.alpha(ThemeColors.fgSurface, ma.containsMouse ? 0.16 : 0.08)
    scale: ma.pressed ? 0.95 : 1
    Behavior on scale { MotionAnimation { role: "press" } }
    Behavior on color { MotionColorAnimation { role: "hover" } }

    ThemedText {
        id: label
        anchors.centerIn: parent
        text: c.text
        style: Theme.type.labelLarge
        color: c.primary ? ThemeColors.fgPrimary : ThemeColors.fgSurface
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: c.clicked()
    }
}
