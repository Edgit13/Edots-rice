import "root:/theme"
import "root:/settings"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// PowerSurface — Material 3 (Phase G). Логіка (lock/logout/reboot/shutdown) збережена.
ColumnLayout {
    id: root
    spacing: 8

    component PowerRow: Rectangle {
        id: pr
        property string glyph: ""
        property string label: ""
        property color iconColor: Colors.grey2
        property string command: ""
        Layout.fillWidth: true
        readonly property bool nothing: Theme.settings.nothing
        Layout.preferredHeight: nothing ? 48 : 44
        radius: nothing ? ThemeNothing.corners.md - 2 : 8
        // Nothing: прозорий рядок із тонким контуром; hover — легка заливка, контур яскравішає
        color: nothing
            ? (prMa.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.06) : "transparent")
            : (prMa.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08) : Colors.bg1)
        border.width: nothing ? 1 : 0
        border.color: prMa.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.45)
                                         : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.16)
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Clean Process component (inherits display environment naturally)
        Process { id: proc }

        MouseArea {
            id: prMa
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            z: 10

            onClicked: {
                if (pr.command === "lock") {
                    // Fully quoted string for sh -c execution using absolute path
                    proc.command = ["sh", "-c", "qs -p $HOME/.config/quickshell/bar/shell.qml ipc call ilock relock"]
                } else {
                    proc.command = ["sh", "-c", pr.command]
                }
                proc.running = true
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            Text {
                text: pr.glyph
                color: pr.iconColor
                font { family: "Material Symbols Rounded"; pixelSize: 19 }
                MouseArea { anchors.fill: parent; propagateComposedEvents: true; enabled: false }
            }
            Text {
                Layout.fillWidth: true
                text: pr.nothing ? pr.label.toUpperCase() : pr.label
                color: Colors.fg
                font {
                    family: pr.nothing ? Theme.type.mono : Colors.uiFont
                    pixelSize: pr.nothing ? 11 : 12
                    letterSpacing: pr.nothing ? 2 : 0
                }
                MouseArea { anchors.fill: parent; propagateComposedEvents: true; enabled: false }
            }
        }
    }

    PowerRow {
        glyph: "\ue899"; label: Lang.t("lock.lockNow")
        command: "lock"
        iconColor: Colors.accent
    }
    PowerRow {
        glyph: "\ue9ba"; label: Lang.t("lock.logout")
        command: "loginctl terminate-user $USER"
    }
    PowerRow {
        glyph: "\uf053"; label: Lang.t("lock.reboot")
        command: "systemctl reboot"
    }
    PowerRow {
        glyph: "\ue8ac"; label: Lang.t("lock.shutdown")
        iconColor: Colors.red
        command: "systemctl poweroff"
    }
}
