pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// SettingsPages.qml — сторінки Settings UI (Phase 3).
//
// Лише РЕАЛЬНІ сторінки: Presets (Працює через Presets singleton),
// System (reload xdg-open тощо), About. Порожніх/фейкових категорій немає —
// нові сторінки додаватимуться фазами 4+.
// ==========================================================================

Item {
    id: pages
    visible: false

    // -------------------------------------------------------------- Presets

    component PagePresets: Item {
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

            SettingsControls.SectionLabel { label: "Presets" }

            SettingsControls.Card {
                title: "Default (factory Edots)"

                Text {
                    Layout.fillWidth: true
                    text: "Restore every setting to the original Edots design. This preset is built in and can never be modified or deleted."
                    color: Colors.grey1
                    wrapMode: Text.Wrap
                    font { family: "SF Pro Display"; pixelSize: 10 }
                }

                SettingsControls.ButtonRow {
                    label: "Active preset: " + Presets.active
                    description: "Applying Default resets all categories at once."
                    buttonText: "Restore Default"
                    onClicked: Presets.apply("Default")
                }
            }

            SettingsControls.Card {
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

            SettingsControls.Card {
                title: "Create / import"

                SettingsControls.EntryRow {
                    label: "Create preset from current state"
                    placeholder: "Preset name…"
                    buttonText: "Create"
                    onSubmitted: (text) => Presets.create(text)
                }

                SettingsControls.EntryRow {
                    label: "Import preset from file"
                    placeholder: "/path/to/preset.json"
                    buttonText: "Import"
                    description: "The imported preset keeps its file name. Reserved names (Default, Custom) are rejected."
                    onSubmitted: (text) => Presets.importPreset(text)
                }
            }
        }
    }

    // --------------------------------------------------------------- System

    component PageSystem: Item {
        id: systemPage
        implicitHeight: systemCol.implicitHeight
        property bool confirmReset: false

        Timer {
            interval: 3000
            onTriggered: systemPage.confirmReset = false
        }

        Process { id: sysProc }

        ColumnLayout {
            id: systemCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 10

            SettingsControls.SectionLabel { label: "System" }

            SettingsControls.Card {
                title: "Session"

                SettingsControls.ButtonRow {
                    label: "Reload Quickshell"
                    description: "Restart the shell process. The bar disappears for a moment."
                    buttonText: "Reload"
                    onClicked: {
                        sysProc.command = ["sh", "-c",
                            "pkill -f 'qs .*bar/shell.qml'; (qs -p ~/.config/quickshell/bar/shell.qml >/dev/null 2>&1 &)"]
                        sysProc.running = true
                    }
                }

                SettingsControls.ButtonRow {
                    label: "Reload MangoWM"
                    description: "Reload compositor configuration (mmsg reload_config)."
                    buttonText: "Reload"
                    onClicked: {
                        sysProc.command = ["sh", "-c", "mmsg reload_config"]
                        sysProc.running = true
                    }
                }

                SettingsControls.ButtonRow {
                    label: "Open config directory"
                    description: Config.configPath
                    buttonText: "Open"
                    onClicked: {
                        sysProc.command = ["xdg-open", Quickshell.env("HOME") + "/.config/quickshell"]
                        sysProc.running = true
                    }
                }
            }

            SettingsControls.Card {
                title: "Danger zone"

                SettingsControls.ButtonRow {
                    label: "Reset all settings"
                    description: "Same as applying the Default preset. Cannot be undone."
                    buttonText: systemPage.confirmReset ? "Click again to confirm" : "Reset everything"
                    onClicked: {
                        if (systemPage.confirmReset) {
                            Config.resetAll()
                            systemPage.confirmReset = false
                        } else {
                            systemPage.confirmReset = true
                        }
                    }
                }
            }
        }
    }

    // ----------------------------------------------------------------- About

    component PageAbout: Item {
        id: pageAboutRoot
        implicitHeight: aboutCol.implicitHeight

        ColumnLayout {
            id: aboutCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 10

            SettingsControls.SectionLabel { label: "About" }

            SettingsControls.Card {
                title: "Edots Settings"

                Text {
                    Layout.fillWidth: true
                    text: "Customization system for the Edots rice. The Settings app is being rolled out in phases — new categories appear as they are wired to the shell."
                    color: Colors.grey1
                    wrapMode: Text.Wrap
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }
            }

            SettingsControls.Card {
                title: "Paths"

                SettingsControls.InfoRow {
                    title: "Settings file"
                    detail: Config.configPath
                }

                SettingsControls.InfoRow {
                    title: "Presets directory"
                    detail: Presets.presetDir
                }

                SettingsControls.InfoRow {
                    title: "Active preset"
                    detail: Presets.active
                }

                SettingsControls.InfoRow {
                    title: "User presets"
                    detail: Presets.names.length + " saved"
                }
            }
        }
    }
    // ----------------------------------------------------------------- Pill

    component PagePill: Item {
        id: pagePillRoot
        implicitHeight: pillCol.implicitHeight

        ColumnLayout {
            id: pillCol
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: 10

            SettingsControls.SectionLabel { label: "Pill" }

            SettingsControls.Card {
                title: "Geometry"

                SettingsControls.SliderRow {
                    category: "pill"; configKey: "idleHeight"
                    label: "Idle height"; from: 20; to: 80; suffix: " px"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "idleHorizontalPadding"
                    label: "Idle horizontal padding"; from: 4; to: 60; suffix: " px"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "idleTopMargin"
                    label: "Top margin"; from: 0; to: 40; suffix: " px"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "expandedWidth"
                    label: "Expanded width"; from: 320; to: 1200; stepSize: 10; suffix: " px"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "expandedHeight"
                    label: "Expanded height"; from: 200; to: 900; stepSize: 10; suffix: " px"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "expandedRadius"
                    label: "Corner radius (surface open)"; from: 0; to: 60; suffix: " px"
                }
            }

            SettingsControls.Card {
                title: "Style"

                SettingsControls.SliderRow {
                    category: "pill"; configKey: "backgroundOpacity"
                    label: "Background opacity"; from: 0.3; to: 1.0
                    stepSize: 0.01; decimals: 2
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "hoverScale"
                    label: "Hover scale"; from: 1.0; to: 1.2
                    stepSize: 0.01; decimals: 2
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "borderWidthDefault"
                    label: "Border width"; from: 0; to: 6; suffix: " px"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "borderWidthHover"
                    label: "Border width (hover)"; from: 0; to: 8; suffix: " px"
                }
                SettingsControls.SwitchRow {
                    category: "pill"; configKey: "glowEnabled"
                    label: "Accent glow"
                    description: "Breathing accent border around the pill."
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "glowMinOpacity"
                    label: "Glow minimum opacity"; from: 0.0; to: 1.0
                    stepSize: 0.01; decimals: 2
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "glowMaxOpacity"
                    label: "Glow maximum opacity"; from: 0.0; to: 1.0
                    stepSize: 0.01; decimals: 2
                }
            }

            SettingsControls.Card {
                title: "Animations"

                SettingsControls.SliderRow {
                    category: "pill"; configKey: "morphDuration"
                    label: "Morph duration"; from: 0; to: 2000; stepSize: 20; suffix: " ms"
                    description: "Idle <-> expanded size transition."
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "morphOvershoot"
                    label: "Morph overshoot"; from: 0.5; to: 2.5
                    stepSize: 0.05; decimals: 2
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "radiusTransitionDuration"
                    label: "Radius transition"; from: 0; to: 1000; stepSize: 20; suffix: " ms"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "scaleDuration"
                    label: "Hover scale duration"; from: 0; to: 1000; stepSize: 20; suffix: " ms"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "borderTransitionDuration"
                    label: "Border transition"; from: 0; to: 1000; stepSize: 20; suffix: " ms"
                }
                SettingsControls.SliderRow {
                    category: "pill"; configKey: "glowBreathDuration"
                    label: "Glow breathing cycle"; from: 400; to: 8000; stepSize: 100; suffix: " ms"
                }
            }
        }
    }

}
