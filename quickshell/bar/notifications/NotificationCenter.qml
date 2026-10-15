pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/settings"
import "root:/services"
import "root:/settings/material"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// NotificationCenter — M3 side sheet: не турбувати, очистити, групи за застосунками.
// Сторона (ліворуч / праворуч) — за позицією сповіщень у налаштуваннях.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property bool target: NotificationService.isCenterTarget(win.screen)
    readonly property bool open: NotificationService.centerOpen && target
    readonly property bool atLeft: NotificationService.position === "left" || NotificationService.position.indexOf("-left") > 0
    readonly property real m: Theme.space.md

    // як у end-4: просто плаваюча панель біля краю — без scrim і без повноекранної поверхні
    visible: open || panel.opacity > 0.01
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: win.atLeft; right: !win.atLeft }
    margins { top: win.m; bottom: win.m; left: win.m; right: win.m }
    implicitWidth: Math.min(Theme.components.dp(420), win.screen.width - win.m * 2)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "m3-notification-center"
    WlrLayershell.keyboardFocus: win.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: if (open) panel.forceActiveFocus()

    Rectangle {
        id: panel
        width: parent.width
        height: parent.height
        radius: Theme.shape.dialog
        color: Theme.color.surfaceContainerLow
        border.width: 1
        border.color: Theme.color.outlineVariant

        // виїжджає від краю екрана
        x: win.open ? 0 : (win.atLeft ? -width - win.m : width + win.m)
        opacity: win.open ? 1 : 0
        Behavior on x { MotionAnimation { role: win.open ? "move" : "exit" } }
        Behavior on opacity { MotionAnimation { role: win.open ? "enter" : "exit" } }

        focus: true
        Keys.onEscapePressed: NotificationService.closeCenter()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.space.lg
            spacing: Theme.space.md

            // ---- заголовок ----
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.sm
                ThemedText {
                    text: Lang.t("ui.notif.title")
                    style: Theme.type.headlineSmall
                }
                Rectangle {
                    visible: NotificationService.count > 0
                    implicitWidth: total.implicitWidth + Theme.space.lg
                    implicitHeight: Theme.components.dp(24)
                    radius: height / 2
                    color: Theme.color.primaryContainer
                    ThemedText {
                        id: total
                        anchors.centerIn: parent
                        text: NotificationService.count
                        style: Theme.type.labelMedium
                        emphasized: true
                        color: Theme.color.fgPrimaryContainer
                    }
                }
                Item { Layout.fillWidth: true }
                MaterialButton {
                    visible: NotificationService.count > 0
                    text: Lang.t("ui.notif.clear")
                    icon: "delete_sweep"
                    style: "tonal"
                    onClicked: NotificationService.clearAll()
                }
                MaterialIconButton {
                    icon: "close"
                    onClicked: NotificationService.closeCenter()
                }
            }

            // ---- не турбувати ----
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.components.dp(64)
                radius: Theme.shape.cardLarge
                color: NotificationService.dnd ? Theme.color.primaryContainer : Theme.color.surfaceContainerHigh
                Behavior on color { MotionColorAnimation { role: "stateChange" } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.lg
                    anchors.rightMargin: Theme.space.lg
                    spacing: Theme.space.md
                    Text {
                        text: NotificationService.dnd ? "\ue7f6" : "\ue7f4"          // notifications_off / notifications
                        color: NotificationService.dnd ? Theme.color.fgPrimaryContainer : Theme.color.fgSurfaceVariant
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        ThemedText {
                            text: Lang.t("ui.notif.dnd")
                            style: Theme.type.bodyLarge
                            color: NotificationService.dnd ? Theme.color.fgPrimaryContainer : Theme.color.fgSurface
                        }
                        ThemedText {
                            text: Lang.t("ui.notif.dnd.desc")
                            style: Theme.type.bodySmall
                            color: NotificationService.dnd ? Theme.color.fgPrimaryContainer : Theme.color.fgSurfaceVariant
                        }
                    }
                    MaterialSwitch {
                        checked: NotificationService.dnd
                        onToggled: NotificationService.setDnd(!NotificationService.dnd)
                    }
                }
            }

            // ---- список ----
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: flick
                    anchors.fill: parent
                    clip: true
                    contentWidth: width
                    contentHeight: groupsCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: groupsCol
                        width: flick.width
                        spacing: Theme.space.lg

                        Repeater {
                            model: ScriptModel {
                                values: NotificationService.groups
                                objectProp: "key"
                            }
                            NotificationGroup {}
                        }
                    }
                }

                // порожній стан
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: NotificationService.count === 0
                    spacing: Theme.space.sm
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: Theme.components.dp(72)
                        implicitHeight: implicitWidth
                        radius: Theme.shape.radius("lg", height)
                        color: Theme.color.secondaryContainer
                        Text {
                            anchors.centerIn: parent
                            text: "\ue7f4"
                            color: Theme.color.fgSecondaryContainer
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconXL }
                        }
                    }
                    ThemedText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Lang.t("ui.notif.empty")
                        style: Theme.type.bodyLarge
                        color: Theme.color.fgSurfaceVariant
                    }
                }
            }
        }
    }
}
