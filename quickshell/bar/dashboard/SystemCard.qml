import "root:/theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

DashCard {
    id: root

    property string osName: "Linux"
    property string wmName: "MangoWC"
    property string uptimeText: "—"

    function _fmtUptime(sec) {
        const h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60)
        if (h > 0) return h + " год " + m + " хв"
        return m + " хв"
    }

    Process {
        id: osProc
        command: ["sh", "-c", "grep '^PRETTY_NAME=' /etc/os-release | cut -d'\"' -f2"]
        stdout: StdioCollector { onStreamFinished: if (text.trim().length > 0) root.osName = text.trim() }
    }
    Process {
        id: upProc
        command: ["sh", "-c", "cat /proc/uptime"]
        stdout: StdioCollector { onStreamFinished: root.uptimeText = root._fmtUptime(parseFloat(text.split(" ")[0])) }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: { osProc.running = true; upProc.running = true } }

    RowLayout {
        width: parent.width
        spacing: Theme.space.md

        DashAvatar { size: 56 }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            RowLayout {
                spacing: Theme.space.xs
                Text { text: "\uf1a0"; font { family: Theme.type.icons; pixelSize: Theme.type.iconXS } color: Theme.color.fgSurfaceVariant }
                ThemedText { text: root.osName; style: Theme.type.bodyMedium }
            }
            RowLayout {
                spacing: Theme.space.xs
                Text { text: "\ue30d"; font { family: Theme.type.icons; pixelSize: Theme.type.iconXS } color: Theme.color.fgSurfaceVariant }
                ThemedText { text: root.wmName; style: Theme.type.bodyMedium }
            }
            RowLayout {
                spacing: Theme.space.xs
                Text { text: "\ue425"; font { family: Theme.type.icons; pixelSize: Theme.type.iconXS } color: Theme.color.fgSurfaceVariant }
                ThemedText { text: root.uptimeText; style: Theme.type.bodyMedium }
            }
        }
    }
}
