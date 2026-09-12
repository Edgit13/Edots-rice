pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Page extracted from the former SettingsPages.qml monolith (Phase 4 fix).

Item {
    id: pageAboutRoot
    implicitHeight: aboutCol.implicitHeight

    ColumnLayout {
        id: aboutCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "About" }

        Card {
            title: "Edots Settings"

            Text {
                Layout.fillWidth: true
                text: "Customization system for the Edots rice. The Settings app is being rolled out in phases — new categories appear as they are wired to the shell."
                color: Colors.grey1
                wrapMode: Text.Wrap
                font { family: "SF Pro Display"; pixelSize: 11 }
            }
        }

        Card {
            title: "Paths"

            InfoRow {
                title: "Settings file"
                detail: Config.configPath
            }

            InfoRow {
                title: "Presets directory"
                detail: Presets.presetDir
            }

            InfoRow {
                title: "Active preset"
                detail: Presets.active
            }

            InfoRow {
                title: "User presets"
                detail: Presets.names.length + " saved"
            }
        }
    }
}
