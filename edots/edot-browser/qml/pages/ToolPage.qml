import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

// Універсальна сторінка зі списком: закладки / історія
Item {
    id: page
    readonly property var c: theme.c

    property string title: ""
    property string searchHint: "Пошук"
    property string emptyTitle: ""
    property string emptyHint: ""
    property string emptyIcon: "history"
    property string clearText: "Очистити все"
    property var items: []
    property string query: ""

    signal openRequested(string url)
    signal removeRequested(int id)
    signal clearRequested()

    readonly property var filtered: {
        var q = query.trim().toLowerCase()
        if (!q) return items
        return items.filter(function(i) { return (i.title + " " + i.subtitle).toLowerCase().indexOf(q) >= 0 })
    }

    Item {
        id: body
        width: Math.min(880, parent.width - 48)
        height: parent.height
        anchors.horizontalCenter: parent.horizontalCenter

        ColumnLayout {
            anchors { fill: parent; topMargin: 32; bottomMargin: 16 }
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 2
                    Text { text: page.title; color: c.on_surface; font.pixelSize: 28 }
                    Text {
                        color: c.on_surface_variant
                        font.pixelSize: 13
                        text: page.query.length > 0 ? "Знайдено " + page.filtered.length + " із " + page.items.length
                                                    : "Усього: " + page.items.length
                    }
                }
                Item { Layout.fillWidth: true }
                M3Button {
                    visible: page.items.length > 0
                    text: page.clearText
                    kind: "dangerText"
                    onClicked: page.clearRequested()
                }
            }

            // ---- пошук
            Rectangle {
                visible: page.items.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 24
                color: c.surface_container_high
                border.width: search.activeFocus ? 2 : 0
                border.color: c.primary

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 8 }
                    spacing: 12
                    Icon { name: "search"; size: 24; color: c.on_surface_variant }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        color: c.on_surface
                        font.pixelSize: 15
                        clip: true
                        selectByMouse: true
                        selectionColor: c.primary_container
                        selectedTextColor: c.on_primary_container
                        onTextChanged: page.query = text
                        Text {
                            visible: search.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: page.searchHint
                            color: c.on_surface_variant
                            font.pixelSize: 15
                        }
                    }
                    IconButton {
                        visible: search.text.length > 0
                        icon: "close"
                        size: 32
                        iconSize: 20
                        onClicked: search.text = ""
                    }
                }
            }

            // ---- список
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: page.filtered.length > 0
                clip: true
                spacing: 2
                model: page.filtered
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: list.width - 8
                    height: 64
                    radius: 16
                    color: "transparent"

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: c.on_surface
                        opacity: rowMa.pressed ? 0.12 : (rowMa.containsMouse ? 0.08 : 0)
                    }
                    MouseArea {
                        id: rowMa
                        anchors { fill: parent; rightMargin: 56 }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.openRequested(modelData.url)
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 8 }
                        spacing: 16

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: c.primary_container
                            Text {
                                anchors.centerIn: parent
                                text: modelData.letter
                                color: c.on_primary_container
                                font.pixelSize: 16
                                font.weight: Font.Medium
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: c.on_surface
                                font.pixelSize: 16
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.subtitle
                                color: c.on_surface_variant
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }
                        Text {
                            visible: modelData.time !== ""
                            text: modelData.time
                            color: c.on_surface_variant
                            font.pixelSize: 13
                        }
                        IconButton {
                            icon: "delete"
                            tip: "Видалити"
                            onClicked: page.removeRequested(modelData.id)
                        }
                    }
                }
            }

            // ---- порожній стан
            Item {
                visible: page.filtered.length === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: page.query.length > 0 ? "search" : page.emptyIcon
                        size: 64
                        color: c.outline
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: page.query.length > 0 ? "Нічого не знайдено" : page.emptyTitle
                        color: c.on_surface
                        font.pixelSize: 20
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: page.query.length === 0
                        width: Math.min(360, body.width)
                        horizontalAlignment: Text.AlignHCenter
                        text: page.emptyHint
                        color: c.on_surface_variant
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
