import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property var theme: ({
        "bg0": "#0e0f06",
        "bg1": "#181a0a",
        "bg2": "#25290f",
        "bg3": "#333715",
        "bg4": "#444a1c",
        "fg": "#e5e7da",
        "accent": "#d3e467",
        "red": "#d2c479",
        "grey1": "#768131"
    })

    property var taskData: ({})
    property var folders: ["Default"]
    property string currentFolder: "Default"
    property bool showingNewFolderInput: false

    function reloadTheme() {
        colorLoader.running = false;
        Qt.callLater(() => { colorLoader.running = true; });
    }

    function reloadTasks() {
        taskLoader.running = false;
        Qt.callLater(() => { taskLoader.running = true; });
    }

    function runAction(args) {
        actionRunner.command = args;
        actionRunner.running = false;
        Qt.callLater(() => { actionRunner.running = true; });
    }

    // Automatically checks and reloads colors every 1.5 seconds without needing inotifywait
    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.reloadTheme()
    }

    // Reads theme colors directly from ~/.config/mango/colors.json
    Process {
        id: colorLoader
        command: ["cat", Quickshell.env("HOME") + "/.config/mango/colors.json"]
        running: true
        property string buffer: ""

        stdout: SplitParser {
            onRead: data => {
                colorLoader.buffer += data + "\n";
            }
        }

        onExited: (code, status) => {
            if (code === 0 && colorLoader.buffer.trim() !== "") {
                try {
                    root.theme = JSON.parse(colorLoader.buffer.trim());
                } catch(e) {
                    console.log("Color parse error: " + e);
                }
            }
            colorLoader.buffer = "";
        }
    }

    // Fetches task data
    Process {
        id: taskLoader
        command: ["python3", "-u", "/home/eduard/edots/task-manager/core.py", "-c", "export-json"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var parsed = JSON.parse(data);
                    root.taskData = parsed;
                    var keys = Object.keys(parsed);
                    if (keys.length > 0) {
                        root.folders = keys;
                        if (keys.indexOf(root.currentFolder) === -1) {
                            root.currentFolder = keys[0];
                        }
                    }
                } catch(e) {}
            }
        }
    }

    // Command runner for write operations
    Process {
        id: actionRunner
        running: false
        stdout: SplitParser {
            onRead: data => { root.reloadTasks(); }
        }
    }

    FloatingWindow {
        id: win
        visible: true
        implicitWidth: 380
        implicitHeight: 440
        title: "Task Manager"
        color: root.theme["bg0"] || "#0e0f06"

        MouseArea {
            anchors.fill: parent
            property point clickPos: Qt.point(0, 0)
            onPressed: (mouse) => { clickPos = Qt.point(mouse.x, mouse.y) }
            onPositionChanged: (mouse) => {
                win.x += mouse.x - clickPos.x
                win.y += mouse.y - clickPos.y
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Folder Tabs Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Flickable {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    contentWidth: folderRow.implicitWidth
                    clip: true

                    RowLayout {
                        id: folderRow
                        spacing: 6

                        Repeater {
                            model: root.folders
                            delegate: Rectangle {
                                implicitWidth: folderTextContainer.implicitWidth + 16
                                implicitHeight: 28
                                radius: 6
                                color: modelData === root.currentFolder ? root.theme["bg3"] : root.theme["bg1"]
                                border.color: modelData === root.currentFolder ? root.theme["accent"] : "transparent"
                                border.width: 1

                                RowLayout {
                                    id: folderTextContainer
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: modelData
                                        color: modelData === root.currentFolder ? root.theme["accent"] : root.theme["fg"]
                                        font.pixelSize: 12
                                        font.bold: modelData === root.currentFolder
                                    }

                                    // Folder Delete Button (shown when tab is selected)
                                    Text {
                                        visible: modelData === root.currentFolder && root.folders.length > 1
                                        text: "✕"
                                        color: root.theme["red"]
                                        font.pixelSize: 10

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.runAction([
                                                    "python3", "-u", "/home/eduard/edots/task-manager/core.py",
                                                    "-c", "remove-folder",
                                                    "-f", modelData
                                                ]);
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.currentFolder = modelData }
                                }
                            }
                        }
                    }
                }

                // Add Folder Toggle Button
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 6
                    color: root.theme["bg2"]
                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: root.theme["accent"]
                        font.pixelSize: 16
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.showingNewFolderInput = !root.showingNewFolderInput }
                    }
                }
            }

            // New Folder Input Field (Toggled)
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: root.showingNewFolderInput ? 32 : 0
                visible: root.showingNewFolderInput
                color: root.theme["bg1"]
                radius: 6
                border.color: root.theme["bg3"]

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4

                    TextInput {
                        id: folderInput
                        Layout.fillWidth: true
                        color: root.theme["fg"]
                        font.pixelSize: 12
                        clip: true
                        Text {
                            text: "New folder name..."
                            color: root.theme["grey1"]
                            font.pixelSize: 12
                            visible: !parent.text
                        }
                    }

                    Rectangle {
                        implicitWidth: 50
                        implicitHeight: 24
                        radius: 4
                        color: root.theme["accent"]
                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            color: root.theme["bg0"]
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (folderInput.text.trim() !== "") {
                                    root.runAction(["python3", "-u", "/home/eduard/edots/task-manager/core.py", "-c", "create-folder", "-f", folderInput.text.trim()]);
                                    folderInput.text = "";
                                    root.showingNewFolderInput = false;
                                }
                            }
                        }
                    }
                }
            }

            // Task Input Fields
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                color: root.theme["bg1"]
                radius: 6
                border.color: root.theme["bg3"]

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    TextInput {
                        id: taskTitleInput
                        Layout.fillWidth: true
                        color: root.theme["fg"]
                        font.pixelSize: 12
                        clip: true
                        Text {
                            text: "Add task title..."
                            color: root.theme["grey1"]
                            font.pixelSize: 12
                            visible: !parent.text
                        }
                    }

                    Rectangle {
                        implicitWidth: 60
                        implicitHeight: 24
                        color: root.theme["bg2"]
                        radius: 4

                        TextInput {
                            id: taskDueInput
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            color: root.theme["accent"]
                            font.pixelSize: 11
                            Text {
                                text: "18:00"
                                color: root.theme["grey1"]
                                font.pixelSize: 11
                                anchors.centerIn: parent
                                visible: !parent.text
                            }
                        }
                    }

                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 24
                        radius: 4
                        color: root.theme["accent"]

                        Text {
                            anchors.centerIn: parent
                            text: "Add"
                            color: root.theme["bg0"]
                            font.pixelSize: 11
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (taskTitleInput.text.trim() !== "") {
                                    root.runAction([
                                        "python3", "-u", "/home/eduard/edots/task-manager/core.py",
                                        "-c", "create",
                                        "-f", root.currentFolder,
                                        "-t", taskTitleInput.text.trim(),
                                        "-d", taskDueInput.text.trim()
                                    ]);
                                    taskTitleInput.text = "";
                                    taskDueInput.text = "";
                                }
                            }
                        }
                    }
                }
            }

            // Tasks List View
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6

                model: (root.taskData && root.taskData[root.currentFolder]) ? root.taskData[root.currentFolder] : []

                delegate: Rectangle {
                    width: ListView.view.width
                    implicitHeight: 38
                    radius: 6
                    color: root.theme["bg1"]
                    border.color: root.theme["bg2"]

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: root.theme["fg"]
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        // Due Time Badge
                        Rectangle {
                            visible: modelData.due !== ""
                            implicitWidth: dueText.implicitWidth + 10
                            implicitHeight: 18
                            radius: 4
                            color: root.theme["bg3"]

                            Text {
                                id: dueText
                                anchors.centerIn: parent
                                text: modelData.due
                                color: root.theme["accent"]
                                font.pixelSize: 10
                            }
                        }

                        // Task Delete Button
                        Text {
                            text: "✕"
                            color: root.theme["red"]
                            font.pixelSize: 12

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.runAction([
                                        "python3", "-u", "/home/eduard/edots/task-manager/core.py",
                                        "-c", "remove",
                                        "-f", root.currentFolder,
                                        "-i", index.toString()
                                    ]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
