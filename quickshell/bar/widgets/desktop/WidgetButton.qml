import "root:/theme"
import QtQuick

Rectangle {
    id: b

    property string glyph: ""
    property bool primary: false
    property real size: 36
    property color onColor: "white"
    property color fillColor: "black"
    signal clicked()

    width: size; height: size; radius: size / 2
    color: primary ? onColor : Theme.alpha(onColor, ma.containsMouse ? 0.24 : 0.14)
    scale: ma.pressed ? 0.92 : 1
    Behavior on scale { MotionAnimation { role: "press" } }
    Behavior on color { MotionColorAnimation { role: "hover" } }

    Text {
        anchors.centerIn: parent
        text: b.glyph
        font { family: Theme.type.icons; pixelSize: b.size * 0.6 }
        color: b.primary ? b.fillColor : b.onColor
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
