pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: r
    required property string label
    property string description: ""
    required property string buttonText
    property string icon: ""
    signal clicked()

    Layout.fillWidth: true
    spacing: Theme.space.md
    visible: SettingsSearch.matches(label)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        ThemedText {
            Layout.fillWidth: true
            text: r.label
            style: Theme.type.bodyLarge
        }
        ThemedText {
            Layout.fillWidth: true
            visible: r.description.length > 0
            text: r.description
            style: Theme.type.bodySmall
            color: Theme.color.fgSurfaceVariant
            wrapMode: Text.Wrap
        }
    }

    MaterialButton {
        text: r.buttonText
        icon: r.icon
        style: "tonal"
        onClicked: r.clicked()
    }
}
