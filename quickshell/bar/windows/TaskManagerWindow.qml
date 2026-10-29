pragma ComponentBehavior: Bound

import "root:/theme"
import "root:/config"
import "root:/settings"
import "root:/services"
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

    // ---- пакети: `upkg -q …` у фоні, вивід — у лог всередині вікна ----
    property bool pkgBusy: false
    property bool pkgNeedsSudo: false
    property string pkgLog: ""
    property string pkgStatus: ""
    property var pkgLast: ({ cmd: "", pkgs: [] })

    function pkgNames() { return pkgName.text.trim().split(/[\s,]+/).filter(x => x.length > 0) }

    function runPkg(cmd, pkgs) {
        if (pkgBusy) return
        if ((cmd === "install" || cmd === "remove" || cmd === "search") && pkgs.length === 0) return
        pkgLast = { cmd: cmd, pkgs: pkgs }
        pkgLog = ""
        pkgNeedsSudo = false
        pkgStatus = "upkg -q " + cmd + (pkgs.length ? " " + pkgs.join(" ") : "") + " …"
        pkgBusy = true
        pkgProc.command = ["upkg", "-q", cmd].concat(pkgs)
        pkgProc.running = true
    }
    // інтерактивний запуск у терміналі (пароль sudo, вибір джерела тощо)
    function runPkgTerminal() {
        const l = pkgLast
        const cmd = l.cmd.length > 0 ? l.cmd : "update"
        toolProc.command = ["kitty", "--hold", "-e", "upkg", cmd].concat(l.pkgs)
        toolProc.running = true
    }
    function _pkgAppend(line) {
        const lines = (pkgLog.length > 0 ? pkgLog + "\n" : "") + line
        const arr = lines.split("\n")
        pkgLog = arr.length > 300 ? arr.slice(arr.length - 300).join("\n") : lines
    }

    Process {
        id: pkgProc
        stdout: SplitParser { onRead: line => win._pkgAppend(line) }
        stderr: SplitParser { onRead: line => win._pkgAppend(line) }
        onExited: (code, status) => {
            win.pkgBusy = false
            win.pkgNeedsSudo = (code === 3)
            win.pkgStatus = code === 0 ? "Done \u2713"
                          : code === 3 ? "Needs a sudo password \u2014 use \u201cOpen in terminal\u201d"
                          : "Finished with errors (exit " + code + ")"
        }
    }

    // ---- таймер: utimer start <тривалість | дата час> [повідомлення] ----
    Process {
        id: timerProc
        property int lastCode: 0
        stderr: StdioCollector {
            id: timerErr
            onStreamFinished: {
                const m = text.trim().replace(/^Error:\s*/, "")
                if (m.length > 0) win.timerStatus = m
            }
        }
        onExited: (code, status) => {
            lastCode = code
            if (code === 0) win.timerStatus = win._timerLabel
            else if (timerErr.text.trim().length === 0) win.timerStatus = "utimer failed"
            TimerService.reload()
        }
    }
    property string _timerLabel: ""

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
        radius: Colors.nothing ? 28 : 24
        color: Qt.rgba(Colors.bg0.r, Colors.bg0.g, Colors.bg0.b, 0.97)
        border.width: 1
        border.color: Colors.nothing ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.18)
                                    : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.4)

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
                    font { family: Colors.nothing ? Colors.monoFont : Colors.uiFont; pixelSize: 10; weight: Colors.nothing ? 400 : 700; letterSpacing: Colors.nothing ? 2.5 : 0 }
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
                                    radius: Colors.nothing ? 10 : 6
                                    color: Colors.nothing ? "transparent" : (modelData === win.currentFolder ? Colors.bg3 : Colors.bg1)
                                    border.color: modelData === win.currentFolder ? (Colors.nothing ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.7) : Colors.accent)
                                                  : (Colors.nothing ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.18) : "transparent")
                                    border.width: 1

                                    RowLayout {
                                        id: folderTabContent
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: modelData
                                            color: modelData === win.currentFolder ? Colors.accent : Colors.fg
                                            font { family: Colors.uiFont; pixelSize: 12; bold: modelData === win.currentFolder }
                                        }
                                        Text {
                                            visible: modelData === win.currentFolder && win.folders.length > 1
                                            text: "✕"
                                            color: Colors.red
                                            font { family: Colors.uiFont; pixelSize: 10 }
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
                        radius: Colors.nothing ? 10 : 6
                        color: Colors.bg2
                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: Colors.accent
                            font { family: Colors.uiFont; pixelSize: 16 }
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
                    radius: Colors.nothing ? 10 : 6
                    border.color: Colors.bg3

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4

                        TextInput {
                            id: folderInput
                            Layout.fillWidth: true
                            color: Colors.fg
                            font { family: Colors.uiFont; pixelSize: 12 }
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
                            radius: Colors.nothing ? 6 : 4
                            color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Save"
                                color: Colors.bg0
                                font { family: Colors.uiFont; pixelSize: 11; bold: true }
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
                    radius: Colors.nothing ? 10 : 6
                    border.color: Colors.bg3

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6

                        TextInput {
                            id: taskTitleInput
                            Layout.fillWidth: true
                            color: Colors.fg
                            font { family: Colors.uiFont; pixelSize: 12 }
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
                            radius: Colors.nothing ? 6 : 4
                            TextInput {
                                id: taskDueInput
                                anchors.fill: parent
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                                color: Colors.accent
                                font { family: Colors.uiFont; pixelSize: 11 }
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
                            radius: Colors.nothing ? 6 : 4
                            color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Add"
                                color: Colors.bg0
                                font { family: Colors.uiFont; pixelSize: 11; bold: true }
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
                        radius: Colors.nothing ? 10 : 6
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
                                font { family: Colors.uiFont; pixelSize: 12 }
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: modelData.due !== ""
                                implicitWidth: dueText.implicitWidth + 10
                                implicitHeight: 18
                                radius: Colors.nothing ? 6 : 4
                                color: Colors.bg3
                                Text {
                                    id: dueText
                                    anchors.centerIn: parent
                                    text: modelData.due
                                    color: Colors.accent
                                    font { family: Colors.uiFont; pixelSize: 10 }
                                }
                            }

                            Text {
                                text: "✕"
                                color: Colors.red
                                font { family: Colors.uiFont; pixelSize: 12 }
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
                    radius: Colors.nothing ? 20 : 16
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "TIMER"
                            color: Colors.accent
                            font { family: Colors.nothing ? Colors.monoFont : Colors.uiFont; pixelSize: 10; weight: Colors.nothing ? 400 : 700; letterSpacing: Colors.nothing ? 2.5 : 0 }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                implicitWidth: 176
                                implicitHeight: 26
                                radius: Colors.nothing ? 10 : 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: timerDuration
                                    anchors.fill: parent
                                    verticalAlignment: TextInput.AlignVCenter
                                    horizontalAlignment: TextInput.AlignHCenter
                                    color: Colors.accent
                                    font { family: Colors.monoFont; pixelSize: 12 }
                                    Text {
                                        text: "10m  |  10.26.2026 13:00"
                                        color: Colors.grey1
                                        anchors.centerIn: parent
                                        visible: !parent.text
                                        font { family: Colors.monoFont; pixelSize: 10 }
                                    }
                                    Keys.onReturnPressed: timerStartBtn.start()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 26
                                radius: Colors.nothing ? 10 : 6
                                color: Colors.bg1
                                border.color: Colors.bg3
                                TextInput {
                                    id: timerMessage
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.fg
                                    font { family: Colors.uiFont; pixelSize: 11 }
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
                            radius: Colors.nothing ? 12 : 8
                            color: timerHover.hovered
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
                                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                            border.width: 1
                            border.color: Colors.accent
                            Text {
                                anchors.centerIn: parent
                                text: "Start timer"
                                color: Colors.accent
                                font { family: Colors.uiFont; pixelSize: 12; bold: true }
                            }
                            HoverHandler { id: timerHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: timerStartBtn.start()
                            }
                            function start() {
                                const when = timerDuration.text.trim()
                                if (when.length === 0) return
                                // "10m" або "10.26.2026 13:00" (дата + час через пробіл) — utimer розбере обидва
                                const args = ["utimer", "start"].concat(when.split(/\s+/))
                                const msg = timerMessage.text.trim()
                                if (msg.length > 0) args.push(msg)
                                win._timerLabel = "Timer set: " + when + (msg ? " \u2014 " + msg : "")
                                win.timerStatus = "\u2026"
                                timerProc.command = args
                                timerProc.running = true
                            }
                        }

                        Text {
                            visible: win.timerStatus.length > 0
                            text: win.timerStatus
                            color: Colors.grey1
                            wrapMode: Text.Wrap
                            font { family: Colors.uiFont; pixelSize: 10 }
                        }

                        // активні таймери (utimer list) — клік по ✕ скасовує
                        Repeater {
                            model: TimerService.timers.slice(0, 5)
                            delegate: RowLayout {
                                id: trow
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 6
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: trow.modelData.state === "ringing" ? Colors.red : (Colors.nothing ? Colors.nothingRed : Colors.accent)
                                }
                                Text {
                                    text: TimerService.short(trow.modelData.at)
                                    color: Colors.fg
                                    font { family: Colors.monoFont; pixelSize: 10 }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: trow.modelData.message
                                    color: Colors.grey1
                                    elide: Text.ElideRight
                                    font { family: Colors.uiFont; pixelSize: 10 }
                                }
                                Text {
                                    text: "\u2715"
                                    color: Colors.grey1
                                    font { family: Colors.uiFont; pixelSize: 11 }
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: TimerService.cancel(trow.modelData.id)
                                    }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Duration (10m, 1h30m) or date + time (10.26.2026 13:00). Runs in the background and rings when it\u2019s up."
                            color: Colors.grey1
                            wrapMode: Text.Wrap
                            font { family: Colors.uiFont; pixelSize: 10 }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Colors.nothing ? 20 : 16
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.55)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Text {
                            text: "PACKAGES"
                            color: Colors.accent
                            font { family: Colors.nothing ? Colors.monoFont : Colors.uiFont; pixelSize: 10; weight: Colors.nothing ? 400 : 700; letterSpacing: Colors.nothing ? 2.5 : 0 }
                        }

                        // кілька пакетів через пробіл або кому: htop btop flatpak:org.mozilla.firefox
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: Colors.nothing ? 10 : 6
                            color: Colors.bg1
                            border.color: Colors.bg3
                            TextInput {
                                id: pkgName
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.fg
                                font { family: Colors.uiFont; pixelSize: 11 }
                                clip: true
                                Keys.onReturnPressed: win.runPkg("install", win.pkgNames())
                                Text {
                                    text: "package names (space separated)…"
                                    color: Colors.grey1
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !parent.text
                                    font { family: Colors.uiFont; pixelSize: 11 }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: [["Search", "search"], ["Install", "install"], ["Remove", "remove"]]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    radius: Colors.nothing ? 10 : 6
                                    opacity: win.pkgBusy ? 0.45 : 1
                                    color: pkgBtnHover.hovered
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
                                        : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15)
                                    border.width: 1
                                    border.color: modelData[1] === "remove" && Colors.nothing ? Colors.nothingRed : Colors.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData[0]
                                        color: Colors.accent
                                        font { family: Colors.uiFont; pixelSize: 11; bold: true }
                                    }
                                    HoverHandler { id: pkgBtnHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !win.pkgBusy
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.runPkg(modelData[1], win.pkgNames())
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            Repeater {
                                model: [["Update all", "update"], ["Clean", "clean"]]
                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    radius: Colors.nothing ? 10 : 6
                                    opacity: win.pkgBusy ? 0.45 : 1
                                    color: sysBtnHover.hovered ? Colors.bg3 : Colors.bg1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData[0]
                                        color: Colors.fg
                                        font { family: Colors.uiFont; pixelSize: 11 }
                                    }
                                    HoverHandler { id: sysBtnHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: !win.pkgBusy
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.runPkg(modelData[1], [])
                                    }
                                }
                            }
                        }

                        // статус + «відкрити в терміналі»
                        RowLayout {
                            Layout.fillWidth: true
                            visible: win.pkgStatus.length > 0
                            spacing: 6
                            Text {
                                Layout.fillWidth: true
                                text: win.pkgStatus
                                color: win.pkgNeedsSudo ? Colors.red : Colors.grey1
                                elide: Text.ElideRight
                                font { family: Colors.monoFont; pixelSize: 10 }
                            }
                            Text {
                                text: "Open in terminal"
                                color: win.pkgNeedsSudo ? Colors.accent : Colors.grey1
                                font { family: Colors.uiFont; pixelSize: 10; underline: true }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.runPkgTerminal()
                                }
                            }
                        }

                        // лог `upkg -q`
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 70
                            radius: Colors.nothing ? 10 : 6
                            color: Colors.bg1
                            border.color: Colors.bg3
                            Flickable {
                                id: logFlick
                                anchors.fill: parent
                                anchors.margins: 6
                                clip: true
                                contentWidth: width
                                contentHeight: logText.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds
                                Text {
                                    id: logText
                                    width: logFlick.width
                                    text: win.pkgLog.length > 0 ? win.pkgLog : "upkg -q update | install pkg1 pkg2 | remove pkg1 pkg2"
                                    color: win.pkgLog.length > 0 ? Colors.fg : Colors.grey1
                                    wrapMode: Text.WrapAnywhere
                                    font { family: Colors.monoFont; pixelSize: 9 }
                                    onTextChanged: logFlick.contentY = Math.max(0, logText.implicitHeight - logFlick.height)
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
