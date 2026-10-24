import "root:/theme"
import "root:/modules/common"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// VolumeModule — іконка; значення виїжджає при hover (як індикатори в end-4).
// Колесо: ±5% · ЛКМ: mute · ПКМ: Mixer.
BarRevealButton {
    id: root

    signal mixerRequested()

    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.ready
    readonly property bool muted: ready && sink.audio.muted
    readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

    glyph: {
        if (!ready || muted) return "\ue04f"
        if (vol === 0) return "\ue04e"
        if (vol < 50) return "\ue04d"
        return "\ue050"
    }
    glyphColor: muted ? Theme.color.error : Theme.color.fgSurface
    label: muted ? "Mute" : (vol + "%")
    labelColor: muted ? Theme.color.outline : Theme.color.fgSurface
    verticalLabel: muted ? "✕" : String(vol)
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

    PwObjectTracker { objects: [root.sink] }
}
