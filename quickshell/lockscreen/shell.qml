//@ pragma UseQApplication
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property bool authenticating: false
    property bool showPassword: false
    property int errorCount: 0

    FileView {
        id: colorsFile
        path: Quickshell.shellPath("../colors.json")
        watchChanges: true
    }

    FileView {
        id: wallpaperFile
        path: Quickshell.shellPath("../current-wallpaper.txt")
        watchChanges: true
    }

    property string wallpaperPath: {
        try {
            var p = wallpaperFile.text().trim()
            return p.length > 0 ? p : ""
        } catch (e) {
            return ""
        }
    }
    property string wallpaperUrl: wallpaperPath.length > 0 ? "file://" + wallpaperPath : ""

    function parseColors() {
        try {
            return JSON.parse(colorsFile.text())
        } catch (e) {
            return ({
                "bg0": "#0f0b06", "surface_container": "#251e17",
                "surface_container_high": "#302921", "fg": "#e7e1da",
                "on_surface": "#ede0d4", "on_surface_variant": "#d4c4b4",
                "primary": "#f7bc70", "on_primary": "#462a00",
                "red": "#f68056", "aqua": "#26bdf3",
                "outline": "#9c8e80", "outline_variant": "#504539",
                "grey2": "#d5b790", "scrim": "#000000"
            })
        }
    }
    property var colors: parseColors()

    // ---------------------------------------------------------------- auth
    Process {
        id: authProc
        stdinEnabled: true
        property string pendingPassword: ""

        onStarted: write(pendingPassword + "\n")

        onExited: (exitCode, exitStatus) => {
            root.authenticating = false
            root.statusWorking = false
            if (exitCode === 0) {
                lock.locked = false
            } else {
                root.errorCount += 1
                root.statusError = true
            }
        }
    }

    Process { id: powerProc }

    function tryUnlock() {
        if (root.authenticating || passText.length === 0) return
        root.authenticating = true
        root.statusError = false
        root.statusWorking = true
        authProc.pendingPassword = root.passText
        root.passText = ""
        authProc.exec([root.home + "/.config/quickshell/lockscreen/pam-auth"])
    }

    function runPower(cmd) {
        powerProc.exec(cmd)
    }

    // state shared with the surface instances (they live per-screen)
    property string passText: ""
    property bool statusWorking: false
    property bool statusError: false
    property var powerExec: []

    function clearPass() { passText = "" }

    // ------------------------------------------------------------- session
    WlSessionLock {
        id: lock
        locked: true

        // unlock confirmed by compositor -> leave a beat, then quit
        onSecureChanged: if (!secure) quitTimer.start()

        WlSessionLockSurface {
            color: root.colors.bg0

            Component.onCompleted: passField.forceActiveFocus()

            // blurred wallpaper (falls back to plain scrim if path is missing)
            Image {
                id: wallpaper
                anchors.fill: parent
                source: root.wallpaperUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: wallpaper
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                visible: wallpaper.status === Image.Ready
            }
            Rectangle {
                anchors.fill: parent
                color: root.colors.scrim
                opacity: wallpaper.status === Image.Ready ? 0.35 : 0.6
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                color: root.colors.primary
            }

            // click scrim -> refocus password
            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: passField.forceActiveFocus()
            }

            // clock
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.1
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clockTimer.date, "hh:mm")
                    color: root.colors.fg
                    font.pixelSize: 110
                    font.weight: Font.Light
                    font.family: "monospace"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clockTimer.date, "dddd, d MMMM yyyy")
                    color: root.colors.grey2
                    font.pixelSize: 22
                    font.family: "monospace"
                }
            }

            Timer {
                id: clockTimer
                property var date: new Date()
                interval: 1000
                running: true
                repeat: true
                onTriggered: date = new Date()
            }

            // main card
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: 440
                height: cardCol.implicitHeight + 56
                radius: 18
                color: root.colors.surface_container
                border.color: root.colors.outline_variant
                border.width: 1
                opacity: 0.97

                Column {
                    id: cardCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 28
                    spacing: 18

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 88
                        height: 88
                        radius: 44
                        color: root.colors.surface_container_high
                        border.color: root.colors.primary
                        border.width: 2
                        Text {
                            anchors.centerIn: parent
                            text: (Quickshell.env("USER") || "u").substring(0, 1).toUpperCase()
                            color: root.colors.primary
                            font.pixelSize: 40
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Quickshell.env("USER")
                        color: root.colors.on_surface
                        font.pixelSize: 24
                        font.weight: Font.Medium
                    }

                    // password field
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 340
                        height: 52
                        radius: 12
                        color: root.colors.surface_container_high
                        border.color: passField.activeFocus ? root.colors.primary : root.colors.outline_variant
                        border.width: passField.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        TextInput {
                            id: passField
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 48
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "●"
                            color: root.colors.on_surface
                            font.pixelSize: 20
                            font.family: "monospace"
                            focus: true
                            text: root.passText
                            onTextChanged: if (text !== root.passText) root.passText = text
                            onAccepted: root.tryUnlock()
                            Keys.onEscapePressed: { root.passText = ""; text = "" }
                        }

                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: -12
                            visible: root.passText.length === 0 && !passField.activeFocus
                            text: "enter password"
                            color: root.colors.outline
                            font.pixelSize: 17
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            radius: 8
                            color: eyeMa.containsMouse ? root.colors.surface_container : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: root.showPassword ? "◡" : "◠"
                                color: root.colors.on_surface_variant
                                font.pixelSize: 16
                            }
                            MouseArea {
                                id: eyeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showPassword = !root.showPassword
                            }
                        }
                    }

                    Text {
                        id: statusText
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.pixelSize: 15
                        font.family: "monospace"
                        text: root.statusWorking ? "authenticating…"
                            : root.statusError ? "wrong password (attempt " + root.errorCount + ")"
                            : "locked"
                        color: root.statusWorking ? root.colors.aqua
                             : root.statusError ? root.colors.red
                             : root.colors.outline
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    // power row
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 28

                        Repeater {
                            model: [
                                { glyph: "⏾", cmd: ["systemctl", "suspend"] },
                                { glyph: "↻", cmd: ["systemctl", "reboot"] },
                                { glyph: "⏻", cmd: ["systemctl", "poweroff"] }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 46
                                height: 46
                                radius: 10
                                color: powerMa.containsMouse ? root.colors.surface_container_high : "transparent"
                                border.color: root.colors.outline_variant
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.glyph
                                    color: powerMa.containsMouse ? root.colors.primary : root.colors.on_surface_variant
                                    font.pixelSize: 22
                                }
                                MouseArea {
                                    id: powerMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.powerExec = modelData.cmd
                                }
                            }
                        }
                    }
                }
            }

            // power confirmation overlay
            Rectangle {
                id: confirmPower
                anchors.fill: parent
                color: root.colors.scrim
                opacity: visible ? 0.8 : 0
                visible: root.powerExec.length > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 380
                    height: col2.implicitHeight + 40
                    radius: 14
                    color: root.colors.surface_container_high
                    border.color: root.colors.outline_variant

                    Column {
                        id: col2
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 16

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.powerExec.length === 0 ? ""
                                : "really " + root.powerExec[root.powerExec.length - 1] + "?"
                            color: root.colors.on_surface
                            font.pixelSize: 20
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 20

                            Rectangle {
                                width: 120; height: 40; radius: 10
                                color: yesMa.containsMouse ? root.colors.red : root.colors.surface_container
                                Text { anchors.centerIn: parent; text: "yes"; color: root.colors.on_surface }
                                MouseArea {
                                    id: yesMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.runPower(root.powerExec)
                                        root.powerExec = []
                                    }
                                }
                            }
                            Rectangle {
                                width: 120; height: 40; radius: 10
                                color: noMa.containsMouse ? root.colors.primary : root.colors.surface_container
                                Text {
                                    anchors.centerIn: parent
                                    text: "no"
                                    color: noMa.containsMouse ? root.colors.on_primary : root.colors.on_surface
                                }
                                MouseArea {
                                    id: noMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.powerExec = []
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: quitTimer
        interval: 200
        onTriggered: Qt.quit()
    }

    // watchdog: if the compositor never confirms the lock, bail out
    Timer {
        interval: 2500
        onTriggered: {
            if (!lock.secure) {
                console.error("ilock: compositor did not confirm session lock " +
                              "(ext-session-lock-v1 unsupported?) — quitting")
                Qt.quit()
            }
        }
        Component.onCompleted: start()
    }

    IpcHandler {
        target: "ilock"
        function relock(): void { lock.locked = true }
        function quit(): void { Qt.quit() }
    }

}
