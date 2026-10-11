pragma ComponentBehavior: Bound
import "../material"
import ".."
import "../controls"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    width: parent ? parent.width : 0
    spacing: M3.s12

    SectionHeader { label: "About" }
    SettingsCard {
        title: "Edots"
        Text {
            Layout.fillWidth: true
            text: "MangoWM + Quickshell rice. Settings app rebuilt on the shared Material 3 component library."
            color: M3.m3OnSurfaceVariant
            font: M3.bodyMedium
            wrapMode: Text.Wrap
        }
    }
    SettingsCard {
        title: "IPC"
        RowInfo { label: "Settings window"; value: "qs ipc call settingsapp toggle" }
        RowInfo { label: "Bar toggle";      value: "qs ipc call bar setPosition top" }
        RowInfo { label: "Lock screen";     value: "qs -p lockscreen/shell.qml" }
    }
}
