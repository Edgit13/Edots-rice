import QtQuick
import QtQuick.Layouts

// Картка налаштувань (surface-container, радіус 20)
Rectangle {
    id: root
    readonly property var c: theme.c
    default property alias content: col.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + 8
    radius: 20
    color: c.surface_container

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 4 }
        spacing: 0
    }
}
