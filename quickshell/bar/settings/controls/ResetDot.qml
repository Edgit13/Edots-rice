pragma ComponentBehavior: Bound
import ".."
import "../material"
import Quickshell
import QtQuick

// ResetDot — маленька кнопка ↺ збоку опції. Видима лише коли значення != default.
Rectangle {
    id: rd
    required property string cat
    required property string key

    readonly property bool dirty: Settings.isDirty(rd.cat, rd.key)
    visible: rd.dirty
    implicitWidth: 24; implicitHeight: 24
    radius: M3.rFull
    color: ma.containsMouse ? M3.hoverOf(M3.primary) : "transparent"

    Text {
        anchors.centerIn: parent
        text: "restart_alt"
        color: M3.primary
        font { family: "Material Symbols Rounded"; pixelSize: 16 }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Settings.resetKey(rd.cat, rd.key)
    }
}
