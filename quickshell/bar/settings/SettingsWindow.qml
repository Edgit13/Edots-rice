pragma ComponentBehavior: Bound
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
        color: M3.scrim
        opacity: win.visible ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: M3.durMed } }
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    // main card
    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(1020, parent.width - 80)
        height: Math.min(680, parent.height - 80)
        radius: M3.rXL
        color: M3.surfaceContainerHigh
        border.width: 1
        border.color: M3.outlineVariant

        scale: win.visible ? 1.0 : 0.94
        opacity: win.visible ? 1.0 : 0.0
        Behavior on scale   { NumberAnimation { duration: M3.durMed; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
        Behavior on opacity { NumberAnimation { duration: M3.durFast } }

        focus: true
        Keys.onEscapePressed: win.close()

        SettingsApp { anchors.fill: parent; anchors.margins: M3.s16 }
    }
}
