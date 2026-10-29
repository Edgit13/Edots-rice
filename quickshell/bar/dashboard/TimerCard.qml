import "root:/theme"
import "root:/services"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

DashCard {
    id: root
    // «Таймер · 10.26 13:00 Call mom» — найближче заплановане нагадування (utimer), якщо є
    title: TimerService.next
        ? ("Таймер · " + TimerService.short(TimerService.next.at)
           + (TimerService.next.message ? "  " + TimerService.next.message.slice(0, 16) : ""))
        : "Таймер"

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
        readonly property bool nothing: Theme.settings.nothing
        color: emphasized ? Theme.color.primary
             : nothing ? (bma.pressed ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.16)
                          : bma.containsMouse ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.08) : "transparent")
             : bma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
             : bma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHighest
        border.width: nothing && !emphasized ? 1 : 0
        border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.28)
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Text {
            anchors.centerIn: parent
            text: btn.icon
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            color: btn.emphasized ? Theme.color.fgPrimary : Theme.color.fgSurface
        }
        MouseArea {
            id: bma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    RowLayout {
        width: parent.width
        height: implicitHeight
        spacing: Theme.space.lg

        RowLayout {
            spacing: Theme.space.xs
            visible: !root._started
            RoundBtn { icon: "\ue15b"; onClicked: root.addMinutes(-1) }
            ThemedText {
                text: Math.round(root.totalSeconds / 60) + " хв"
                style: Theme.type.labelMedium
                color: Theme.color.fgSurfaceVariant
                Layout.preferredWidth: 56
                horizontalAlignment: Text.AlignHCenter
            }
            RoundBtn { icon: "\ue145"; onClicked: root.addMinutes(1) }
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
                icon: root.running ? "\ue034" : "\ue037"
                emphasized: true
                onClicked: root.running ? root.pause() : root.start()
            }
            RoundBtn { icon: "\ue5d5"; onClicked: root.reset() }
        }
    }
}
