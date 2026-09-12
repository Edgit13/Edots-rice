pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import QtQuick
import QtQuick.Controls  // ScrollBar
import QtQuick.Layouts

// ==========================================================================
// SettingsApp.qml — каркас Settings UI: бічна панель + контент.
// Категорії data-driven; нові сторінки додаються в `categories` фазами 4+.
// ==========================================================================

Item {
    id: app

    readonly property var categories: [
        { name: "Pill",     page: SettingsPages.PagePill },
        { name: "Presets", page: SettingsPages.PagePresets },
        { name: "System",  page: SettingsPages.PageSystem },
        { name: "About",   page: SettingsPages.PageAbout }
    ]

    property int currentIndex: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------------------------------------------------- sidebar

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 180
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    text: "Settings"
                    color: Colors.fg
                    font { family: "SF Pro Display"; pixelSize: 16; weight: 700 }
                }

                Repeater {
                    model: app.categories
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 32
                        radius: 8
                        color: app.currentIndex === index
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                            : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: app.currentIndex === index ? Colors.accent : Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 12; weight: app.currentIndex === index ? 600 : 500 }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.currentIndex = index
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
        }

        // ---------------------------------------------------------- content

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: pageCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                width: 6
                contentItem: Rectangle {
                    radius: 3
                    color: Colors.bg4
                }
            }

            ColumnLayout {
                id: pageCol
                width: parent.width
                spacing: 12

                Loader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: item ? item.implicitHeight : 0
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    sourceComponent: app.categories[app.currentIndex].page
                }
            }
        }
    }
}
