pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Inline-компоненти у JS-контексті давали silent undefined у цьому білді.

ColumnLayout {
    id: dropRowRoot
    required property string category
    required property string configKey
    required property string label
    property string description: ""
    property var options: []
    property bool expanded: false
    property bool isSettingsControl: true
    visible: SettingsSearch.matches(label)

    Layout.fillWidth: true
    spacing: 6

    readonly property var value: Config.get(category, configKey)

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: dropRowRoot.label
            color: Colors.fg
            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
        }

        Rectangle {
            Layout.preferredWidth: 140
            Layout.preferredHeight: 26
            radius: 8
            color: Colors.bg2
            border.width: 1
            border.color: dropHover.hovered ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    text: String(dropRowRoot.value)
                    color: Colors.fg
                    elide: Text.ElideRight
                    font { family: "SF Pro Display"; pixelSize: 11 }
                }
                Text {
                    text: dropRowRoot.expanded ? "▴" : "▾"
                    color: Colors.grey2
                    font { family: "SF Pro Display"; pixelSize: 10 }
                }
            }

            HoverHandler { id: dropHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: dropRowRoot.expanded = !dropRowRoot.expanded
            }
        }

        ResetDot {
            category: dropRowRoot.category
            configKey: dropRowRoot.configKey
        }
    }

    Repeater {
        model: dropRowRoot.expanded ? dropRowRoot.options : []
        Rectangle {
            required property var modelData
            Layout.fillWidth: true
            Layout.leftMargin: 12
            implicitHeight: 26
            radius: 6
            color: optHover.hovered ? Colors.bg3 : Colors.bg2
            border.width: modelData === dropRowRoot.value ? 1 : 0
            border.color: Colors.accent

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: String(modelData)
                color: modelData === dropRowRoot.value ? Colors.accent : Colors.fg
                font { family: "SF Pro Display"; pixelSize: 11 }
            }

            HoverHandler { id: optHover }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Config.set(dropRowRoot.category, dropRowRoot.configKey, modelData)
                    dropRowRoot.expanded = false
                }
            }
        }
    }

    Text {
        visible: dropRowRoot.description.length > 0
        text: dropRowRoot.description
        color: Colors.grey1
        font { family: "SF Pro Display"; pixelSize: 10 }
    }
}
