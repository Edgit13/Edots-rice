import QtQuick
import QtQuick.Layouts
import "../components"

// Дозволи поточного сайту: Типово / Довірений / Заблокований
Item {
    id: root
    readonly property var c: theme.c
    width: 336
    height: card.height + 2
    focus: true
    Keys.onEscapePressed: browser.closePopup()

    readonly property var options: [
        { mode: "default", icon: "shield",        title: "Типово",       desc: "Застосовувати фільтри" },
        { mode: "trusted", icon: "verified_user", title: "Довірений",    desc: "Не фільтрувати запити цього сайту" },
        { mode: "blocked", icon: "block",         title: "Заблокований", desc: "Блокувати всі запити цього сайту" }
    ]

    Rectangle {
        id: card
        x: 1; y: 1
        width: parent.width - 2
        height: col.implicitHeight + 40
        radius: 28
        color: c.surface_container
        border.width: 1
        border.color: c.outline_variant

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 20 }
            spacing: 6

            Text { text: "Дозволи сайту"; color: c.on_surface; font.pixelSize: 18; font.weight: Font.Medium }
            Text {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                text: browser.currentHost
                color: c.on_surface_variant
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Repeater {
                model: root.options
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: browser.permission === modelData.mode
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 16
                    color: selected ? c.primary_container : c.surface_container_high

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: selected ? c.on_primary_container : c.on_surface
                        opacity: ma.pressed ? 0.12 : (ma.containsMouse ? 0.08 : 0)
                    }
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        spacing: 14
                        Icon {
                            name: modelData.icon
                            size: 24
                            color: selected ? c.on_primary_container : c.on_surface_variant
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData.title
                                color: selected ? c.on_primary_container : c.on_surface
                                font.pixelSize: 15
                                font.weight: Font.Medium
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.desc
                                color: selected ? c.on_primary_container : c.on_surface_variant
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                        Icon { visible: selected; name: "check"; size: 22; color: c.on_primary_container }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            browser.closePopup()
                            browser.setPermission(modelData.mode)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 6
                text: "Правило застосовується до домену та його піддоменів. Сторінка перезавантажиться."
                color: c.on_surface_variant
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
