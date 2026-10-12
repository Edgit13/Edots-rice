pragma ComponentBehavior: Bound
import ".."
import "../material"
import Quickshell
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

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: M3.rS
        color: M3.surfaceContainerLow
        border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? M3.primary : M3.outline

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: M3.s12
            anchors.rightMargin: M3.s12
            verticalAlignment: TextInput.AlignVCenter
            color: M3.m3OnSurface
            font: M3.bodyMedium
            selectByMouse: true
            text: String(Settings.get(r.cat, r.key) ?? "")
            onEditingFinished: Settings.set(r.cat, r.key, text)
            Keys.onReturnPressed: { Settings.set(r.cat, r.key, text); focus = false }
        }
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
