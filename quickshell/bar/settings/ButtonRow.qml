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
            radius: Md.rFull
            color: btnHover.hovered ? Md.mix(Md.secondaryContainer, Md.primary, 0.15) : Md.secondaryContainer
            border.width: 0

            Text {
                id: btnLbl
                anchors.centerIn: parent
                text: btnRowRoot.buttonText
                color: Colors.accent
                font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
            }

            HoverHandler { id: btnHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: btnRowRoot.clicked()
            }
        }
    }
}
