import QtQuick

// M3 segmented button. model: [{key, label}]
Item {
    id: root
    readonly property var c: theme.c
    property var model: []
    property string current: ""
    signal picked(string key)

    height: 40
    width: row.width

    Row {
        id: row
        Repeater {
            model: root.model
            delegate: Item {
                required property var modelData
                required property int index
                readonly property bool sel: modelData.key === root.current
                readonly property bool first: index === 0
                readonly property bool last: index === root.model.length - 1
                width: label.implicitWidth + (sel ? 52 : 36)
                height: 40
                clip: true
                Behavior on width { NumberAnimation { duration: theme.animations ? 150 : 0 } }

                Rectangle {
                    // зовнішні кути закруглені, внутрішні обрізані clip-ом сегмента
                    x: first ? 0 : -20
                    width: parent.width + (first || last ? 20 : 40)
                    height: parent.height
                    radius: first || last ? 20 : 0
                    color: sel ? c.secondary_container : "transparent"
                }
                Rectangle {
                    anchors.fill: parent
                    color: c.on_surface
                    opacity: segMa.containsMouse ? 0.08 : 0
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        visible: sel
                        name: "check"
                        size: 18
                        color: c.on_secondary_container
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: label
                        text: modelData.label
                        color: sel ? c.on_secondary_container : c.on_surface
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                Rectangle {
                    visible: !last
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: c.outline
                }
                MouseArea {
                    id: segMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(modelData.key)
                }
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "transparent"
        border.width: 1
        border.color: c.outline
    }
}
