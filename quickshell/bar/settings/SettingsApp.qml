pragma ComponentBehavior: Bound
import "."
import "pages"
import "material"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: app

    readonly property var categories: [
        { name: "Appearance",  icon: "palette",         page: 0 },
        { name: "Colors",      icon: "format_paint",    page: 1 },
        { name: "Bar",         icon: "space_dashboard", page: 2 },
        { name: "Lock screen", icon: "lock",            page: 3 },
        { name: "Animations",  icon: "animation",       page: 4 },
        { name: "Presets",     icon: "bookmark",        page: 5 },
        { name: "System",      icon: "settings",        page: 6 },
        { name: "About",       icon: "info",            page: 7 }
    ]
    property int currentIndex: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---- sidebar ----
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: M3.s16
                spacing: M3.s4

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: M3.s12
                    text: "Settings"
                    color: M3.m3OnSurface
                    font: M3.titleLarge
                }

                Repeater {
                    model: app.categories
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: M3.rFull
                        color: app.currentIndex === index
                            ? M3.secondaryContainer
                            : (sideMa.containsMouse ? M3.hoverOf(M3.m3OnSurface) : "transparent")
                        Behavior on color { ColorAnimation { duration: M3.durFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: M3.s12
                            anchors.rightMargin: M3.s12
                            spacing: M3.s8
                            Text {
                                text: modelData.icon
                                color: app.currentIndex === index ? M3.m3OnSecondaryContainer : M3.m3OnSurfaceVariant
                                font { family: "Material Symbols Rounded"; pixelSize: 18 }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: app.currentIndex === index ? M3.m3OnSecondaryContainer : M3.m3OnSurface
                                font: app.currentIndex === index ? M3.labelLarge : M3.bodyMedium
                            }
                        }
                        MouseArea {
                            id: sideMa
                            anchors.fill: parent
                            hoverEnabled: true
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
            color: M3.outlineVariant
        }

        // ---- content ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: M3.s16
                Layout.leftMargin: M3.s16
                Layout.rightMargin: M3.s16
                Layout.bottomMargin: M3.s8
                implicitHeight: 40
                radius: M3.rFull
                color: M3.surfaceContainer
                border.width: search.activeFocus ? 2 : 1
                border.color: search.activeFocus ? M3.primary : M3.outline

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: M3.s16
                    anchors.rightMargin: M3.s16
                    spacing: M3.s8
                    Text {
                        text: "search"
                        color: M3.m3OnSurfaceVariant
                        font { family: "Material Symbols Rounded"; pixelSize: 18 }
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: M3.m3OnSurface
                        font: M3.bodyMedium
                        clip: true
                        onTextChanged: SettingsSearch.query = text
                        Keys.onEscapePressed: { text = ""; SettingsSearch.clear() }
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: search.text.length === 0
                            text: "Search settings…"
                            color: M3.m3OnSurfaceVariant
                            font: M3.bodyMedium
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
                contentHeight: pageCol.implicitHeight + M3.s24 * 2
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: pageCol
                    width: flick.width - M3.s32
                    x: M3.s16
                    y: M3.s8
                    spacing: M3.s12

                    PageAppearance   { Layout.fillWidth: true; visible: app.currentIndex === 0 || SettingsSearch.active }
                    PageColors       { Layout.fillWidth: true; visible: app.currentIndex === 1 || SettingsSearch.active }
                    PageBar          { Layout.fillWidth: true; visible: app.currentIndex === 2 || SettingsSearch.active }
                    PageLockscreen   { Layout.fillWidth: true; visible: app.currentIndex === 3 || SettingsSearch.active }
                    PageAnimations   { Layout.fillWidth: true; visible: app.currentIndex === 4 || SettingsSearch.active }
                    PagePresets      { Layout.fillWidth: true; visible: app.currentIndex === 5 || SettingsSearch.active }
                    PageSystem       { Layout.fillWidth: true; visible: app.currentIndex === 6 || SettingsSearch.active }
                    PageAbout        { Layout.fillWidth: true; visible: app.currentIndex === 7 || SettingsSearch.active }
                }
            }
        }
    }
}
