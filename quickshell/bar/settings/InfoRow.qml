pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

Rectangle {
    id: infoRowRoot
    required property string title
    required property string detail
    property bool isSettingsControl: true
    visible: SettingsSearch.matches(title)

    Layout.fillWidth: true
    implicitHeight: infoCol.implicitHeight + 20
    radius: 10
    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.72)

    ColumnLayout {
        id: infoCol
        anchors.fill: parent
        anchors.margins: 10
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: infoRowRoot.title
            color: Colors.fg
            elide: Text.ElideRight
            font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
        }
        Text {
            Layout.fillWidth: true
            text: infoRowRoot.detail
            color: Colors.grey1
            elide: Text.ElideMiddle
            wrapMode: Text.Wrap
            font { family: "SF Pro Display"; pixelSize: 10 }
        }
    }
}
