pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

Rectangle {
    id: btnRowRoot
    required property string label
    property string description: ""
    required property string buttonText
    signal clicked()
    property bool isSettingsControl: true
    visible: SettingsSearch.matches(label)

    Layout.fillWidth: true
    implicitHeight: btnInner.implicitHeight + 20
    radius: 10
    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.72)

    RowLayout {
        id: btnInner
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: btnRowRoot.label
                color: Colors.fg
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
            }
            Text {
                Layout.fillWidth: true
                visible: btnRowRoot.description.length > 0
                text: btnRowRoot.description
                color: Colors.grey1
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 10 }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: btnLbl.implicitWidth + 24
            implicitHeight: 26
            radius: 8
            color: btnHover.hovered
                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
            border.width: 1
            border.color: Colors.accent

            Text {
                id: btnLbl
                anchors.centerIn: parent
                text: btnRowRoot.buttonText
                color: Colors.accent
                font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
            }

            HoverHandler { id: btnHover }
            MouseArea {
                id: btnRowMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: btnRowRoot.clicked()
            }
        }
    }
}
