pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: r
    required property string cat
    required property string key
    required property var field

    Layout.fillWidth: true
    spacing: M3.s4
    visible: SettingsSearch.matches(r.field.label || r.key)

    RowLayout {
        Layout.fillWidth: true
        spacing: M3.s8
        Text {
            Layout.fillWidth: true
            text: r.field.label || r.key
            color: M3.m3OnSurface
            font: M3.bodyLarge
        }
        ResetDot { cat: r.cat; key: r.key }
    }

    MaterialDropdown {
        Layout.fillWidth: true
        options: r.field.options || []
        value: Settings.get(r.cat, r.key)
        onSelected: (v) => Settings.set(r.cat, r.key, v)
    }

    Text {
        visible: !!r.field.desc
        Layout.fillWidth: true
        text: r.field.desc || ""
        color: M3.m3OnSurfaceVariant
        font: M3.bodySmall
        wrapMode: Text.Wrap
    }
}
