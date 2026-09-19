pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// SwitchRow — Material 3 switch (52x32). Колір: Md (Colors <- colors.json).
RowLayout {
    id: switchRowRoot
    required property string category
    required property string configKey
    required property string label
    property string description: ""
    property bool isSettingsControl: true
    visible: SettingsSearch.matches(label)

    Layout.fillWidth: true
    spacing: 10

    readonly property bool value: !!Config.get(category, configKey)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            Layout.fillWidth: true
            text: switchRowRoot.label
            color: Md.onSurface
            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
        }
        Text {
            Layout.fillWidth: true
            visible: switchRowRoot.description.length > 0
            text: switchRowRoot.description
            color: Md.onSurfaceVariant
            elide: Text.ElideRight
            font { family: "SF Pro Display"; pixelSize: 10 }
        }
    }

    Rectangle {
        id: swTrack
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 52
        Layout.preferredHeight: 32
        radius: 16
        color: switchRowRoot.value ? Md.primary : "transparent"
        border.width: switchRowRoot.value ? 0 : 2
        border.color: Md.outline
        Behavior on color { ColorAnimation { duration: Md.durMed } }

        Rectangle {
            id: knob
            width: switchRowRoot.value ? 24 : 16
            height: width
            radius: width / 2
            y: (parent.height - height) / 2
            x: switchRowRoot.value ? parent.width - width - 4 : 6
            color: switchRowRoot.value ? Md.onPrimary : Md.outline
            Behavior on x { NumberAnimation { duration: Md.durMed; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Md.durFast } }
            Behavior on color { ColorAnimation { duration: Md.durMed } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.set(switchRowRoot.category, switchRowRoot.configKey, !switchRowRoot.value)
        }
    }

    ResetDot {
        category: switchRowRoot.category
        configKey: switchRowRoot.configKey
    }
}
