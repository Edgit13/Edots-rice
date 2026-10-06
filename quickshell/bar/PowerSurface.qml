import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// PowerSurface — Material 3 (Phase G). Логіка (lock/logout/reboot/shutdown) збережена.
ColumnLayout {
    id: root
    spacing: 8

    Process {
        id: proc
        // Force clean process lifecycle handling
    }

    component PowerRow: Rectangle {
        id: pr
        property string glyph: ""
        property string label: ""
        property color iconColor: Colors.grey2
        property string command: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        radius: 8
        color: prMa.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08) : Colors.bg1
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12
            Text { text: pr.glyph; color: pr.iconColor; font { family: "Material Symbols Rounded"; pixelSize: 19 } }
            Text { Layout.fillWidth: true; text: pr.label; color: Colors.fg; font { family: "SF Pro Display"; pixelSize: 12 } }
        }

        MouseArea {
            id: prMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // Terminate any stuck shell operations before invoking a new one
                if (proc.running) {
                    proc.terminate();
                }

                if (pr.command === "lock") {
                    proc.command = ["sh", "-c", "pgrep -f 'qs -p .*lockscreen/shell.qml' || qs -p ~/.config/quickshell/lockscreen/shell.qml"]
                } else {
                    proc.command = ["sh", "-c", pr.command]
                }

                // FIX: Use start() instead of assigning running property directly
                proc.start();
            }
        }
    }

    PowerRow {
        glyph: "\ue899"; label: "Lock"
        command: "lock"
        iconColor: Colors.accent
    }
    PowerRow {
        glyph: "\ue9ba"; label: "Log out"
        command: "loginctl terminate-user $USER"
    }
    PowerRow {
        glyph: "\uf053"; label: "Reboot"
        command: "systemctl reboot"
    }
    PowerRow {
        glyph: "\ue8ac"; label: "Shut down"
        iconColor: Colors.red
        command: "systemctl poweroff"
    }
}
