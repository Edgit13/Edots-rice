import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.DockApp

// The dock's settings dialog, opened from the launcher button's menu or with
// `qs ipc call dock settings`.
//
// A regular toplevel window rather than something drawn inside the dock: it
// needs keyboard focus, can be moved, and closes like any other window. The
// dock's focus-grab trouble with popups (see DockMenu) does not apply, as the
// menu is already closed when this opens.
//
// The size is fixed (minimum = maximum), which makes the compositor float the
// window without a window rule.
//
// DockLoader creates it while DockSettings.dialogOpen is set, independently of
// the dock window, so it keeps working when the dock itself is turned off. The
// controls are bound straight to DockSettings: changes apply live and follow
// changes made elsewhere.
FloatingWindow {
    id: root

    title: "Dock Settings"
    visible: true
    color: DockTheme.background

    implicitWidth: 480
    implicitHeight: 300
    minimumSize: Qt.size(480, 300)
    maximumSize: Qt.size(480, 300)

    // Closed by the compositor (window close action): drop the flag so
    // DockLoader tears the window down and a later open builds it anew.
    onClosed: DockSettings.dialogOpen = false

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: DockSettings.dialogOpen = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // --- HEADER ---
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Dock Settings"
                    color: DockTheme.on_surface
                    font.family: DockTheme.fontFamily
                    font.pixelSize: 22
                }

                Item { Layout.fillWidth: true }

                // Close button: an M3 state layer circle behind a drawn ×.
                Item {
                    id: closeButton
                    implicitWidth: 30
                    implicitHeight: 30

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: DockTheme.primary
                        opacity: closeMouse.pressed ? 0.12
                               : closeMouse.containsMouse ? 0.08 : 0

                        Behavior on opacity {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuint }
                        }
                    }

                    Repeater {
                        model: [45, -45]
                        delegate: Rectangle {
                            required property int modelData
                            anchors.centerIn: parent
                            width: 14
                            height: 2
                            radius: 1
                            rotation: modelData
                            color: DockTheme.on_surface
                        }
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DockSettings.dialogOpen = false
                    }
                }
            }

            // --- AUTOHIDE ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Autohide"
                        color: DockTheme.on_surface
                        font.family: DockTheme.fontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Hide the dock until the pointer touches the bottom edge of the screen."
                        color: DockTheme.on_surface_variant
                        font.family: DockTheme.fontFamily
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }

                DockSwitch {
                    Layout.alignment: Qt.AlignVCenter
                    value: DockSettings.autohide
                    onToggledTo: on => DockSettings.setAutohide(on)
                }
            }

            // --- LAUNCHER ICON ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Launcher Icon"
                        color: DockTheme.on_surface
                        font.family: DockTheme.fontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Show the launcher button at the left end of the dock."
                        color: DockTheme.on_surface_variant
                        font.family: DockTheme.fontFamily
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }

                DockSwitch {
                    Layout.alignment: Qt.AlignVCenter
                    value: DockSettings.launcherButton
                    onToggledTo: on => DockSettings.setLauncherButton(on)
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
