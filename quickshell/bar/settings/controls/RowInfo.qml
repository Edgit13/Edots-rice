pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: r
    required property string label
    required property string value

    Layout.fillWidth: true
    spacing: Theme.space.md
    visible: SettingsSearch.matches(label)

    ThemedText {
        Layout.fillWidth: true
        text: r.label
        style: Theme.type.bodyLarge
    }
    ThemedText {
        text: r.value
        style: Theme.type.monoMedium
        color: Theme.color.fgSurfaceVariant
        elide: Text.ElideMiddle
    }
}
