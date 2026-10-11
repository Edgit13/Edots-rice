pragma ComponentBehavior: Bound
import "../material"
import ".."
import "../controls"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    width: parent ? parent.width : 0
    spacing: M3.s12

    SectionHeader { label: "Presets" }
    SettingsCard {
        title: "Default"
        Text {
            Layout.fillWidth: true
            text: "Restore every setting to factory."
            color: M3.m3OnSurfaceVariant
            font: M3.bodySmall
        }
        RowButton {
            label: "Reset everything"
            buttonText: "Reset"
            icon: "restart_alt"
            onClicked: SettingsState.resetAll()
        }
    }
}
