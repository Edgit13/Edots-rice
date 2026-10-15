pragma ComponentBehavior: Bound
import "root:/theme"
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
    spacing: Theme.space.sm
    visible: SettingsSearch.matches(Lang.searchText(r.cat, r.key, r.field))

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.space.sm
        ThemedText {
            Layout.fillWidth: true
            text: Lang.label(r.cat, r.key, r.field)
            style: Theme.type.bodyLarge
        }
        ResetDot { cat: r.cat; key: r.key }
    }

    MaterialDropdown {
        Layout.fillWidth: true
        options: (r.field.options || []).map(o => ({ value: o, label: Lang.opt(r.cat, r.key, o) }))
        value: Settings.get(r.cat, r.key)
        onSelected: (v) => Settings.set(r.cat, r.key, v)
    }

    ThemedText {
        visible: Lang.desc(r.cat, r.key, r.field).length > 0
        Layout.fillWidth: true
        text: Lang.desc(r.cat, r.key, r.field)
        style: Theme.type.bodySmall
        color: Theme.color.fgSurfaceVariant
        wrapMode: Text.Wrap
    }
}
