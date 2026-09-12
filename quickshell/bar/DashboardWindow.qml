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

    // вибрана дата календаря (YYYY-MM-DD); за замовчуванням — сьогодні
    property string selectedDateStr: {
        const t = new Date()
        return t.getFullYear() + "-" + String(t.getMonth() + 1).padStart(2, "0")
            + "-" + String(t.getDate()).padStart(2, "0")
    }

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
        id: notifProc
        command: ["swaync-client", "-t"]
        running: false
    }
    Process {
        id: dndProc
        command: ["swaync-client", "-d"]
        running: false
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
            const ds = day.getFullYear() + "-" + String(day.getMonth() + 1).padStart(2, "0")
                + "-" + String(day.getDate()).padStart(2, "0")
            out.push({
                day: day.getDate(),
                inMonth: day.getMonth() === m,
                isToday: day.toDateString() === todayStr,
                dateStr: ds,
                isSelected: ds === win.selectedDateStr
            })
        }
        return out
    }

    function shiftMonth(delta) {
        const d = win.viewDate
        // новий об'єкт Date -> binding гарантовано переобчислиться
        win.viewDate = new Date(d.getFullYear(), d.getMonth() + delta, 1)
    }

    function addTaskForSelected() {
        const title = taskTitleInput.text.trim()
        if (title.length === 0)
            return
        const time = taskTimeInput.text.trim().length > 0 ? taskTimeInput.text.trim() : "18:00"
        TasksStore.add(win.selectedDateStr, time, title)
        taskTitleInput.text = ""
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

        component DashAction: Rectangle {
            id: daRoot
            property string icon: ""
            property string title: ""
            property string actionText: "Open"
            signal action()

            Layout.fillWidth: true
            implicitHeight: 40
            radius: 12
            color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.6)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: daRoot.icon
                    color: Colors.grey1
                    font { family: "Material Symbols Rounded"; pixelSize: 18 }
                }
                Text {
                    Layout.fillWidth: true
                    text: daRoot.title
                    color: Colors.fg
                    font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
                }
                Rectangle {
                    implicitWidth: daBtnText.implicitWidth + 18
                    implicitHeight: 22
                    radius: 7
                    color: daHover.hovered
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.28)
                        : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
                    border.width: 1
                    border.color: Colors.accent
                    Text {
                        id: daBtnText
                        anchors.centerIn: parent
                        text: daRoot.actionText
                        color: Colors.accent
                        font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
                    }
                    HoverHandler { id: daHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: daRoot.action()
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

                        DashAction {
                            icon: String.fromCodePoint(0xe7f4)
                            title: "Notification panel (swaync)"
                            actionText: "Open"
                            onAction: { notifProc.running = true }
                        }

                        DashAction {
                            icon: String.fromCodePoint(0xf1c1)
                            title: "Do not disturb"
                            actionText: "Toggle"
                            onAction: { dndProc.running = true }
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

                        // ---- tasks for selected day ----
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: 6
                            Layout.preferredHeight: 1
                            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.1)
                        }

                        Text {
                            text: "TASKS — " + win.selectedDateStr
                            color: Colors.accent
                            font { family: "SF Pro Display"; pixelSize: 10; weight: 700 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                implicitWidth: 52
                                implicitHeight: 24
                                radius: 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: taskTimeInput
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    horizontalAlignment: TextInput.AlignHCenter
                                    color: Colors.accent
                                    font { family: "SF Mono"; pixelSize: 11 }
                                    Text {
                                        text: "18:00"
                                        color: Colors.grey1
                                        anchors.centerIn: parent
                                        visible: !parent.text
                                    }
                                    Keys.onReturnPressed: win.addTaskForSelected()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 24
                                radius: 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: taskTitleInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.fg
                                    font { family: "SF Pro Display"; pixelSize: 11 }
                                    clip: true
                                    Text {
                                        text: "Task for this day..."
                                        color: Colors.grey1
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !parent.text
                                    }
                                    Keys.onReturnPressed: win.addTaskForSelected()
                                }
                            }

                            Rectangle {
                                implicitWidth: 40
                                implicitHeight: 24
                                radius: 6
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                                border.width: 1
                                border.color: Colors.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: "Add"
                                    color: Colors.accent
                                    font { family: "SF Pro Display"; pixelSize: 11; weight: 600 }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.addTaskForSelected()
                                }
                            }
                        }

                        Repeater {
                            model: TasksStore.tasksFor(win.selectedDateStr)
                            Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: 6
                                color: Colors.bg1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Rectangle {
                                        implicitWidth: 40
                                        implicitHeight: 18
                                        radius: 4
                                        color: Colors.bg3
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.time || "--:--"
                                            color: Colors.accent
                                            font { family: "SF Mono"; pixelSize: 10 }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: modelData.done ? Colors.grey1 : Colors.fg
                                        elide: Text.ElideRight
                                        font { family: "SF Pro Display"; pixelSize: 11 }
                                    }

                                    Text {
                                        text: "\u2713"
                                        color: doneHover.hovered ? Colors.accent : Colors.grey1
                                        font { family: "SF Pro Display"; pixelSize: 12 }
                                        HoverHandler { id: doneHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TasksStore.toggleDone(win.selectedDateStr, index)
                                        }
                                    }

                                    Text {
                                        text: "\u00d7"
                                        color: delHover.hovered ? Colors.red : Colors.grey1
                                        font { family: "SF Pro Display"; pixelSize: 12 }
                                        HoverHandler { id: delHover }
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: TasksStore.remove(win.selectedDateStr, index)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: TasksStore.tasksFor(win.selectedDateStr).length === 0
                            text: "No tasks for this day."
                            color: Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 10 }
                        }

                        Repeater {
                            model: win.calendarCells
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: modelData.isToday
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
                                    : (modelData.isSelected
                                        ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
                                        : "transparent")
                                radius: 8
                                border.width: modelData.isSelected && !modelData.isToday ? 1 : 0
                                border.color: Colors.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    color: modelData.isToday ? Colors.accent
                                        : (modelData.inMonth ? Colors.fg : Colors.grey1)
                                    opacity: modelData.inMonth ? 1.0 : 0.45
                                    font { family: "SF Pro Display"; pixelSize: 12; weight: modelData.isToday ? 700 : 400 }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.inMonth)
                                            win.selectedDateStr = modelData.dateStr
                                    }
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
