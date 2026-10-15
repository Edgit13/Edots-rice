import "root:/theme"
import "root:/services"
import Quickshell
import Quickshell.Wayland
import QtQuick

// NotificationPopups — стек спливаючих сповіщень у вибраному куті/краї (Settings → Notifications).
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property string pos: NotificationService.position
    readonly property bool atTop: pos.indexOf("top") === 0
    readonly property bool atBottom: pos.indexOf("bottom") === 0
    readonly property bool atLeft: pos === "left" || pos.indexOf("-left") > 0
    readonly property bool atRight: pos === "right" || pos.indexOf("-right") > 0

    readonly property real pad: Theme.components.dp(16)
    readonly property real gap: Theme.components.dp(8)
    readonly property real edge: Math.max(0, Math.round(NotificationService.margin * Theme.space.k) - pad)
    readonly property real offX: atLeft ? -1 : (atRight ? 1 : 0)

    readonly property bool target: NotificationService.isPopupTarget(win.screen)
    visible: target && NotificationService.toasts && !NotificationService.centerOpen && (NotificationService.popups.length > 0 || stack.height > 1)

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: win.atLeft; right: win.atRight }
    margins { top: win.edge; bottom: win.edge; left: win.edge; right: win.edge }
    implicitWidth: Theme.components.dp(NotificationService.cardWidth) + pad * 2
    mask: Region { item: stack }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "m3-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack
        x: win.pad
        width: parent.width - win.pad * 2
        y: win.atTop ? 0
         : win.atBottom ? parent.height - height
         : (parent.height - height) / 2

        Repeater {
            model: ScriptModel {
                values: win.atBottom ? NotificationService.items.slice().reverse() : NotificationService.items
            }

            Item {
                id: slot
                required property var modelData
                readonly property bool shown: NotificationService.popups.indexOf(modelData) >= 0
                property bool entered: false
                Component.onCompleted: entered = true

                width: stack.width
                height: shown ? card.implicitHeight + win.gap : 0
                visible: height > 0.5
                Behavior on height { MotionAnimation { role: slot.shown ? "expand" : "collapse" } }

                NotificationCard {
                    id: card
                    width: parent.width
                    notif: slot.modelData
                    popup: true
                    y: win.gap / 2
                    opacity: (slot.entered && slot.shown) ? 1 : 0
                    transform: Translate {
                        x: (slot.entered && slot.shown) ? 0 : win.offX * Theme.components.dp(56)
                        y: (slot.entered && slot.shown) || win.offX !== 0 ? 0
                           : (win.atBottom ? 1 : -1) * Theme.components.dp(32)
                        Behavior on x { MotionAnimation { role: (slot.entered && slot.shown) ? "move" : "exit" } }
                        Behavior on y { MotionAnimation { role: (slot.entered && slot.shown) ? "move" : "exit" } }
                    }
                    Behavior on opacity { MotionAnimation { role: (slot.entered && slot.shown) ? "enter" : "exit" } }

                    onRemoved: NotificationService.dismiss(slot.modelData)
                }
            }
        }
    }
}
