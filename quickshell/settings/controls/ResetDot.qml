pragma ComponentBehavior: Bound
import ".."
import "../material"
import Quickshell
import QtQuick

Rectangle {
    id: rd
    required property string category
    required property string configKey

    visible: SettingsState.isDirty(category, configKey)
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
        onClicked: SettingsState.resetKey(rd.category, rd.configKey)
    }
}
