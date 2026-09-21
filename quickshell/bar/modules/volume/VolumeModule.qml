import "root:/theme"
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// VolumeModule — M3 Expressive модуль аудіо через Pipewire.
// Колесо миші: гучність ±5%; клік: mute / unmute; правий клік: відкрити Mixer.
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
        if (!ready || muted) return "\ue04f"   // volume_off
        if (vol === 0) return "\ue04e"        // volume_mute
        if (vol < 50) return "\ue04d"         // volume_down
        return "\ue050"                       // volume_up
    }

    implicitWidth: vertical ? cross : (contentRow.implicitWidth + Theme.space.sm * 2)
    implicitHeight: vertical ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross

    PwObjectTracker {
        objects: [root.sink]
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHigh

        scale: ma.pressed ? 0.94 : 1.0
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        // Horizontal layout
        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.muted ? Theme.color.error : Theme.color.primary
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.muted ? "Mute" : (root.vol + "%")
                style: Theme.type.labelMedium
                color: root.muted ? Theme.color.outline : Theme.color.fgSurface
            }
        }

        // Vertical layout
        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: root.muted ? Theme.color.error : Theme.color.primary
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.muted ? "✕" : String(root.vol)
                style: Theme.type.labelSmall
                color: root.muted ? Theme.color.outline : Theme.color.fgSurface
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.mixerRequested()
            } else if (root.sink && root.sink.audio) {
                root.sink.audio.muted = !root.sink.audio.muted
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (!root.sink || !root.sink.audio) return
            const delta = event.angleDelta.y > 0 ? 0.05 : -0.05
            const nextVol = Math.max(0.0, Math.min(1.5, root.sink.audio.volume + delta))
            root.sink.audio.volume = nextVol
            if (root.sink.audio.muted && nextVol > 0) {
                root.sink.audio.muted = false
            }
        }
    }
}
