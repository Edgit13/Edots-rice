pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import QtQuick
import QtQuick.Controls  // ScrollBar
import QtQuick.Layouts

// ==========================================================================
// SettingsApp.qml — каркас Settings UI (Phase 4 fix: plain-файли).
//
// Усунуто root cause невидимого контенту: inline-компоненти у JS-контексті
// (var-масив + Loader.sourceComponent) давали silent undefined у цьому білді
// (Loader.status=Ready, item=null). Тепер сторінки — звичайні компоненти
// однієї директорії, інстанційовані декларативно з visible-гейтом;
// стан сторінок зберігається між перемиканнями.
// ==========================================================================

Item {
    id: app

    readonly property var categories: [
        { name: "Pill" },
        { name: "Animations" },
        { name: "Bar" },
        { name: "Presets" },
        { name: "System" },
        { name: "About" }
    ]

    property int currentIndex: 0

    // М'який fade-in контенту при перемиканні вкладок
    SequentialAnimation {
        id: pageSwitchAnim
        PropertyAction { target: pageCol; property: "opacity"; value: 0 }
        NumberAnimation { target: pageCol; property: "opacity"; to: 1; duration: Anim.ms(140); easing.type: Easing.OutCubic }
    }

    onCurrentIndexChanged: pageSwitchAnim.restart()

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
                            : (sideHover.hovered
                                ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06)
                                : "transparent")

                        Behavior on color { ColorAnimation { duration: Anim.ms(120) } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: app.currentIndex === index ? Colors.accent
                                : (sideHover.hovered ? Colors.fg : Colors.grey1)
                            font { family: "SF Pro Display"; pixelSize: 12; weight: app.currentIndex === index ? 600 : 500 }

                            Behavior on color { ColorAnimation { duration: Anim.ms(120) } }
                        }

                        HoverHandler { id: sideHover }

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

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 12
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.bottomMargin: 8
            implicitHeight: 30
            radius: 9
            color: Colors.bg2
            border.width: 1
            border.color: searchInput.activeFocus
                ? Colors.accent
                : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.12)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "\uef7a"
                    color: Colors.grey1
                    font { family: "Material Symbols Rounded"; pixelSize: 14 }
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Colors.fg
                    font { family: "SF Pro Display"; pixelSize: 11 }
                    clip: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: searchInput.text.length === 0
                        text: "Search settings\u2026"
                        color: Colors.grey1
                        font: searchInput.font
                    }

                    onTextChanged: SettingsSearch.query = text
                    Keys.onEscapePressed: {
                        searchInput.text = ""
                        SettingsSearch.clear()
                    }
                }

                Text {
                    visible: SettingsSearch.active
                    text: "\u00d7"
                    color: clearHover.hovered ? Colors.red : Colors.grey1
                    font { family: "SF Pro Display"; pixelSize: 14 }

                    HoverHandler { id: clearHover }
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = ""
                            SettingsSearch.clear()
                        }
                    }
                }
            }
        }

        Flickable {
            id: flick
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

                PagePill {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    visible: app.currentIndex === 0 || SettingsSearch.active
                }
                PageAnimations {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    visible: app.currentIndex === 1 || SettingsSearch.active
                }
                PageBar {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    visible: app.currentIndex === 2 || SettingsSearch.active
                }
                PagePresets {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    visible: app.currentIndex === 3 || SettingsSearch.active
                }
                PageSystem {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    visible: app.currentIndex === 4 || SettingsSearch.active
                }
                PageAbout {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    Layout.bottomMargin: 14
                    Layout.leftMargin: 16
                    Layout.rightMargin: 16
                    visible: app.currentIndex === 5 || SettingsSearch.active
                }
            }
        }
        }   // content ColumnLayout
    }
}
