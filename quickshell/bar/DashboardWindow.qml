pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// DashboardWindow.qml — Material You (m3.material.io + hyprland-material-you).
// Правий сайдбар: Internet/Bluetooth картки, M3 світчі, quick actions,
// Volume/Brightness слайдери, сповіщення. Все реальне (NetworkManager/rfkill/
// Pipewire/brightnessctl/swaync).
// ==========================================================================

// Один корінь: Item, що містить обидва вікна. PillShell викликає
// dashboardWindow.open()/toggle() — делегують сюди.
Item {
    id: dashRoot

    function open() { win.open() }
    function close() { win.close() }
    function toggle() { win.visible ? win.close() : win.open() }

PanelWindow {
        id: win
    
        visible: false
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: win.visible
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; right: true }

        width: 680
    
        property var sink: Pipewire.defaultAudioSink
        readonly property int vol: (sink && sink.ready) ? Math.round(sink.audio.volume * 100) : 0
        property int brightnessVal: 50
        property bool btOn: false
        property bool tasksOpen: false
    
        function open(): void { win.visible = true }
        function close(): void { win.visible = false }
        function toggle(): void { win.visible ? win.close() : win.open() }
    
        onVisibleChanged: {
            if (visible) {
                card.forceActiveFocus()
                btQuery.running = true
                brightnessQuery.running = true
            }
        }
    
        Process {
            id: btQuery
            command: ["sh", "-c", "rfkill list bluetooth 2>/dev/null | grep -q 'Soft blocked: yes' && echo blocked || echo unblocked"]
            stdout: StdioCollector { onStreamFinished: win.btOn = (text.trim() === "unblocked") }
        }
        Process {
            id: btSet
            command: []
            onExited: btQuery.running = true
        }
        Process {
            id: brightnessQuery
            command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const v = parseInt(text.trim())
                    if (!isNaN(v)) win.brightnessVal = v
                }
            }
        }
        Process { id: brightnessSet; command: [] }
        Process { id: actionProc; command: [] }
    
        function setBrightness(val) {
            const c = Math.max(5, Math.min(100, val))
            win.brightnessVal = c
            brightnessSet.command = ["brightnessctl", "s", c + "%"]
            brightnessSet.running = true
        }
        function toggleBt() {
            btSet.command = ["sh", "-c", win.btOn ? "rfkill block bluetooth" : "rfkill unblock bluetooth"]
            btSet.running = true
        }
    
        PwObjectTracker { objects: [win.sink] }
    
        // ---- M3 Expressive slider ----
        component XSlider: RowLayout {
            id: xs
            property string icon: ""
            property color accent: Md.primary
            property real fraction: 0
            property string valueLabel: ""
            signal setFraction(real pct)
    
            Layout.fillWidth: true
            spacing: 10
    
            Text {
                text: xs.icon
                color: xs.accent
                font { family: "Material Symbols Rounded"; pixelSize: 17 }
            }
            Rectangle {
                id: track
                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: 4
                color: Colors.bg2est
                Rectangle {
                    width: track.width * xs.fraction
                    height: parent.height
                    radius: parent.radius
                    color: xs.accent
                }
                Rectangle {
                    width: 18; height: 18; radius: 9
                    x: track.width * xs.fraction - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Colors.fg
                    border.width: 3
                    border.color: xs.accent
                    scale: trackMa.pressed ? 1.15 : 1.0
                    Behavior on scale { NumberAnimation { duration: Md.durFast } }
                }
                MouseArea {
                    id: trackMa
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onPressed: (m) => xs.setFraction(Math.max(0, Math.min(1, m.x / width)))
                    onPositionChanged: (m) => { if (pressed) xs.setFraction(Math.max(0, Math.min(1, m.x / width))) }
                }
            }
            Text {
                text: xs.valueLabel
                color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                font { family: "SF Mono"; pixelSize: 11 }
                Layout.preferredWidth: 36
            }
        }
    
        // ---- M3 switch row ----
        component M3Switch: RowLayout {
            id: sw
            required property string icon
            required property string title
            required property string subtitle
            property bool checked: false
            signal toggled()
            Layout.fillWidth: true
            spacing: 12
    
            Text { text: sw.icon; color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7); font { family: "Material Symbols Rounded"; pixelSize: 19 } }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: sw.title; color: Colors.fg; font { family: "SF Pro Display"; pixelSize: 13; weight: 500 } }
                Text { text: sw.subtitle; color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7); font { family: "SF Pro Display"; pixelSize: 11 } }
            }
            Rectangle {
                width: 52; height: 32; radius: 16
                color: sw.checked ? Md.primary : "transparent"
                border.width: sw.checked ? 0 : 2
                border.color: Md.outline
                Rectangle {
                    width: sw.checked ? 24 : 16; height: width; radius: width / 2
                    x: sw.checked ? parent.width - width - 4 : 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: sw.checked ? Md.onPrimary : Md.outline
                    Behavior on x { NumberAnimation { duration: Md.durMed; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: Md.durFast } }
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sw.toggled()
                }
            }
        }
    
        // ---- chevron card row ----
        component CardRow: Rectangle {
            id: cr
            required property string icon
            required property string title
            required property string subtitle
            signal clicked()
            Layout.fillWidth: true
            implicitHeight: 62
            radius: Md.rXL
            color: crMa.containsMouse ? Md.hoverOf(Colors.bg2) : Colors.bg2
            Behavior on color { ColorAnimation { duration: Md.durFast } }
    
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 14
                Text { text: cr.icon; color: Md.primary; font { family: "Material Symbols Rounded"; pixelSize: 21 } }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text { text: cr.title; color: Colors.fg; font { family: "SF Pro Display"; pixelSize: 13; weight: 600 } }
                    Text {
                        Layout.fillWidth: true
                        text: cr.subtitle
                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                        font { family: "SF Pro Display"; pixelSize: 11 }
                        elide: Text.ElideRight
                    }
                }
                Text { text: "\ue5e1"; color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7); font { family: "Material Symbols Rounded"; pixelSize: 18 } }
            }
            MouseArea {
                id: crMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cr.clicked()
            }
        }
    
        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: win.tasksOpen ? 300 : 0
            width: 380
            color: Md.surface
            focus: true
            Keys.onEscapePressed: win.close()

            Behavior on anchors.rightMargin { NumberAnimation { duration: Md.durMed; easing.type: Easing.OutCubic } }
    
            Flickable {
                anchors.fill: parent
                anchors.margins: 16
                contentWidth: width
                contentHeight: col.implicitHeight
                clip: true
    
                ColumnLayout {
                    id: col
                    width: parent.width
                    spacing: 10
    
                    // header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.bottomMargin: 4
                        Text {
                            Layout.fillWidth: true
                            text: "Quick Settings"
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 16; weight: 700 }
                        }
                        Text {
                            text: "\u00d7"
                            color: closeMa.containsMouse ? Md.error : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                            font { family: "SF Pro Display"; pixelSize: 18 }
                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                anchors.margins: -6
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.close()
                            }
                        }
                    }
    
                    // Internet / Bluetooth cards
                    CardRow {
                        icon: "\ue63e"
                        title: "Internet"
                        subtitle: Networking.wifiEnabled ? "Wi-Fi enabled" : "Wi-Fi disabled"
                        onClicked: { actionProc.command = ["nm-connection-editor"]; actionProc.running = true }
                    }
                    CardRow {
                        icon: "\ue1a7"
                        title: "Bluetooth"
                        subtitle: win.btOn ? "On" : "Off"
                        onClicked: { actionProc.command = ["blueman-manager"]; actionProc.running = true }
                    }
    
                    // quick actions (stadium outlined)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Repeater {
                            model: [
                                { icon: "\ue899", tip: "Lock", cmd: "sh -c 'pidof swaylock || swaylock --config ~/.config/swaylock/config --image ~/.config/swaylock/current-wallpaper'" },
                                { icon: "\uf053", tip: "Reboot", cmd: "systemctl reboot" },
                                { icon: "\ue8ac", tip: "Power off", cmd: "systemctl poweroff" }
                            ]
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 40
                                radius: Md.rFull
                                color: qaMa.pressed ? Md.pressedOf(Colors.fg)
                                    : (qaMa.containsMouse ? Md.hoverOf(Colors.fg) : "transparent")
                                border.width: 1
                                border.color: Md.outline
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.tip === "Power off" ? Md.error : Md.primary
                                    font { family: "Material Symbols Rounded"; pixelSize: 18 }
                                }
                                MouseArea {
                                    id: qaMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { actionProc.command = ["sh", "-c", modelData.cmd]; actionProc.running = true }
                                }
                            }
                        }
                    }
    
                    // switches
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: swCol.implicitHeight + 20
                        radius: Md.rXL
                        color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)
    
                        ColumnLayout {
                            id: swCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 10
                            }
                            spacing: 4
    
                            M3Switch {
                                icon: "\ue1a7"
                                title: "Bluetooth"
                                subtitle: win.btOn ? "On" : "Off"
                                checked: win.btOn
                                onToggled: win.toggleBt()
                            }
                            M3Switch {
                                icon: "\uf1c1"
                                title: "Do not disturb"
                                subtitle: "SwayNC notifications"
                                onToggled: { actionProc.command = ["swaync-client", "-d"]; actionProc.running = true }
                            }
                        }
                    }
    
                    // sliders
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: slCol.implicitHeight + 20
                        radius: Md.rXL
                        color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)
    
                        ColumnLayout {
                            id: slCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 14
                            }
                            spacing: 12
    
                            XSlider {
                                icon: "\ue050"
                                fraction: win.vol / 100
                                valueLabel: win.vol + "%"
                                onSetFraction: (pct) => { if (win.sink && win.sink.ready) win.sink.audio.volume = pct }
                            }
                            XSlider {
                                icon: "\ue3ab"
                                accent: Md.error
                                fraction: win.brightnessVal / 100
                                valueLabel: win.brightnessVal + "%"
                                onSetFraction: (pct) => win.setBrightness(Math.round(pct * 100))
                            }
                        }
                    }
    
                    // ---- tasks кнопка (відкриває панель праворуч) ----
                    CardRow {
                        icon: "\ue8b0"
                        title: "Tasks"
                        subtitle: "Daily tasks"
                        onClicked: win.tasksOpen = !win.tasksOpen
                    }
    
                    // ---- CALENDAR (без тасок; weekday-рядок окремо від сітки) ----
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: calCol.implicitHeight + 20
                        radius: Md.rXL
                        color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)
    
                        ColumnLayout {
                            id: calCol
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 14
                            }
                            spacing: 8
    
                            property var viewDate: new Date()
    
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: calCol.viewDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")
                                    color: Colors.fg
                                    font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
                                }
                                Text {
                                    text: "\u2039"
                                    color: pMv.hovered ? Md.primary : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                    font { family: "SF Pro Display"; pixelSize: 15 }
                                    HoverHandler { id: pMv }
                                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                        onClicked: calCol.shift(-1) }
                                }
                                Text {
                                    text: "\u203a"
                                    color: nMv.hovered ? Md.primary : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                    font { family: "SF Pro Display"; pixelSize: 15 }
                                    HoverHandler { id: nMv }
                                    MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                        onClicked: calCol.shift(1) }
                                }
                            }
    
                            function shift(delta) {
                                const d = calCol.viewDate
                                calCol.viewDate = new Date(d.getFullYear(), d.getMonth() + delta, 1)
                            }
                            function weekdayName(i) {
                                return new Date(2024, 0, 1 + i).toLocaleDateString(Qt.locale(), "ddd")
                            }
                            readonly property var cells: {
                                const d = calCol.viewDate
                                const y = d.getFullYear(), m = d.getMonth()
                                const off = (new Date(y, m, 1).getDay() + 6) % 7
                                const today = new Date().toDateString()
                                const out = []
                                for (let i = 0; i < 42; i++) {
                                    const day = new Date(y, m, 1 - off + i)
                                    out.push({ day: day.getDate(), inMonth: day.getMonth() === m,
                                               today: day.toDateString() === today })
                                }
                                return out
                            }
    
                            // weekday labels — ОКРЕМИЙ рядок (без перекриття)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Repeater {
                                    model: 7
                                    Text {
                                        required property int index
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: calCol.weekdayName(index)
                                        color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                        font { family: "SF Pro Display"; pixelSize: 10; weight: 600 }
                                    }
                                }
                            }
    
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 7
                                columnSpacing: 0
                                rowSpacing: 0
    
                                Repeater {
                                    model: calCol.cells
                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 28
                                        radius: Md.rS
                                        color: modelData.today ? Md.primaryContainer : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            color: modelData.today ? Md.onPrimaryContainer
                                                : (modelData.inMonth ? Colors.fg : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7))
                                            opacity: modelData.inMonth ? 1.0 : 0.45
                                            font { family: "SF Pro Display"; pixelSize: 11; weight: modelData.today ? 700 : 400 }
                                        }
                                    }
                                }
                            }
                        }
                    }
    
                    // notifications
                    CardRow {
                        icon: "\ue7f4"
                        title: "Notifications"
                        subtitle: "SwayNC panel"
                        onClicked: { actionProc.command = ["swaync-client", "-t"]; actionProc.running = true }
                    }
                }
            }
        }
    }
    
    // ==========================================================================
    // TasksPanel — окрема панель праворуч від Dashboard; відкривається/закривається
    // кнопкою Tasks. TasksStore (~/.config/quickshell/tasks.json).
    // ==========================================================================
    Item {
        id: tasksWin

        visible: win.tasksOpen
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 300
    
        property string selectedDate: {
            const t = new Date()
            return t.getFullYear() + "-" + String(t.getMonth() + 1).padStart(2, "0")
                + "-" + String(t.getDate()).padStart(2, "0")
        }
    
        Rectangle {
            anchors.fill: parent
            color: Md.surface
            border.width: 1
            border.color: Md.outlineVariant
    
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10
    
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: "TASKS \u2014 " + tasksWin.selectedDate
                        color: Colors.fg
                        font { family: "SF Pro Display"; pixelSize: 13; weight: 700 }
                    }
                    Text {
                        text: "\u00d7"
                        color: tcl.hovered ? Md.error : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                        font { family: "SF Pro Display"; pixelSize: 16 }
                        HoverHandler { id: tcl }
                        MouseArea { anchors.fill: parent; anchors.margins: -5; cursorShape: Qt.PointingHandCursor
                            onClicked: win.tasksOpen = false }
                    }
                }
    
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Rectangle {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 26
                        radius: Md.rS
                        color: Colors.bg2est
                        TextInput {
                            id: taskTime
                            anchors.fill: parent
                            horizontalAlignment: TextInput.AlignHCenter
                            verticalAlignment: TextInput.AlignVCenter
                            color: Md.primary
                            font { family: "SF Mono"; pixelSize: 11 }
                            Text { anchors.centerIn: parent; text: "18:00"; color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7); visible: taskTime.text.length === 0 }
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        radius: Md.rS
                        color: Colors.bg2est
                        TextInput {
                            id: taskTitle
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 11 }
                            clip: true
                            Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                                   text: "New task..."; color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7); visible: taskTitle.text.length === 0 }
                            Keys.onReturnPressed: addTaskBtn.addTask()
                        }
                    }
                    Rectangle {
                        id: addTaskBtn
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 26
                        radius: Md.rS
                        color: atM.containsMouse ? Md.mix(Md.primaryContainer, Colors.fg, 0.15) : Md.primaryContainer
                        Text { anchors.centerIn: parent; text: "Add"; color: Md.onPrimaryContainer
                               font { family: "SF Pro Display"; pixelSize: 11; weight: 600 } }
                        MouseArea { id: atM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: addTaskBtn.addTask() }
                        function addTask() {
                            const t = taskTitle.text.trim()
                            if (t.length === 0) return
                            TasksStore.add(tasksWin.selectedDate,
                                taskTime.text.trim().length > 0 ? taskTime.text.trim() : "18:00", t)
                            taskTitle.text = ""
                        }
                    }
                }
    
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: taskListCol.implicitHeight
    
                    ColumnLayout {
                        id: taskListCol
                        width: parent.width
                        spacing: 4
    
                        Repeater {
                            model: TasksStore.tasksFor(tasksWin.selectedDate)
                            Rectangle {
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                implicitHeight: 28
                                radius: Md.rS
                                color: Colors.bg2
    
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8
                                    Text { text: modelData.time; color: Md.primary; font { family: "SF Mono"; pixelSize: 10 } }
                                    Text { Layout.fillWidth: true; text: modelData.title
                                           color: modelData.done ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7) : Colors.fg; elide: Text.ElideRight
                                           font { family: "SF Pro Display"; pixelSize: 11 } }
                                    Text { text: "\u2713"; color: dM.containsMouse ? Md.primary : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                           font { family: "SF Pro Display"; pixelSize: 12 }
                                           MouseArea { id: dM; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true
                                               cursorShape: Qt.PointingHandCursor
                                               onClicked: TasksStore.toggleDone(tasksWin.selectedDate, index) } }
                                    Text { text: "\u00d7"; color: xM.containsMouse ? Md.error : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7)
                                           font { family: "SF Pro Display"; pixelSize: 12 }
                                           MouseArea { id: xM; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true
                                               cursorShape: Qt.PointingHandCursor
                                               onClicked: TasksStore.remove(tasksWin.selectedDate, index) } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}
