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

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: Theme.components.dp(48)
        radius: Theme.shape.field
        color: Theme.color.surfaceContainerHighest
        border.width: input.activeFocus ? Theme.components.dp(2) : 0
        border.color: Theme.color.primary
        Behavior on border.color { MotionColorAnimation { role: "hover" } }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: Theme.space.lg
            anchors.rightMargin: Theme.space.lg
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.color.fgSurface
            font.family: Theme.type.bodyLarge.family
            font.pixelSize: Theme.type.bodyLarge.size
            selectByMouse: true
            clip: true
            text: String(Settings.get(r.cat, r.key) ?? "")
            onEditingFinished: Settings.set(r.cat, r.key, text)
            Keys.onReturnPressed: { Settings.set(r.cat, r.key, text); focus = false }
        }
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
