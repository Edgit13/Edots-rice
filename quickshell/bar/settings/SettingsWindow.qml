pragma ComponentBehavior: Bound
import "root:/theme"
import "."
import "material"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: win
    visible: false

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: win.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }

    function open(): void   { win.visible = true }
    function close(): void  { win.visible = false }
    function toggle(): void { win.visible ? win.close() : win.open() }

    onVisibleChanged: if (visible) card.forceActiveFocus()

    // scrim
    Rectangle {
        anchors.fill: parent
        color: Theme.color.scrim
        opacity: win.visible ? 0.5 : 0
        Behavior on opacity { MotionAnimation { role: "fade" } }
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    // main card (M3E: shape.dialog, scale-морф із overshoot)
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(Theme.components.dp(1080), parent.width - Theme.space.xxl * 2)
        height: Math.min(Theme.components.dp(700), parent.height - Theme.space.xxl * 2)
        radius: Theme.shape.dialog
        color: Theme.color.surface
        border.width: 1
        border.color: Theme.color.outlineVariant

        scale: win.visible ? 1 : 0.92
        opacity: win.visible ? 1 : 0
        Behavior on scale { MotionAnimation { role: "expand" } }
        Behavior on opacity { MotionAnimation { role: "fade" } }

        focus: true
        Keys.onEscapePressed: win.close()

        SettingsApp {
            anchors.fill: parent
            anchors.margins: Theme.space.sm
        }
    }
}
