pragma ComponentBehavior: Bound
import "root:/"
import QtQuick
import QtQuick.Layouts

// Material 3 OutlinedTextField: label над полем, focus — 2px primary border.
ColumnLayout {
    id: tf
    property string label: ""
    property string placeholder: ""
    property string text: input.text
    property bool enabled_: true
    spacing: M3.s4
    Layout.fillWidth: true

    Text {
        visible: tf.label.length > 0
        text: tf.label
        color: M3.onSurfaceVariant
        font: M3.labelMedium
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: M3.rS
        color: M3.surfaceContainerLow
        border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? M3.primary : M3.outline
        opacity: tf.enabled_ ? 1.0 : M3.disabledOpacity

        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: M3.s12
            anchors.rightMargin: M3.s12
            verticalAlignment: TextInput.AlignVCenter
            color: M3.onSurface
            font: M3.bodyMedium
            clip: true

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: input.text.length === 0
                text: tf.placeholder
                color: M3.onSurfaceVariant
                font: input.font
            }
        }
    }
}
