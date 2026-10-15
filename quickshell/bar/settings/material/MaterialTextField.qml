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
        color: input.activeFocus ? Theme.color.primary : Theme.color.fgSurfaceVariant
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Theme.components.dp(48)
        radius: Theme.shape.field
        color: "transparent"
        border.width: input.activeFocus ? Theme.components.dp(2) : 1
        border.color: input.activeFocus ? Theme.color.primary : Theme.color.outline
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
