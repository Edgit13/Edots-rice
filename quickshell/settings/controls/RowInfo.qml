pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: r
    required property string label
    required property string value

    Layout.fillWidth: true
    spacing: M3.s12
    visible: SettingsSearch.matches(label)

    Text {
        Layout.fillWidth: true
        text: r.label
        color: M3.m3OnSurface
        font: M3.bodyMedium
    }
    Text {
        text: r.value
        color: M3.m3OnSurfaceVariant
        font: M3.monoMedium
        elide: Text.ElideMiddle
    }
}
