import QtQuick
import QtQuick.Layouts

// Рядок меню з іконкою та підказкою про гарячу клавішу
Item {
    id: root
    readonly property var c: theme.c
    property string icon: ""
    property string text: ""
    property string hint: ""
    signal clicked()

    implicitHeight: 48
    Layout.fillWidth: true

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: c.on_surface
        opacity: ma.pressed ? 0.12 : (ma.containsMouse ? 0.08 : 0)
    }
    RowLayout {
        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
        spacing: 14
        Icon { name: root.icon; size: 22; color: c.on_surface_variant }
        Text { Layout.fillWidth: true; text: root.text; color: c.on_surface; font.pixelSize: 14 }
        Text { visible: root.hint !== ""; text: root.hint; color: c.on_surface_variant; font.pixelSize: 12 }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
