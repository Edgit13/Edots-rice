pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Control extracted from the former SettingsControls.qml monolith (Phase 4 fix).
// Hardened: явне mouse.accepted (Flickable не краде grab), onClicked fallback,
// WheelHandler для точного підгортання коліщатком.

ColumnLayout {
    id: sliderRowRoot
    required property string category
    required property string configKey
    required property string label
    property string description: ""
    required property real from
    required property real to
    property real stepSize: 1
    property int decimals: 0
    property string suffix: ""
    property bool isSettingsControl: true
    visible: SettingsSearch.matches(label)

    Layout.fillWidth: true
    spacing: 6

    readonly property real value: {
        const v = Config.get(category, configKey)
        return typeof v === "number" ? v : sliderRowRoot.from
    }
    readonly property real fraction: (sliderRowRoot.value - sliderRowRoot.from)
        / Math.max(0.0001, sliderRowRoot.to - sliderRowRoot.from)

    function applyValue(v) {
        v = Math.max(sliderRowRoot.from, Math.min(sliderRowRoot.to, v))
        Config.set(sliderRowRoot.category, sliderRowRoot.configKey, v)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: sliderRowRoot.label
            color: Colors.fg
            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
        }
        Text {
            text: sliderRowRoot.value.toFixed(sliderRowRoot.decimals) + sliderRowRoot.suffix
            color: Colors.grey2
            font { family: "SF Mono"; pixelSize: 11 }
        }
        ResetDot {
            category: sliderRowRoot.category
            configKey: sliderRowRoot.configKey
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 6
        Layout.topMargin: 2
        Layout.bottomMargin: 2
        radius: 3
        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.2)

        Rectangle {
            width: parent.width * sliderRowRoot.fraction
            height: parent.height
            radius: 3
            color: Colors.accent
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            y: -4
            x: parent.width * sliderRowRoot.fraction - width / 2
            color: Colors.fg
            border.width: 2
            border.color: Colors.accent

            Behavior on x { NumberAnimation { duration: Anim.ms(90); easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: sliderMouse
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor

            onPressed: (mouse) => {
                mouse.accepted = true
                setFromMouse(mouse.x)
            }
            onClicked: (mouse) => setFromMouse(mouse.x)
            onPositionChanged: (mouse) => {
                if (sliderMouse.pressed)
                    setFromMouse(mouse.x)
            }

            function setFromMouse(mx) {
                let f = Math.max(0, Math.min(1, mx / sliderMouse.width))
                let v = sliderRowRoot.from + f * (sliderRowRoot.to - sliderRowRoot.from)
                v = Math.round(v / sliderRowRoot.stepSize) * sliderRowRoot.stepSize
                sliderRowRoot.applyValue(v)
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: (event) => {
                const dir = event.angleDelta.y > 0 ? 1 : -1
                const mult = (event.modifiers & Qt.ShiftModifier) ? 10 : 1
                sliderRowRoot.applyValue(
                    sliderRowRoot.value + dir * sliderRowRoot.stepSize * mult)
                event.accepted = true
            }
        }
    }

    Text {
        visible: sliderRowRoot.description.length > 0
        text: sliderRowRoot.description
        color: Colors.grey1
        font { family: "SF Pro Display"; pixelSize: 10 }
    }
}
