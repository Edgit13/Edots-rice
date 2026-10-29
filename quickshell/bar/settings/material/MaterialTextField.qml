pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Layouts

// M3 Outlined TextField: label над полем, у фокусі — 2dp primary.
ColumnLayout {
    id: tf

    property string label: ""
    property string placeholder: ""
    property string text: input.text
    property bool enabled_: true
    spacing: Theme.space.xs
    Layout.fillWidth: true

    ThemedText {
        visible: tf.label.length > 0
        text: tf.label
        style: Theme.type.labelMedium
        color: input.activeFocus && !Theme.settings.nothing ? Theme.color.primary : Theme.color.fgSurfaceVariant
        font.capitalization: Theme.settings.nothing ? Font.AllUppercase : Font.MixedCase
        font.letterSpacing: Theme.settings.nothing ? 2 : style.tracking
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.components.dp(48)
        radius: Theme.shape.field
        color: "transparent"
        border.width: Theme.settings.nothing ? 1 : (input.activeFocus ? Theme.components.dp(2) : 1)
        border.color: Theme.settings.nothing
            ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, input.activeFocus ? 0.75 : 0.25)
            : (input.activeFocus ? Theme.color.primary : Theme.color.outline)
        opacity: tf.enabled_ ? 1 : Theme.components.disabledContent
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
            selectionColor: Theme.settings.nothing ? ThemeNothing.red : Theme.color.primary
            selectedTextColor: Theme.settings.nothing ? "#FFFFFF" : Theme.color.fgPrimary
            cursorDelegate: Theme.settings.nothing ? nothingCaret : null
            Component { id: nothingCaret; Rectangle { width: 2; color: ThemeNothing.red } }

            ThemedText {
                anchors.fill: parent
                visible: input.text.length === 0
                text: tf.placeholder
                style: Theme.type.bodyLarge
                color: Theme.color.fgSurfaceVariant
            }
        }
    }
}
