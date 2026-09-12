pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// DashboardWindow.qml — великий центр керування Edots (Phase 6).
// Референси: end-4 (sidebar w/ big sliders), Ricelin (calendar), README.
// Відкриття: qs ipc call dashboard toggle | бінд (рекомендація: Super+D).
// Картка напівпрозора (bg0@0.82) — blur позаду видно, якщо blur_layer=1.
// ==========================================================================

PanelWindow {
    id: win

    visible: false
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: win.visible
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors { top: true; bottom: true; left: true; right: true }

    // ---------------- data ----------------
    property var now: new Date()
    property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.ready
    readonly property int vol: sinkReady ? Math.round(sink.audio.volume * 100) : 0
    property int brightnessVal: 50
    property bool btOn: false

    Timer {
        interval: 1000
        repeat: true
        running: win.visible
        onTriggered: win.now = new Date()
    }

    PwObjectTracker { objects: [win.sink] }

    Process {
        id: brightnessQuery
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(text.trim())
                if (!isNaN(val)) win.brightnessVal = val
            }
        }
    }
    Process {
        id: brightnessSetProc
        command: []
        onExited: brightnessQuery.running = true
    }

    Process {
        id: btQuery
        command: ["sh", "-c", "rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes' && echo blocked || echo unblocked"]
        stdout: StdioCollector {
            onStreamFinished: win.btOn = (text.trim() === "unblocked")
        }
    }
    Process {
        id: btSetProc
        command: []
        onExited: btTimer.start()
    }
    Timer {
        id: btTimer
        interval: 400
        onTriggered: btQuery.running = true
    }

    function setBrightness(val) {
        let clamped = Math.max(5, Math.min(100, val))
        win.brightnessVal = clamped
        brightnessSetProc.command = ["brightnessctl", "s", clamped + "%"]
        brightnessSetProc.running = true
    }

    function toggleBt() {
        btSetProc.command = ["sh", "-c", win.btOn
            ? "rfkill block bluetooth"
            : "rfkill unblock bluetooth"]
        btSetProc.running = true
    }

    // ---------------- calendar state/logic ----------------
    property var viewDate: new Date()

    readonly property var calendarCells: {
        const d = win.viewDate
        const y = d.getFullYear(), m = d.getMonth()
        const first = new Date(y, m, 1)
        const startOffset = (first.getDay() + 6) % 7   // Monday-first
        const todayStr = new Date().toDateString()
        const out = []
        for (let i = 0; i < 42; i++) {
            const day = new Date(y, m, 1 - startOffset + i)
            out.push({
                day: day.getDate(),
                inMonth: day.getMonth() === m,
                isToday: day.toDateString() === todayStr
            })
        }
        return out
    }

    function shiftMonth(delta) {
        const d = win.viewDate
        // новий об'єкт Date -> binding гарантовано переобчислиться
        win.viewDate = new Date(d.getFullYear(), d.getMonth() + delta, 1)
    }

    function weekdayName(index) {
        // 1 січня 2024 — понеділок
        return new Date(2024, 0, 1 + index).toLocaleDateString(Qt.locale(), "ddd")
    }

    // ---------------- window ----------------
    function open(): void { win.visible = true }
    function close(): void { win.visible = false }
    function toggle(): void { win.visible ? win.close() : win.open() }

    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
            brightnessQuery.running = true
            btQuery.running = true
        }
    }

    // клік поза карткою закриває
    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(920, parent.width - 100)
        height: Math.min(600, parent.height - 100)
        radius: 26
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.82)
        border.width: 1
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)

        scale: win.visible ? 1.0 : 0.96
        opacity: win.visible ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: Anim.ms(260); easing.type: Easing.OutBack; easing.overshoot: 1.12 } }
        Behavior on opacity { NumberAnimation { duration: Anim.ms(160) } }

        focus: true
        Keys.onEscapePressed: win.close()

        // ---------------- components ----------------
        component DashSlider: RowLayout {
            id: dsRow
            property string icon: ""
            property color iconColor: Colors.accent
            property real fraction: 0
            property string valueLabel: ""
            signal setFraction(real pct)

            Layout.fillWidth: true
            spacing: 10

            Text {
                text: dsRow.icon
                color: dsRow.iconColor
                font { family: "Material Symbols Rounded"; pixelSize: 18 }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.15)

                Rectangle {
                    width: parent.width * dsRow.fraction
                    height: parent.height
                    radius: 4
                    color: dsRow.iconColor
                    Behavior on width { NumberAnimation { duration: Anim.ms(100) } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (m) => { m.accepted = true; jump(m.x) }
                    onClicked: (m) => jump(m.x)
                    onPositionChanged: (m) => { if (pressed) jump(m.x) }
                    function jump(mx) {
                        dsRow.setFraction(Math.max(0, Math.min(1, mx / width)))
                    }
                }
            }

            Text {
                text: dsRow.valueLabel
                color: Colors.grey2
                font { family: "SF Mono"; pixelSize: 12 }
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 42
                Layout.maximumWidth: 42
                elide: Text.ElideRight
            }
        }

        component DashToggle: Rectangle {
            id: dtRoot
            property string icon: ""
            property string title: ""
            property string subtitle: ""
            property bool checked: false
            signal toggled()

            Layout.fillWidth: true
            implicitHeight: 44
            radius: 12
            color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.6)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: dtRoot.icon
                    color: dtRoot.checked ? Colors.accent : Colors.grey1
                    font { family: "Material Symbols Rounded"; pixelSize: 18 }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: dtRoot.title
                        color: Colors.fg
                        font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
                    }
                    Text {
                        visible: dtRoot.subtitle.length > 0
                        text: dtRoot.subtitle
                        color: Colors.grey1
                        font { family: "SF Pro Display"; pixelSize: 10 }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 22
                    radius: 11
                    color: dtRoot.checked ? Colors.accent : Colors.bg4
                    Behavior on color { ColorAnimation { duration: Anim.ms(120) } }

                    Rectangle {
                        width: 16; height: 16; radius: 8; y: 3
                        x: dtRoot.checked ? parent.width - width - 3 : 3
                        color: Colors.bg0
                        Behavior on x { NumberAnimation { duration: Anim.ms(140); easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dtRoot.toggled()
                    }
                }
            }
        }

        // ---------------- content ----------------
        RowLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

            // ---- left column ----
            ColumnLayout {
                Layout.preferredWidth: 300
                Layout.maximumWidth: 300
                Layout.minimumWidth: 300
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                spacing: 14

                // header
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    spacing: 2
                    Text {
                        Layout.alignment: Qt.AlignLeft
                        horizontalAlignment: Text.AlignLeft
                        text: Qt.formatTime(win.now, "hh:mm")
                        color: Colors.fg
                        font { family: "SF Mono"; pixelSize: 40; weight: 600 }
                    }
                    Text {
                        Layout.alignment: Qt.AlignLeft
                        horizontalAlignment: Text.AlignLeft
                        text: Qt.formatDate(win.now, "dddd, d MMMM")
                        color: Colors.accent
                        font { family: "SF Pro Display"; pixelSize: 14; weight: 600 }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 170
                    clip: true
                    radius: 16
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Text {
                            text: "CONTROLS"
                            color: Colors.accent
                            font { family: "SF Pro Display"; pixelSize: 10; weight: 700 }
                        }

                        DashSlider {
                            icon: String.fromCodePoint(0xe050)
                            iconColor: Colors.accent
                            fraction: win.sinkReady ? win.vol / 100 : 0
                            valueLabel: win.sinkReady ? win.vol + "%" : "-"
                            onSetFraction: (pct) => { if (win.sinkReady) win.sink.audio.volume = pct }
                        }

                        DashSlider {
                            icon: String.fromCodePoint(0xe3ab)
                            iconColor: Colors.yellow
                            fraction: win.brightnessVal / 100
                            valueLabel: win.brightnessVal + "%"
                            onSetFraction: (pct) => win.setBrightness(Math.round(pct * 100))
                        }

                        Battery {}

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    radius: 16
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            Layout.alignment: Qt.AlignLeft
                            horizontalAlignment: Text.AlignLeft
                            text: "QUICK TOGGLES"
                            color: Colors.accent
                            font { family: "SF Pro Display"; pixelSize: 10; weight: 700 }
                        }

                        DashToggle {
                            icon: String.fromCodePoint(0xe63e)
                            title: "Wi-Fi"
                            subtitle: Networking.wifiEnabled ? "Enabled" : "Disabled"
                            checked: Networking.wifiEnabled
                            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
                        }

                        DashToggle {
                            icon: String.fromCodePoint(0xe1a7)
                            title: "Bluetooth"
                            subtitle: win.btOn ? "Enabled" : "Disabled"
                            checked: win.btOn
                            onToggled: win.toggleBt()
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ---- calendar ----
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                radius: 16
                color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: String.fromCodePoint(0xe5c4)   // arrow_back
                            color: calPrevHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "Material Symbols Rounded"; pixelSize: 16 }
                            HoverHandler { id: calPrevHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.shiftMonth(-1)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: win.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 14; weight: 600 }
                        }

                        Text {
                            text: String.fromCodePoint(0xe5c8)   // arrow_forward
                            color: calNextHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "Material Symbols Rounded"; pixelSize: 16 }
                            HoverHandler { id: calNextHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.shiftMonth(1)
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 0
                        rowSpacing: 0

                        Repeater {
                            model: 7
                            Text {
                                required property int index
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: win.weekdayName(index)
                                color: Colors.grey1
                                font { family: "SF Pro Display"; pixelSize: 10; weight: 600 }
                            }
                        }

                        Repeater {
                            model: win.calendarCells
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: modelData.isToday
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
                                    : "transparent"
                                radius: 8

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.isToday ? Colors.accent
                                        : (modelData.inMonth ? Colors.fg : Colors.grey1)
                                    opacity: modelData.inMonth ? 1.0 : 0.45
                                    font { family: "SF Pro Display"; pixelSize: 12; weight: modelData.isToday ? 700 : 400 }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

    }
}
