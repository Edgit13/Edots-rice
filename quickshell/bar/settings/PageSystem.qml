pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Page extracted from the former SettingsPages.qml monolith (Phase 4 fix).

Item {
    id: systemPage
    implicitHeight: systemCol.implicitHeight
    property bool confirmReset: false

    Timer {
        interval: 3000
        onTriggered: systemPage.confirmReset = false
    }

    Process { id: sysProc }

    ColumnLayout {
        id: systemCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "System" }

        Card {
            title: "Session"

            ButtonRow {
                label: "Reload Quickshell"
                description: "Restart the shell process. The bar disappears for a moment."
                buttonText: "Reload"
                onClicked: {
                    sysProc.command = ["sh", "-c",
                        "pkill -f 'qs .*bar/shell.qml'; (qs -p ~/.config/quickshell/bar/shell.qml >/dev/null 2>&1 &)"]
                    sysProc.running = true
                }
            }

            ButtonRow {
                label: "Reload MangoWM"
                description: "Reload compositor configuration (mmsg reload_config)."
                buttonText: "Reload"
                onClicked: {
                    sysProc.command = ["sh", "-c", "mmsg reload_config"]
                    sysProc.running = true
                }
            }

            ButtonRow {
                label: "Open config directory"
                description: Config.configPath
                buttonText: "Open"
                onClicked: {
                    sysProc.command = ["xdg-open", Quickshell.env("HOME") + "/.config/quickshell"]
                    sysProc.running = true
                }
            }
        }

        Card {
            title: "Danger zone"

            ButtonRow {
                label: "Reset all settings"
                description: "Same as applying the Default preset. Cannot be undone."
                buttonText: systemPage.confirmReset ? "Click again to confirm" : "Reset everything"
                onClicked: {
                    if (systemPage.confirmReset) {
                        Config.resetAll()
                        systemPage.confirmReset = false
                    } else {
                        systemPage.confirmReset = true
                    }
                }
            }
        }
    }
}
