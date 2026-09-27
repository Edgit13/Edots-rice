import "root:/theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// TimerCard — простий таймер (хв:сек), старт/пауза/скидання. По завершенню: візуальний
// спалах + системне сповіщення через notify-send (той самий шлях, що вже стоїть для swaync).
DashCard {
    id: root
    title: "Таймер"

    property int totalSeconds: 5 * 60
    property int remaining: totalSeconds
    property bool running: false
    readonly property bool finished: remaining <= 0 && !running && _started
    property bool _started: false

    function _fmt(s) {
        const m = Math.floor(s / 60), ss = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (ss < 10 ? "0" : "") + ss
    }

    function start() {
        if (remaining <= 0) remaining = totalSeconds
        running = true
        _started = true
    }
    function pause() { running = false }
    function reset() {
        running = false
        _started = false
        remaining = totalSeconds
    }
    function addMinutes(delta) {
        totalSeconds = Math.max(60, Math.min(180 * 60, totalSeconds + delta * 60))
        if (!_started) remaining = totalSeconds
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            root.remaining -= 1
            if (root.remaining <= 0) {
                root.remaining = 0
                root.running = false
                notifyProc.running = true
            }
        }
    }
    Process {
        id: notifyProc
        command: ["notify-send", "Таймер", "Час вийшов", "-a", "Edots"]
    }

    component RoundBtn: Rectangle {
        id: btn
        property string icon: ""
        property bool emphasized: false
        signal clicked()
        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: emphasized ? Theme.color.primary
             : bma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
             : bma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHighest
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Text {
            anchors.centerIn: parent
            text: btn.icon
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            color: btn.emphasized ? Theme.color.fgPrimary : Theme.color.fgSurface
        }
        MouseArea { id: bma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
    }

    RowLayout {
        width: parent.width
        spacing: Theme.space.lg

        RowLayout {
            spacing: Theme.space.xs
            visible: !root._started
            RoundBtn { icon: "\ue15b"; onClicked: root.addMinutes(-1) }   // remove
            ThemedText { text: Math.round(root.totalSeconds / 60) + " хв"; style: Theme.type.labelMedium
                         color: Theme.color.fgSurfaceVariant; Layout.preferredWidth: 44
                         horizontalAlignment: Text.AlignHCenter }
            RoundBtn { icon: "\ue145"; onClicked: root.addMinutes(1) }    // add
        }

        ThemedText {
            text: root._fmt(root.remaining)
            style: Theme.type.displaySmall
            emphasized: true
            color: root.finished ? Theme.color.error : Theme.color.fgSurface
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            spacing: Theme.space.xs
            RoundBtn {
                icon: root.running ? "\ue034" : "\ue037"   // pause/play
                emphasized: true
                onClicked: root.running ? root.pause() : root.start()
            }
            RoundBtn { icon: "\ue5d5"; onClicked: root.reset() }   // refresh/reset
        }
    }
}
