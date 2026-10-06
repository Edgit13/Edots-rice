import QtQuick

// Елемент Navigation Rail: індикатор-«пілюля» 32->56 + підпис
Item {
    id: root
    readonly property var c: theme.c
    property string icon: ""
    property string label: ""
    property bool selected: false
    signal clicked()

    width: 80
    height: 68

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4
        height: 32
        radius: 16
        width: root.selected ? 56 : (ma.containsMouse ? 56 : 32)
        color: root.selected ? c.secondary_container
             : theme.alpha(c.on_surface, ma.pressed ? 0.12 : (ma.containsMouse ? 0.08 : 0))
        Behavior on width { NumberAnimation { duration: theme.animations ? 200 : 0; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: theme.animations ? 150 : 0 } }
    }
    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        name: root.icon
        size: 24
        color: root.selected ? c.on_secondary_container : c.on_surface_variant
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 42 }
        text: root.label
        color: root.selected ? c.on_surface : c.on_surface_variant
        font.pixelSize: 12
        font.weight: root.selected ? Font.DemiBold : Font.Medium
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
