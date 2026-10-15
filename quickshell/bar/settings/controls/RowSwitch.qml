pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: r
    required property string cat
    required property string key
    required property var field

    Layout.fillWidth: true
    spacing: Theme.space.md
    visible: SettingsSearch.matches(Lang.searchText(r.cat, r.key, r.field))

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        ThemedText {
            Layout.fillWidth: true
            text: Lang.label(r.cat, r.key, r.field)
            style: Theme.type.bodyLarge
        }
        ThemedText {
            Layout.fillWidth: true
            visible: Lang.desc(r.cat, r.key, r.field).length > 0
            text: Lang.desc(r.cat, r.key, r.field)
            style: Theme.type.bodySmall
            color: Theme.color.fgSurfaceVariant
            wrapMode: Text.Wrap
        }
    }

    ResetDot { cat: r.cat; key: r.key }

    MaterialSwitch {
        Layout.alignment: Qt.AlignVCenter
        checked: !!Settings.get(r.cat, r.key)
        onToggled: Settings.set(r.cat, r.key, !checked)
    }
}
