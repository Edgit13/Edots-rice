pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

Text {
    required property string label
    Layout.fillWidth: true
    Layout.topMargin: 6
    text: label.toUpperCase()
    color: Colors.accent
    font { family: "SF Pro Display"; pixelSize: 11; weight: 700 }
}
