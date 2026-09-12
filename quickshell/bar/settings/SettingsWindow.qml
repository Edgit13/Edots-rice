pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import Quickshell.Wayland
import QtQuick

// ==========================================================================
// SettingsWindow.qml — окреме overlay-вікно Settings UI (Phase 3).
//
// Навмисне НЕ всередині pill-вікна: 25 категорій налаштувань не вміщуються
// в expanded-пігулку 480x300. Відкривається через IPC:
//   qs ipc call settingsapp toggle
//
// Клік по затемненню або Escape — закриття (keyboardFocus Exclusive, поки відкрито).
// ==========================================================================

PanelWindow {
    id: win

    visible: false

    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: win.visible
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function open(): void {
        win.visible = true
    }
    function close(): void {
        win.visible = false
    }
    function toggle(): void {
        if (win.visible) win.close()
        else win.open()
    }

    onVisibleChanged: {
        if (visible)
            card.forceActiveFocus()
    }

    // затемнення + клік поза вікном закриває
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: win.visible ? 0.4 : 0

        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            onClicked: win.close()
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(940, parent.width - 80)
        height: Math.min(620, parent.height - 80)
        radius: 24
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.98)
        border.width: 1
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)

        scale: win.visible ? 1.0 : 0.96
        opacity: win.visible ? 1.0 : 0.0

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Keys.onEscapePressed: win.close()

        SettingsApp {
            anchors.fill: parent
            anchors.margins: 16
        }
    }
}
