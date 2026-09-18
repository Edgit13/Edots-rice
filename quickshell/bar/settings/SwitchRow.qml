pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// SwitchRow — Settings control (M3 colors via bridge). Пошук: SettingsSearch.
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
            color: M3.onSurface
            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
        }
        Text {
            Layout.fillWidth: true
            visible: switchRowRoot.description.length > 0
            text: switchRowRoot.description
            color: M3.onSurfaceVariant
            elide: Text.ElideRight
            font { family: "SF Pro Display"; pixelSize: 10 }
        }
    }

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: 44
        Layout.preferredHeight: 22
        radius: 11
        color: switchRowRoot.value ? M3.primary : M3.surfaceContainerHighest
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            width: 16
            height: 16
            radius: 8
            y: 3
            x: switchRowRoot.value ? parent.width - width - 3 : 3
            color: switchRowRoot.value ? M3.onPrimary : M3.outline
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.set(switchRowRoot.category, switchRowRoot.configKey, !switchRowRoot.value)
        }
    }

    ResetDot {
        category: switchRowRoot.category
        configKey: switchRowRoot.configKey
    }
}
