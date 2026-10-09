pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

RowLayout {
    Layout.fillWidth: true
    id: r
    required property string category
    required property string configKey
    required property string label
    property string description: ""

    spacing: M3.s12
    visible: SettingsSearch.matches(label)

    readonly property color value: SettingsState.get(category, configKey)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            Layout.fillWidth: true
            text: r.label
            color: M3.m3OnSurface
            font: M3.bodyLarge
        }
        Text {
            Layout.fillWidth: true
            visible: r.description.length > 0
            text: r.description
            color: M3.m3OnSurfaceVariant
            font: M3.bodySmall
            wrapMode: Text.Wrap
        }
    }

    Text {
        text: String(SettingsState.get(r.category, r.configKey))
        color: M3.m3OnSurfaceVariant
        font: M3.monoMedium
    }

    Rectangle {
        id: swatch
        implicitWidth: 32; implicitHeight: 32
        radius: M3.rS
        color: r.value
        border.width: 1
        border.color: M3.outline
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible = !popup.visible
        }
    }

    ResetDot { category: r.category; configKey: r.configKey }

    Rectangle {
        id: popup
        visible: false
        z: 100
        width: 220
        height: 130
        x: swatch.x - width + swatch.width
        y: swatch.y + swatch.height + 6
        radius: M3.rM
        color: M3.surfaceContainerHigh
        border.width: 1
        border.color: M3.outlineVariant

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: M3.s12
            spacing: M3.s8

            Text {
                text: "Pick color"
                color: M3.m3OnSurface
                font: M3.labelLarge
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: M3.rS
                color: M3.surfaceContainer
                border.width: 1
                border.color: hexField.activeFocus ? M3.primary : M3.outline

                TextInput {
                    id: hexField
                    anchors.fill: parent
                    anchors.leftMargin: M3.s12
                    anchors.rightMargin: M3.s12
                    verticalAlignment: TextInput.AlignVCenter
                    color: M3.m3OnSurface
                    font: M3.monoMedium
                    text: String(SettingsState.get(r.category, r.configKey))
                    onAccepted: {
                        const v = text.trim()
                        if (/^#[0-9a-fA-F]{6}$/.test(v)) {
                            SettingsState.set(r.category, r.configKey, v)
                            popup.visible = false
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: M3.s8
                Repeater {
                    model: ["#74e7c8", "#d27c79", "#d1df9f", "#90d5c2", "#31816c"]
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 24
                        radius: M3.rS
                        color: modelData
                        border.width: 1
                        border.color: M3.outlineVariant
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SettingsState.set(r.category, r.configKey, modelData)
                                popup.visible = false
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
