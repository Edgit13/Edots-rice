pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// SettingsControls.qml — бібліотека контролів Settings UI (Phase 3).
//
// Inline-компоненти доступні ззовні як SettingsControls.<Ім'я>.
// Контроли з category/configKey читають/пишуть Config напряму
// (Config.get/set). ResetDot видимий, лише коли значення відрізняється
// від заводського (Config.isDirty), і скидає один ключ (Config.resetKey).
//
// Контроли з category/configKey починають використовуватися з Phase 4 —
// бібліотека тут, щоб усі наступні фази мали ОДНУ мову дизайну контролів.
// ==========================================================================

Item {
    id: ctl
    visible: false

    // ---------------------------------------------------------- SectionLabel

    component SectionLabel: Text {
        required property string label
        Layout.fillWidth: true
        Layout.topMargin: 6
        text: label.toUpperCase()
        color: Colors.accent
        font { family: "SF Pro Display"; pixelSize: 11; weight: 700 }
    }

    // ------------------------------------------------------------------ Card

    component Card: Rectangle {
        property string title: ""
        default property alias content: cardCol.children

        Layout.fillWidth: true
        radius: 12
        color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.72)
        border.width: 1
        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.14)
        implicitHeight: cardCol.implicitHeight + 24

        ColumnLayout {
            id: cardCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 10

            Text {
                visible: title.length > 0
                text: title
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
            }
        }
    }

    // -------------------------------------------------------------- ResetDot

    component ResetDot: Text {
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

    // ------------------------------------------------------------- SwitchRow

    component SwitchRow: RowLayout {
        required property string category
        required property string configKey
        required property string label
        property string description: ""

        Layout.fillWidth: true
        spacing: 10

        readonly property bool value: !!Config.get(category, configKey)

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: switchRowRoot.label
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
            }
            Text {
                Layout.fillWidth: true
                visible: switchRowRoot.description.length > 0
                text: switchRowRoot.description
                color: Colors.grey1
                elide: Text.ElideRight
                font { family: "SF Pro Display"; pixelSize: 10 }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 44
            Layout.preferredHeight: 22
            radius: 11
            color: switchRowRoot.value ? Colors.accent : Colors.bg4

            Behavior on color { ColorAnimation { duration: 120 } }

            Rectangle {
                width: 16
                height: 16
                radius: 8
                y: 3
                x: switchRowRoot.value ? parent.width - width - 3 : 3
                color: Colors.bg0

                Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.set(switchRowRoot.category, switchRowRoot.configKey, !switchRowRoot.value)
            }
        }

        SettingsControls.ResetDot {
            category: switchRowRoot.category
            configKey: switchRowRoot.configKey
        }
    }

    // ------------------------------------------------------------ SliderRow

    component SliderRow: ColumnLayout {
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

        Layout.fillWidth: true
        spacing: 6

        readonly property real value: {
            const v = Config.get(category, configKey)
            return typeof v === "number" ? v : sliderRowRoot.from
        }
        readonly property real fraction: (sliderRowRoot.value - sliderRowRoot.from)
            / Math.max(0.0001, sliderRowRoot.to - sliderRowRoot.from)

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
            SettingsControls.ResetDot {
                category: sliderRowRoot.category
                configKey: sliderRowRoot.configKey
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
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
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onPressed: (mouse) => setFromMouse(mouse.x)
                onPositionChanged: (mouse) => { if (pressed) setFromMouse(mouse.x) }

                function setFromMouse(mx) {
                    let f = Math.max(0, Math.min(1, mx / width))
                    let v = sliderRowRoot.from + f * (sliderRowRoot.to - sliderRowRoot.from)
                    v = Math.round(v / sliderRowRoot.stepSize) * sliderRowRoot.stepSize
                    v = Math.max(sliderRowRoot.from, Math.min(sliderRowRoot.to, v))
                    Config.set(sliderRowRoot.category, sliderRowRoot.configKey, v)
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

    // ----------------------------------------------------------- DropdownRow

    component DropdownRow: ColumnLayout {
        id: dropRowRoot
        required property string category
        required property string configKey
        required property string label
        property string description: ""
        property var options: []
        property bool expanded: false

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

            SettingsControls.ResetDot {
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

    // ------------------------------------------------------------ ButtonRow

    component ButtonRow: Rectangle {
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
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: btnRowRoot.clicked()
                }
            }
        }
    }

    // ------------------------------------------------------------- EntryRow

    component EntryRow: ColumnLayout {
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

    // -------------------------------------------------------------- InfoRow

    component InfoRow: Rectangle {
        id: infoRowRoot
        required property string title
        required property string detail

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
}
