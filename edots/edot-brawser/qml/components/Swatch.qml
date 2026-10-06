import QtQuick

// Круглий вибір акцентного кольору
Item {
    id: root
    readonly property var c: theme.c
    property string seed: "#9ccbfb"
    property bool selected: false
    property bool custom: false
    signal clicked()

    width: 40
    height: 40

    Rectangle {
        anchors.centerIn: parent
        width: 36
        height: 36
        radius: 18
        color: "transparent"
        border.width: root.selected ? 2 : 0
        border.color: c.on_surface
    }
    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: theme.accentPreview(root.seed)
    }
    Icon {
        anchors.centerIn: parent
        visible: root.custom || root.selected
        name: root.custom ? "palette" : "check"
        size: 18
        color: c.surface
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
