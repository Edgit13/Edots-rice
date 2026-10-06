import QtQuick

// kind: filled | tonal | outlined | text | danger | dangerText
Item {
    id: root
    readonly property var c: theme.c

    property string text: ""
    property string kind: "tonal"
    property string icon: ""
    signal clicked()

    implicitHeight: 40
    implicitWidth: content.implicitWidth + (icon !== "" ? 40 : 48)
    opacity: enabled ? 1 : 0.38

    readonly property color bg: kind === "filled" ? c.primary
                              : kind === "tonal" ? c.secondary_container : "transparent"
    readonly property color fg: kind === "filled" ? c.on_primary
                              : kind === "tonal" ? c.on_secondary_container
                              : (kind === "danger" || kind === "dangerText") ? c.error : c.primary
    readonly property bool bordered: kind === "outlined" || kind === "danger"

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.bg
        border.width: root.bordered ? 1 : 0
        border.color: c.outline
    }
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.fg
        opacity: ma.pressed ? 0.12 : (ma.containsMouse ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: theme.animations ? 100 : 0 } }
    }
    Row {
        id: content
        anchors.centerIn: parent
        spacing: 8
        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 18
            color: root.fg
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.text
            color: root.fg
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
