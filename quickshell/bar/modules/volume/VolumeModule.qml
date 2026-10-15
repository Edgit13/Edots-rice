import "root:/theme"
import "root:/modules/common"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// VolumeModule — іконка; значення виїжджає при hover (як індикатори в end-4).
// Колесо: ±5% · ЛКМ: mute · ПКМ: Mixer.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal mixerRequested()

    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.ready
    readonly property bool muted: ready && sink.audio.muted
    readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

    readonly property string iconGlyph: {
        if (!ready || muted) return "\ue04f"
        if (vol === 0) return "\ue04e"
        if (vol < 50) return "\ue04d"
        return "\ue050"
    }
    readonly property real iconBox: Theme.type.iconS
    readonly property real fullW: (cross + iconBox) / 2 + Theme.space.xs + label.implicitWidth + Theme.space.md

    implicitWidth: vertical ? cross : (btn.hovered ? fullW : cross)
    implicitHeight: vertical ? (vcol.implicitHeight + Theme.space.xs * 2) : cross
    Behavior on implicitWidth { MotionAnimation { role: "morph" } }

    PwObjectTracker { objects: [root.sink] }

    BarButton {
        id: btn
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.mixerRequested()
            else if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
        }
        onWheeled: e => {
            if (!root.sink || !root.sink.audio) return
            const next = Math.max(0.0, Math.min(1.5, root.sink.audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
            root.sink.audio.volume = next
            if (root.sink.audio.muted && next > 0) root.sink.audio.muted = false
        }

        Row {
            visible: !root.vertical
            anchors.verticalCenter: parent.verticalCenter
            x: (btn.height - root.iconBox) / 2
            spacing: Theme.space.xs
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.muted ? Theme.color.error : Theme.color.fgSurface
                Behavior on color { MotionColorAnimation { role: "hover" } }
            }
            ThemedText {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "Mute" : (root.vol + "%")
                style: Theme.type.labelMedium
                color: root.muted ? Theme.color.outline : Theme.color.fgSurface
                opacity: btn.hovered ? 1 : 0
                Behavior on opacity { MotionAnimation { role: "hover" } }
            }
        }

        Column {
            id: vcol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.muted ? Theme.color.error : Theme.color.fgSurface
            }
            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.muted ? "✕" : String(root.vol)
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
            }
        }
    }
}
