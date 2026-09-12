pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

Text {
    required property string category
    required property string configKey

    visible: Config.isDirty(category, configKey)
    text: "↺"
    color: resetHover.hovered ? Colors.accent : Colors.grey1
    font { family: "SF Pro Display"; pixelSize: 11 }

    HoverHandler { id: resetHover }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.resetKey(category, configKey)
    }
}
