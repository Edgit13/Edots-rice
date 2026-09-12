pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Page extracted from the former SettingsPages.qml monolith (Phase 4 fix).

Item {
    id: presetsPage
    implicitWidth: 200
    implicitHeight: presetsCol.implicitHeight

    property string confirmDelete: ""
    property string renaming: ""

    Timer {
        id: confirmTimer
        interval: 3000
        onTriggered: presetsPage.confirmDelete = ""
    }

    ColumnLayout {
        id: presetsCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "Presets" }

        Card {
            title: "Default (factory Edots)"

            Text {
                Layout.fillWidth: true
                text: "Restore every setting to the original Edots design. This preset is built in and can never be modified or deleted."
                color: Colors.grey1
                wrapMode: Text.Wrap
                font { family: "SF Pro Display"; pixelSize: 10 }
            }

            ButtonRow {
                label: "Active preset: " + Presets.active
                description: "Applying Default resets all categories at once."
                buttonText: "Restore Default"
                onClicked: Presets.apply("Default")
            }
        }

        Card {
            title: "User presets"

            Text {
                Layout.fillWidth: true
                visible: Presets.names.length === 0
                text: "No user presets yet. Create one below to snapshot the current look."
                color: Colors.grey1
                font { family: "SF Pro Display"; pixelSize: 10 }
            }

            Repeater {
                model: Presets.names
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 8
                    color: Presets.active === modelData
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
                        : Qt.rgba(Colors.bg3.r, Colors.bg3.g, Colors.bg3.b, 0.45)
                    border.width: Presets.active === modelData ? 1 : 0
                    border.color: Colors.accent

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            visible: presetsPage.renaming !== modelData
                            text: modelData
                            color: Colors.fg
                            elide: Text.ElideRight
                            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
                        }

                        Rectangle {
                            visible: presetsPage.renaming === modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            radius: 6
                            color: Colors.bg2

                            TextInput {
                                id: renameInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                text: presetsPage.renaming === modelData ? modelData : ""
                                color: Colors.fg
                                font { family: "SF Pro Display"; pixelSize: 11 }

                                Keys.onReturnPressed: commitRename()
                                Keys.onEnterPressed: commitRename()
                                Keys.onEscapePressed: presetsPage.renaming = ""

                                function commitRename() {
                                    if (text.trim().length > 0 && text.trim() !== modelData)
                                        Presets.rename(modelData, text.trim())
                                    presetsPage.renaming = ""
                                }
                            }
                        }

                        Text {
                            text: "Apply"
                            color: applyHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 11 }

                            HoverHandler { id: applyHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Presets.apply(modelData)
                            }
                        }

                        Text {
                            text: presetsPage.renaming === modelData ? "Save" : "Rename"
                            color: renHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 11 }

                            HoverHandler { id: renHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (presetsPage.renaming === modelData) {
                                        renameInput.commitRename()
                                    } else {
                                        presetsPage.renaming = modelData
                                        presetsPage.confirmDelete = ""
                                    }
                                }
                            }
                        }

                        Text {
                            text: presetsPage.confirmDelete === modelData ? "Sure?" : "Delete"
                            color: presetsPage.confirmDelete === modelData
                                ? Colors.red
                                : (delHover.hovered ? Colors.accent : Colors.grey1)
                            font { family: "SF Pro Display"; pixelSize: 11 }

                            HoverHandler { id: delHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (presetsPage.confirmDelete === modelData) {
                                        Presets.remove(modelData)
                                        presetsPage.confirmDelete = ""
                                        presetsPage.renaming = ""
                                    } else {
                                        presetsPage.confirmDelete = modelData
                                        presetsPage.renaming = ""
                                        confirmTimer.restart()
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Export"
                            color: expHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 11 }

                            HoverHandler { id: expHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Presets.exportPreset(
                                    modelData,
                                    Quickshell.env("HOME") + "/" + modelData + ".edots-preset.json")
                            }
                        }
                    }
                }
            }
        }

        Card {
            title: "Create / import"

            EntryRow {
                label: "Create preset from current state"
                placeholder: "Preset name…"
                buttonText: "Create"
                onSubmitted: (text) => Presets.create(text)
            }

            EntryRow {
                label: "Import preset from file"
                placeholder: "/path/to/preset.json"
                buttonText: "Import"
                description: "The imported preset keeps its file name. Reserved names (Default, Custom) are rejected."
                onSubmitted: (text) => Presets.importPreset(text)
            }
        }
    }
}
