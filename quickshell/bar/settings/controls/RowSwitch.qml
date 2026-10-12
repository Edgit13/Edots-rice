pragma ComponentBehavior: Bound
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
    spacing: M3.s12
    visible: SettingsSearch.matches(r.field.label || r.key)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            Layout.fillWidth: true
            text: r.field.label || r.key
            color: M3.m3OnSurface
            font: M3.bodyLarge
        }
        Text {
            Layout.fillWidth: true
            visible: !!r.field.desc
            text: r.field.desc || ""
            color: M3.m3OnSurfaceVariant
            font: M3.bodySmall
            wrapMode: Text.Wrap
        }
    }

    MaterialSwitch {
        Layout.alignment: Qt.AlignVCenter
        checked: !!Settings.get(r.cat, r.key)
        onToggled: Settings.set(r.cat, r.key, !checked)
    }

    ResetDot { cat: r.cat; key: r.key }
}
