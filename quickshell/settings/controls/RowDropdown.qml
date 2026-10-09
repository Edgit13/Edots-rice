pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: r
    required property string category
    required property string configKey
    required property string label
    property string description: ""

    Layout.fillWidth: true
    spacing: M3.s4
    visible: SettingsSearch.matches(label)

    readonly property var s: SettingsState.schema[category] ? SettingsState.schema[category][configKey] : null

    RowLayout {
        Layout.fillWidth: true
        spacing: M3.s8
        Text {
            Layout.fillWidth: true
            text: r.label
            color: M3.m3OnSurface
            font: M3.bodyLarge
        }
        ResetDot { category: r.category; configKey: r.configKey }
    }

    MaterialDropdown {
        Layout.fillWidth: true
        options: r.s && r.s.options ? r.s.options : []
        value: SettingsState.get(r.category, r.configKey)
        onSelected: (v) => SettingsState.set(r.category, r.configKey, v)
    }

    Text {
        visible: r.description.length > 0
        Layout.fillWidth: true
        text: r.description
        color: M3.m3OnSurfaceVariant
        font: M3.bodySmall
        wrapMode: Text.Wrap
    }
}
