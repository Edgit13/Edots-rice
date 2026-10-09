pragma ComponentBehavior: Bound
import "../material"
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    Layout.fillWidth: true
    width: parent ? parent.width : 0
    spacing: M3.s12

    Process { id: proc }

    SectionHeader { label: "Session" }
    SettingsCard {
        title: "Reload"
        RowButton {
            label: "Reload bar"
            description: "Restart the bar shell process."
            buttonText: "Reload"
            icon: "refresh"
            onClicked: {
                proc.command = ["sh", "-c",
                    "pkill -f 'qs .*bar/shell.qml'; (qs -p " +
                    Quickshell.env("HOME") + "/.config/quickshell/bar/shell.qml >/dev/null 2>&1 &)"]
                proc.running = true
            }
        }
        RowButton {
            label: "Reload lock screen"
            description: "Kill any running lockscreen so the next lock uses the new settings."
            buttonText: "Kill"
            icon: "cancel"
            onClicked: {
                proc.command = ["sh", "-c", "pkill -f 'lockscreen/shell.qml'"]
                proc.running = true
            }
        }
    }

    SectionHeader { label: "Files" }
    SettingsCard {
        title: "Paths"
        RowInfo { label: "Config dir";  value: Quickshell.env("HOME") + "/.config/quickshell" }
        RowInfo { label: "Colors";      value: "colors.json" }
        RowInfo { label: "Settings";    value: "settings.json" }
        RowInfo { label: "Theme";       value: "theme.json" }
        RowInfo { label: "Lock screen"; value: "lockscreen.json" }
    }

    SectionHeader { label: "Danger zone" }
    SettingsCard {
        title: "Reset"
        RowButton {
            label: "Reset all settings"
            description: "Cannot be undone."
            buttonText: "Reset"
            icon: "warning"
            onClicked: SettingsState.resetAll()
        }
    }
}
