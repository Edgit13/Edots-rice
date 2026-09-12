pragma ComponentBehavior: Bound

import "root:/"
import "root:/settings"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// ==========================================================================
// TaskManagerWindow.qml — порт test-implementions/shell.qml у бар
// (Phase 7): папковий Task Manager (бекенд edots/task-manager/core.py)
// + utimer (таймер із сповіщенням через swaync) + upkg (пакети, kitty).
// Відкриття: qs ipc call tasks toggle.
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

    readonly property string corePy: Quickshell.env("HOME") + "/edots/task-manager/core.py"

    property var taskData: ({})
    property var folders: ["Default"]
    property string currentFolder: "Default"
    property bool showingNewFolderInput: false
    property string timerStatus: ""

    Process { id: actionRunner; onExited: taskLoader.running = true }

    function runAction(args) {
        actionRunner.command = args
        actionRunner.running = true
    }

    function reloadTasks() {
        taskLoader.running = false
        Qt.callLater(() => { taskLoader.running = true })
    }

    Process {
        id: taskLoader
        command: ["python3", "-u", win.corePy, "-c", "export-json"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data)
                    win.taskData = parsed
                    var keys = Object.keys(parsed)
                    if (keys.length > 0) {
                        win.folders = keys
                        if (keys.indexOf(win.currentFolder) === -1)
                            win.currentFolder = keys[0]
                    }
                } catch (e) {}
            }
        }
    }

    Process { id: toolProc }

    function runPkg(cmd, pkg) {
        if ((cmd === "install" || cmd === "remove" || cmd === "search") && pkg.length === 0)
            return
        const args = ["upkg", cmd]
        if (pkg.length > 0) args.push(pkg)
        toolProc.command = ["kitty", "--hold", "-e", ...args]
        toolProc.running = true
    }

    function open(): void { win.visible = true }
    function close(): void { win.visible = false }
    function toggle(): void { win.visible ? win.close() : win.open() }

    onVisibleChanged: {
        if (visible) {
            card.forceActiveFocus()
            reloadTasks()
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.close()
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(760, parent.width - 100)
        height: Math.min(600, parent.height - 100)
        radius: 24
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.97)
        border.width: 1
        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)

        scale: win.visible ? 1.0 : 0.96
        opacity: win.visible ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: Anim.ms(240); easing.type: Easing.OutBack; easing.overshoot: 1.12 } }
        Behavior on opacity { NumberAnimation { duration: Anim.ms(150) } }

        focus: true
        Keys.onEscapePressed: win.close()

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16

            // ---------------- task manager ----------------
            ColumnLayout {
                Layout.preferredWidth: 380
                Layout.maximumWidth: 380
                Layout.minimumWidth: 380
                Layout.fillHeight: true
                spacing: 10

                Text {
                    text: "TASKS"
                    color: Colors.accent
                    font { family: "SF Pro Display"; pixelSize: 10; weight: 700 }
                }

                // folder tabs
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Flickable {
                        Layout.fillWidth: true
                        implicitHeight: 30
                        contentWidth: folderRow.implicitWidth
                        clip: true

                        RowLayout {
                            id: folderRow
                            spacing: 6

                            Repeater {
                                model: win.folders
                                Rectangle {
                                    required property var modelData
                                    implicitWidth: folderTabContent.implicitWidth + 16
                                    implicitHeight: 28
                                    radius: 6
                                    color: modelData === win.currentFolder ? Colors.bg3 : Colors.bg1
                                    border.color: modelData === win.currentFolder ? Colors.accent : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        id: folderTabContent
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: modelData
                                            color: modelData === win.currentFolder ? Colors.accent : Colors.fg
                                            font { family: "SF Pro Display"; pixelSize: 12; bold: modelData === win.currentFolder }
                                        }
                                        Text {
                                            visible: modelData === win.currentFolder && win.folders.length > 1
                                            text: "✕"
                                            color: Colors.red
                                            font { family: "SF Pro Display"; pixelSize: 10 }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.runAction(
                                                    ["python3", "-u", win.corePy, "-c", "remove-folder", "-f", modelData])
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.currentFolder = modelData
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 6
                        color: Colors.bg2
                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: Colors.accent
                            font { family: "SF Pro Display"; pixelSize: 16 }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.showingNewFolderInput = !win.showingNewFolderInput
                        }
                    }
                }

                // new folder input
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 30
                    visible: win.showingNewFolderInput
                    color: Colors.bg1
                    radius: 6
                    border.color: Colors.bg3

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4

                        TextInput {
                            id: folderInput
                            Layout.fillWidth: true
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 12 }
                            clip: true
                            Text {
                                text: "New folder name..."
                                color: Colors.grey1
                                font.pixelSize: 12
                                visible: !parent.text
                            }
                        }

                        Rectangle {
                            implicitWidth: 50
                            implicitHeight: 24
                            radius: 4
                            color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Save"
                                color: Colors.bg0
                                font { family: "SF Pro Display"; pixelSize: 11; bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (folderInput.text.trim() !== "") {
                                        win.runAction(["python3", "-u", win.corePy, "-c",
                                            "create-folder", "-f", folderInput.text.trim()])
                                        folderInput.text = ""
                                        win.showingNewFolderInput = false
                                    }
                                }
                            }
                        }
                    }
                }

                // task input
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    color: Colors.bg1
                    radius: 6
                    border.color: Colors.bg3

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6

                        TextInput {
                            id: taskTitleInput
                            Layout.fillWidth: true
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 12 }
                            clip: true
                            Text {
                                text: "Add task title..."
                                color: Colors.grey1
                                font.pixelSize: 12
                                visible: !parent.text
                            }
                            Keys.onReturnPressed: addTaskBtn.addTask()
                        }

                        Rectangle {
                            implicitWidth: 56
                            implicitHeight: 24
                            color: Colors.bg2
                            radius: 4
                            TextInput {
                                id: taskDueInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                                color: Colors.accent
                                font { family: "SF Pro Display"; pixelSize: 11 }
                                Text {
                                    text: "18:00"
                                    color: Colors.grey1
                                    font.pixelSize: 11
                                    anchors.centerIn: parent
                                    visible: !parent.text
                                }
                            }
                        }

                        Rectangle {
                            id: addTaskBtn
                            implicitWidth: 38
                            implicitHeight: 24
                            radius: 4
                            color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Add"
                                color: Colors.bg0
                                font { family: "SF Pro Display"; pixelSize: 11; bold: true }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: addTaskBtn.addTask()
                            }
                            function addTask() {
                                if (taskTitleInput.text.trim() !== "") {
                                    win.runAction(["python3", "-u", win.corePy, "-c", "create",
                                        "-f", win.currentFolder,
                                        "-t", taskTitleInput.text.trim(),
                                        "-d", taskDueInput.text.trim()])
                                    taskTitleInput.text = ""
                                    taskDueInput.text = ""
                                }
                            }
                        }
                    }
                }

                // tasks list
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6

                    model: (win.taskData && win.taskData[win.currentFolder])
                        ? win.taskData[win.currentFolder] : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        implicitHeight: 36
                        radius: 6
                        color: Colors.bg1
                        border.color: Colors.bg2

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: Colors.fg
                                font { family: "SF Pro Display"; pixelSize: 12 }
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: modelData.due !== ""
                                implicitWidth: dueText.implicitWidth + 10
                                implicitHeight: 18
                                radius: 4
                                color: Colors.bg3
                                Text {
                                    id: dueText
                                    anchors.centerIn: parent
                                    text: modelData.due
                                    color: Colors.accent
                                    font { family: "SF Pro Display"; pixelSize: 10 }
                                }
                            }

                            Text {
                                text: "✕"
                                color: Colors.red
                                font { family: "SF Pro Display"; pixelSize: 12 }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.runAction(["python3", "-u", win.corePy,
                                        "-c", "remove", "-f", win.currentFolder, "-i", index.toString()])
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- tools: utimer + upkg ----------------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "TIMER"
                            color: Colors.accent
                            font { family: "SF Pro Display"; pixelSize: 10; weight: 700 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                implicitWidth: 64
                                implicitHeight: 26
                                radius: 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: timerDuration
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    horizontalAlignment: TextInput.AlignHCenter
                                    color: Colors.accent
                                    font { family: "SF Mono"; pixelSize: 12 }
                                    Text {
                                        text: "10m"
                                        color: Colors.grey1
                                        anchors.centerIn: parent
                                        visible: !parent.text
                                    }
                                    Keys.onReturnPressed: timerStartBtn.start()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: timerMessage
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.fg
                                    font { family: "SF Pro Display"; pixelSize: 11 }
                                    clip: true
                                    Text {
                                        text: "Message (optional)..."
                                        color: Colors.grey1
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !parent.text
                                    }
                                    Keys.onReturnPressed: timerStartBtn.start()
                                }
                            }
                        }

                        Rectangle {
                            id: timerStartBtn
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 8
                            color: timerHover.hovered
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
                                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                            border.width: 1
                            border.color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Start timer"
                                color: Colors.accent
                                font { family: "SF Pro Display"; pixelSize: 12; bold: true }
                            }
                            HoverHandler { id: timerHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: timerStartBtn.start()
                            }
                            function start() {
                                const dur = timerDuration.text.trim()
                                if (dur.length === 0) return
                                const args = ["utimer", "start", dur]
                                const msg = timerMessage.text.trim()
                                if (msg.length > 0) args.push(msg)
                                toolProc.command = args
                                toolProc.running = true
                                win.timerStatus = "Timer set: " + dur + (msg ? " — " + msg : "")
                            }
                        }

                        Text {
                            visible: win.timerStatus.length > 0
                            text: win.timerStatus
                            color: Colors.grey1
                            wrapMode: Text.Wrap
                            font { family: "SF Pro Display"; pixelSize: 10 }
                        }

                        Text {
                            text: "Runs in background; SwayNC notifies you when it\u2019s up."
                            color: Colors.grey1
                            wrapMode: Text.Wrap
                            font { family: "SF Pro Display"; pixelSize: 10 }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "PACKAGES"
                            color: Colors.accent
                            font { family: "SF Pro Display"; pixelSize: 10; weight: 700 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: pkgName
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.fg
                                    font { family: "SF Pro Display"; pixelSize: 11 }
                                    clip: true
                                    Text {
                                        text: "package name..."
                                        color: Colors.grey1
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !parent.text
                                    }
                                }
                            }

                            Rectangle {
                                implicitWidth: 64
                                implicitHeight: 26
                                radius: 6
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                                border.width: 1
                                border.color: Colors.accent
                                Text {
                                    anchors.centerIn: parent
                                    text: "Search"
                                    color: Colors.accent
                                    font { family: "SF Pro Display"; pixelSize: 11; bold: true }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.runPkg("search", pkgName.text.trim())
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [["Install", "install"], ["Remove", "remove"]]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    radius: 6
                                    color: pkgBtnHover.hovered
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
                                        : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
                                    border.width: 1
                                    border.color: Colors.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData[0]
                                        color: Colors.accent
                                        font { family: "SF Pro Display"; pixelSize: 11; bold: true }
                                    }
                                    HoverHandler { id: pkgBtnHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.runPkg(modelData[1], pkgName.text.trim())
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: ["Update all", "Clean"]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    radius: 6
                                    color: sysBtnHover.hovered ? Colors.bg3 : Colors.bg1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: Colors.fg
                                        font { family: "SF Pro Display"; pixelSize: 11 }
                                    }
                                    HoverHandler { id: sysBtnHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.runPkg(modelData === "Update all" ? "update" : "clean", "")
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Opens a terminal (kitty --hold). yay/flatpak handle the rest."
                            color: Colors.grey1
                            wrapMode: Text.Wrap
                            font { family: "SF Pro Display"; pixelSize: 10 }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

    }
}
