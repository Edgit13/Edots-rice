pragma ComponentBehavior: Bound
import ".."
import "../material"
import "../controls"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    width: parent ? parent.width : 0
    spacing: M3.s12

    SectionHeader { label: "Position" }
    SettingsCard {
        title: "Placement"
        RowDropdown { category: "bar"; configKey: "position"; label: "Panel position"
            description: "Which screen edge the bar hugs." }
        RowDropdown { category: "bar"; configKey: "mode"; label: "Bar mode"
            description: "compact | expanded | morphing (pill)." }
        RowSlider { category: "bar"; configKey: "elevation"; label: "Elevation"
            suffix: ""; decimals: 0 }
    }

    SectionHeader { label: "Modules" }
    SettingsCard {
        title: "Visibility"
        Repeater {
            model: ["launcher","workspaces","window","clock","media","mixer","wifi","notifications","battery","power"]
            RowSwitch {
                required property string modelData
                category: "modules"
                configKey: modelData
                label: modelData.charAt(0).toUpperCase() + modelData.slice(1)
            }
        }
    }

    SettingsCard {
        title: "Order"
        Text {
            Layout.fillWidth: true
            text: "Move modules up/down. Changes apply live."
            color: M3.m3OnSurfaceVariant
            font: M3.bodySmall
        }
        Repeater {
            model: SettingsState.get("modules", "order") || []
            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                implicitHeight: 36
                radius: M3.rS
                color: M3.surfaceContainerLow

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: M3.s12
                    anchors.rightMargin: M3.s12
                    Text {
                        Layout.fillWidth: true
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        color: M3.m3OnSurface
                        font: M3.bodyMedium
                    }
                    MaterialIconButton {
                        icon: "keyboard_arrow_up"; style: "standard"
                        onClicked: SettingsState.moveModule(modelData, -1)
                    }
                    MaterialIconButton {
                        icon: "keyboard_arrow_down"; style: "standard"
                        onClicked: SettingsState.moveModule(modelData, 1)
                    }
                }
            }
        }
    }
}
