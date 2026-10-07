import QtQuick

// M3 switch 52x32. Стан задає батько (checked), зміну віддає через toggled()
Item {
    id: root
    readonly property var c: theme.c
    property bool checked: false
    signal toggled(bool value)

    width: 52
    height: 32
    Rectangle {
        anchors.fill: parent
        radius: 16
        color: root.checked ? c.primary : c.surface_container_highest
        border.width: root.checked ? 0 : 2
        border.color: c.outline
        Behavior on color { ColorAnimation { duration: theme.animations ? 200 : 0 } }
    }
    Rectangle {
        id: thumb
        property real d: ma.pressed ? 28 : (root.checked ? 24 : 16)
        width: d
        height: d
        radius: d / 2
        y: (parent.height - d) / 2
        x: root.checked ? parent.width - 16 - d / 2 : 16 - d / 2
        color: root.checked ? c.on_primary : c.outline
        Behavior on x { NumberAnimation { duration: theme.animations ? 200 : 0; easing.type: Easing.OutCubic } }
        Behavior on d { NumberAnimation { duration: theme.animations ? 120 : 0 } }
        Behavior on color { ColorAnimation { duration: theme.animations ? 200 : 0 } }
        Icon {
            anchors.centerIn: parent
            visible: root.checked
            name: "check"
            size: 16
            color: c.primary
        }
    }
    Rectangle {
        // state layer навколо thumb
        width: 40
        height: 40
        radius: 20
        x: thumb.x + thumb.width / 2 - 20
        y: 16 - 20
        color: root.checked ? c.primary : c.on_surface
        opacity: ma.pressed ? 0.12 : (ma.containsMouse ? 0.08 : 0)
        z: -1
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
