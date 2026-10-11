import "root:/theme"
import "root:/shell"
import Quickshell
import QtQuick
import QtQuick.Layouts

// STEP 2 — перевірка MorphShell/MorphShellState (плейсхолдер-модулі, без реальних бекендів):
//   qs -p ~/.config/quickshell/bar/MorphShellPreview.qml
// Наведи мишу на пігулку → peek (ряд глімпсів). Клік по Wi-Fi/Volume → module. Клік по
// Launcher → dialog. Esc — крок назад. Клік по фону превʼю — теж крок назад (imitates
// "клік поза межами").
ShellRoot {
    FloatingWindow {
        id: win
        visible: true
        implicitWidth: 900
        implicitHeight: 500
        color: Theme.color.surface

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: state.back()
        }

        MorphShellState { id: state }

        Component {
            id: clockGlimpse
            ThemedText { text: "12:42"; style: Theme.type.monoMedium; emphasized: true }
        }
        Component {
            id: wifiGlimpse
            Row { spacing: Theme.space.xs
                Text { text: "\ue63e"; font { family: Theme.type.icons; pixelSize: Theme.type.iconS } color: Theme.color.primary } }
        }
        Component {
            id: wifiPanel
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.space.sm
                ThemedText { text: "Wi-Fi"; style: Theme.type.titleMedium }
                Repeater {
                    model: ["Home", "Phone", "Other"]
                    ThemedText { required property string modelData; text: "● " + modelData; style: Theme.type.bodyMedium }
                }
                Item { Layout.fillHeight: true }
            }
        }
        Component {
            id: volGlimpse
            Row { spacing: Theme.space.xs
                Text { text: "\ue050"; font { family: Theme.type.icons; pixelSize: Theme.type.iconS } color: Theme.color.fgSurface }
                ThemedText { text: "72%"; style: Theme.type.labelMedium } }
        }
        Component {
            id: volPanel
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.space.sm
                ThemedText { text: "Гучність"; style: Theme.type.titleMedium }
                ThemedText { text: "72%"; style: Theme.type.displaySmall }
                Item { Layout.fillHeight: true }
            }
        }
        Component {
            id: launcherGlimpse
            Text { text: "\ue5c3"; font { family: Theme.type.icons; pixelSize: Theme.type.iconS } color: Theme.color.fgSurfaceVariant }
        }
        Component {
            id: launcherDialog
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.space.sm
                ThemedText { text: "Launcher (dialog tier)"; style: Theme.type.titleMedium }
                ThemedText { text: "Це має бути більше за module-панель"; style: Theme.type.bodyMedium; color: Theme.color.fgSurfaceVariant }
                Item { Layout.fillHeight: true }
            }
        }

        MorphShell {
            x: (win.width - implicitWidth) / 2
            y: 40
            shellState: state
            modules: [
                { key: "clock", glimpse: clockGlimpse, panel: null },
                { key: "wifi", glimpse: wifiGlimpse, panel: wifiPanel, panelWidth: 280, panelHeight: 220 },
                { key: "volume", glimpse: volGlimpse, panel: volPanel, panelWidth: 260, panelHeight: 180 },
                { key: "launcher", glimpse: launcherGlimpse, panel: null, dialogPanel: launcherDialog, dialogWidth: 500, dialogHeight: 380 }
            ]
        }

        ThemedText {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.space.md
            text: "state: " + state.state + "   active: " + state.activeModule + "   stack: " + state._stack.length
            style: Theme.type.labelMedium
            color: Theme.color.fgSurfaceVariant
        }
    }
}
