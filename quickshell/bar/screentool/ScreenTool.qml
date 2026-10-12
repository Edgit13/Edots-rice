import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Run:  qs -c screenshot      (needs: grim, wl-clipboard, libnotify)
Item {
    id: root

    property bool active: false

    function start()   { active = true }
    function dismiss() { active = false; busy = false }
    function toggle()  { active ? dismiss() : start() }

    property string mode: "region"      // region | screen
    property bool toClipboard: true
    property bool toFile: true
    property int delaySec: 0
    property bool busy: false

    readonly property string saveDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    Process {
        id: proc
        onExited: { root.busy = false; root.active = false }
    }

    function capture(geometry) {
        busy = true
        const script =
            (delaySec > 0 ? 'notify-send -a Screenshot -t 1500 "Capturing in ' + delaySec + 's"\n' : '') +
            'sleep ' + (0.35 + delaySec) + '\n' +
            'd="$1"; g="$2"; clip="$3"; save="$4"\n' +
            'if [ "$save" = 1 ]; then mkdir -p "$d"; f="$d/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"; else f="$(mktemp --suffix=.png)"; fi\n' +
            'grim -g "$g" "$f" || { notify-send -u critical -a Screenshot "Screenshot failed"; exit 1; }\n' +
            '[ "$clip" = 1 ] && wl-copy --type image/png < "$f"\n' +
            'if [ "$save" = 1 ]; then msg="$f"; else msg="Copied to clipboard"; fi\n' +
            'notify-send -a Screenshot -i "$f" "Screenshot captured" "$msg"\n'
        proc.command = ["sh", "-c", script, "sh", saveDir, geometry, toClipboard ? "1" : "0", toFile ? "1" : "0"]
        proc.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: root.active && !root.busy && win.ready
            WlrLayershell.namespace: "m3-screenshot"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // selection state
            property real x1: 0
            property real y1: 0
            property real x2: 0
            property real y2: 0
            property bool hasSel: false
            property bool dragging: false
            property bool ready: false
            readonly property string shotPath: "/tmp/m3-screenshot-" + (screen ? screen.name : "x") + ".png"
            readonly property real sx: Math.min(x1, x2)
            readonly property real sy: Math.min(y1, y2)
            readonly property real sw: Math.abs(x2 - x1)
            readonly property real sh: Math.abs(y2 - y1)
            readonly property bool showSel: root.mode === "region" && hasSel

            function doCapture() {
                if (!(root.toFile || root.toClipboard)) return
                if (root.mode === "screen") {
                    root.capture(screen.x + "," + screen.y + " " + screen.width + "x" + screen.height)
                } else if (hasSel) {
                    root.capture(Math.round(screen.x + sx) + "," + Math.round(screen.y + sy) + " " +
                                 Math.round(sw) + "x" + Math.round(sh))
                }
            }

            FocusScope {
                id: canvas
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.dismiss()
                Keys.onReturnPressed: win.doCapture()
                Keys.onEnterPressed: win.doCapture()

                // frozen screen (grabbed with grim before the overlay is shown)
                Process {
                    command: ["grim", "-o", win.screen.name, win.shotPath]
                    running: true
                    onExited: win.ready = true
                }
                Image {
                    anchors.fill: parent
                    source: win.ready ? "file://" + win.shotPath : ""
                    cache: false
                    asynchronous: false
                    fillMode: Image.Stretch
                }

                // scrim with cutout
                readonly property color scrimColor: root.mode === "screen" ? M3.scrimLight : M3.scrim
                Rectangle { color: canvas.scrimColor; x: 0; y: 0; width: canvas.width
                            height: win.showSel ? win.sy : canvas.height }
                Rectangle { color: canvas.scrimColor; visible: win.showSel
                            x: 0; y: win.sy; width: win.sx; height: win.sh }
                Rectangle { color: canvas.scrimColor; visible: win.showSel
                            x: win.sx + win.sw; y: win.sy; width: canvas.width - (win.sx + win.sw); height: win.sh }
                Rectangle { color: canvas.scrimColor; visible: win.showSel
                            x: 0; y: win.sy + win.sh; width: canvas.width; height: canvas.height - (win.sy + win.sh) }

                // screen-mode outline
                Rectangle {
                    visible: root.mode === "screen"
                    anchors.fill: parent
                    anchors.margins: 6
                    radius: 28
                    color: "transparent"
                    border.color: M3.primary
                    border.width: 3
                }

                // region interaction
                MouseArea {
                    id: area
                    anchors.fill: parent
                    enabled: root.mode === "region"
                    cursorShape: Qt.CrossCursor
                    property string op: ""
                    property real lx: 0
                    property real ly: 0

                    function inside(mx, my) {
                        return win.hasSel && mx >= win.sx && mx <= win.sx + win.sw && my >= win.sy && my <= win.sy + win.sh
                    }

                    onPressed: mouse => {
                        if (inside(mouse.x, mouse.y)) {
                            op = "move"; lx = mouse.x; ly = mouse.y
                        } else {
                            op = "create"
                            win.x1 = win.x2 = mouse.x
                            win.y1 = win.y2 = mouse.y
                            win.hasSel = false
                            win.dragging = true
                        }
                    }
                    onPositionChanged: mouse => {
                        if (!pressed) return
                        if (op === "create") {
                            win.x2 = Math.max(0, Math.min(canvas.width, mouse.x))
                            win.y2 = Math.max(0, Math.min(canvas.height, mouse.y))
                            win.hasSel = Math.abs(win.x2 - win.x1) > 3 || Math.abs(win.y2 - win.y1) > 3
                        } else if (op === "move") {
                            const dx = Math.max(-win.sx, Math.min(canvas.width - (win.sx + win.sw), mouse.x - lx))
                            const dy = Math.max(-win.sy, Math.min(canvas.height - (win.sy + win.sh), mouse.y - ly))
                            win.x1 += dx; win.x2 += dx; win.y1 += dy; win.y2 += dy
                            lx = mouse.x; ly = mouse.y
                        }
                    }
                    onReleased: {
                        if (op === "create") {
                            const a = Math.min(win.x1, win.x2), b = Math.min(win.y1, win.y2)
                            const c = Math.max(win.x1, win.x2), d = Math.max(win.y1, win.y2)
                            win.x1 = a; win.y1 = b; win.x2 = c; win.y2 = d
                            if (c - a < 8 || d - b < 8) win.hasSel = false
                            win.dragging = false
                        }
                        op = ""
                    }
                    onDoubleClicked: mouse => { if (inside(mouse.x, mouse.y)) win.doCapture() }
                }

                // selection outline
                Rectangle {
                    visible: win.showSel
                    x: win.sx; y: win.sy; width: win.sw; height: win.sh
                    color: "transparent"
                    border.color: M3.primary
                    border.width: 2
                    radius: 4
                }

                // size chip
                Rectangle {
                    visible: win.showSel && win.sw > 24
                    height: 28
                    width: sizeText.implicitWidth + 24
                    radius: height / 2
                    color: M3.secondaryContainer
                    x: win.sx
                    y: win.sy > 40 ? win.sy - 36 : win.sy + 8
                    Text {
                        id: sizeText
                        anchors.centerIn: parent
                        text: Math.round(win.sw) + " × " + Math.round(win.sh)
                        color: M3.fgSecondaryContainer
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }

                // corner handles
                Repeater {
                    model: 4
                    Rectangle {
                        id: h
                        required property int index
                        readonly property bool isRight: index % 2 === 1
                        readonly property bool isBottom: index > 1
                        visible: win.showSel && !win.dragging
                        width: 16; height: 16; radius: 8
                        color: M3.primary
                        border.color: M3.fgPrimary
                        border.width: 2
                        x: win.sx + (isRight ? win.sw : 0) - 8
                        y: win.sy + (isBottom ? win.sh : 0) - 8

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            preventStealing: true
                            cursorShape: h.isRight === h.isBottom ? Qt.SizeFDiagCursor : Qt.SizeBDiagCursor
                            onPositionChanged: mouse => {
                                if (!pressed) return
                                const p = mapToItem(canvas, mouse.x, mouse.y)
                                if (h.isRight) win.x2 = Math.max(win.x1 + 16, Math.min(canvas.width, p.x))
                                else         win.x1 = Math.max(0, Math.min(win.x2 - 16, p.x))
                                if (h.isBottom) win.y2 = Math.max(win.y1 + 16, Math.min(canvas.height, p.y))
                                else          win.y1 = Math.max(0, Math.min(win.y2 - 16, p.y))
                            }
                        }
                    }
                }

                // hint (snackbar style)
                Rectangle {
                    visible: root.mode === "screen" || !win.hasSel
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 48
                    height: 44
                    width: hintText.implicitWidth + 32
                    radius: 12
                    color: M3.inverseSurface
                    Text {
                        id: hintText
                        anchors.centerIn: parent
                        color: M3.inverseOnSurface
                        font.pixelSize: 14
                        text: root.mode === "screen"
                              ? "Entire screen  ·  Enter to capture"
                              : "Drag to select an area  ·  Enter to capture  ·  Esc to cancel"
                    }
                }

                // floating toolbar
                Rectangle {
                    id: bar
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40
                    width: barRow.implicitWidth + 16
                    height: barRow.implicitHeight + 16
                    radius: height / 2
                    color: M3.surfaceContainerHigh
                    border.color: M3.outlineVariant
                    border.width: 1

                    scale: 0.85
                    opacity: 0
                    Component.onCompleted: { scale = 1; opacity = 1 }
                    Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MouseArea { anchors.fill: parent }   // swallow clicks in gaps

                    RowLayout {
                        id: barRow
                        anchors.centerIn: parent
                        spacing: 4

                        MButton {
                            label: "Region"; icon: "crop_free"
                            toggled: root.mode === "region"
                            onClicked: root.mode = "region"
                        }
                        MButton {
                            label: "Screen"; icon: "fullscreen"
                            toggled: root.mode === "screen"
                            onClicked: root.mode = "screen"
                        }

                        Rectangle { width: 1; height: 24; color: M3.outlineVariant; Layout.leftMargin: 4; Layout.rightMargin: 4 }

                        MButton {
                            label: "Clipboard"; icon: "content_copy"
                            toggled: root.toClipboard
                            onClicked: root.toClipboard = !root.toClipboard
                        }
                        MButton {
                            label: "Save"; icon: "save"
                            toggled: root.toFile
                            onClicked: root.toFile = !root.toFile
                        }
                        MButton {
                            label: root.delaySec === 0 ? "Timer" : root.delaySec + "s"; icon: "timer"
                            toggled: root.delaySec > 0
                            onClicked: root.delaySec = ({0: 3, 3: 5, 5: 10, 10: 0})[root.delaySec]
                        }

                        Rectangle { width: 1; height: 24; color: M3.outlineVariant; Layout.leftMargin: 4; Layout.rightMargin: 4 }

                        MButton {
                            icon: "close"; fallback: "✕"
                            onClicked: root.dismiss()
                        }
                        MButton {
                            variant: "primary"
                            label: "Capture"; icon: "photo_camera"
                            enabled: (root.toFile || root.toClipboard) && (root.mode === "screen" || win.hasSel)
                            onClicked: win.doCapture()
                        }
                    }
                }
            }
        }
    }
}
