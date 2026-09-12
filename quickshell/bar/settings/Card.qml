pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

Rectangle {
    property string title: ""
    default property alias content: cardCol.children

    // Під час пошуку картка видима, лише якщо хоча б один контрол у ній
    // збігся із запитом.
    visible: {
        if (!SettingsSearch.active)
            return true
        for (let i = 0; i < cardCol.children.length; i++) {
            const c = cardCol.children[i]
            if (c.isSettingsControl !== undefined && c.isSettingsControl && c.visible)
                return true
        }
        return false
    }

    Layout.fillWidth: true
    radius: 12
    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.72)
    border.width: 1
    border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.14)
    implicitHeight: cardCol.implicitHeight + 24

    ColumnLayout {
        id: cardCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        Text {
            visible: title.length > 0 && !SettingsSearch.active
            text: title
            color: Colors.fg
            font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
        }
    }
}
