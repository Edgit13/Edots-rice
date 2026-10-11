pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: r
    required property string category
    required property string configKey
    required property string label
    property string description: ""

    Layout.fillWidth: true
    spacing: M3.s12
    visible: SettingsSearch.matches(label)

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

    MaterialSwitch {
        Layout.alignment: Qt.AlignVCenter
        checked: !!SettingsState.get(r.category, r.configKey)
        onToggled: SettingsState.set(r.category, r.configKey, !checked)
    }

    ResetDot { category: r.category; configKey: r.configKey }
}
