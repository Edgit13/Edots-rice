pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

ColumnLayout {
    id: entryRowRoot
    required property string label
    property string description: ""
    property string placeholder: ""
    property string buttonText: "OK"
    signal submitted(string text)

    Layout.fillWidth: true
    spacing: 6

    function submit() {
        const t = entryInput.text.trim()
        if (t.length === 0)
            return
        entryRowRoot.submitted(t)
        entryInput.text = ""
    }

    Text {
        text: entryRowRoot.label
        color: Colors.fg
        font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 8
            color: Colors.bg2
            border.width: 1
            border.color: entryInput.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)

            TextInput {
                id: entryInput
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 11 }
                clip: true

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    visible: entryInput.text.length === 0
                    text: entryRowRoot.placeholder
                    color: Colors.grey1
                    font: entryInput.font
                }

                Keys.onReturnPressed: entryRowRoot.submit()
                Keys.onEnterPressed: entryRowRoot.submit()
            }
        }

        Rectangle {
            implicitWidth: entryBtnLbl.implicitWidth + 24
            implicitHeight: 26
            radius: 8
            color: entryBtnHover.hovered
                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
            border.width: 1
            border.color: Colors.accent

            Text {
                id: entryBtnLbl
                anchors.centerIn: parent
                text: entryRowRoot.buttonText
                color: Colors.accent
                font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
            }

            HoverHandler { id: entryBtnHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: entryRowRoot.submit()
            }
        }
    }

    Text {
        visible: entryRowRoot.description.length > 0
        text: entryRowRoot.description
        color: Colors.grey1
        font { family: "SF Pro Display"; pixelSize: 10 }
    }
}
