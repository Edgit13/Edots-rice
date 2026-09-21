import "root:/theme"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// MediaModule — M3 Expressive міні-плеєр (MPRIS).
// Клік: Play/Pause; Правий клік: Next; Автоматично ховається, якщо нічого не грає.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact
    signal mediaRequested()

    // Знаходимо активного або першого доступного гравця
    readonly property var activePlayer: {
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        }
        return players.length > 0 ? players[0] : null
    }

    readonly property bool hasMedia: activePlayer !== null && (activePlayer.trackTitle.length > 0 || activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property bool isPlaying: activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "Media") : ""
    readonly property string artist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string displayTrack: artist.length > 0 ? (artist + " — " + title) : title

    visible: hasMedia
    implicitWidth: hasMedia ? (vertical ? cross : Math.min(220, contentRow.implicitWidth + Theme.space.sm * 2)) : 0
    implicitHeight: hasMedia ? (vertical ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross) : 0

    Behavior on implicitWidth { MotionAnimation { role: "morph" } }
    Behavior on implicitHeight { MotionAnimation { role: "morph" } }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.shape.radius("full", Math.min(width, height))
        color: ma.pressed ? Theme.stateLayer(Theme.color.tertiaryContainer, Theme.color.fgTertiaryContainer, Theme.components.statePressed)
             : ma.containsMouse ? Theme.stateLayer(Theme.color.tertiaryContainer, Theme.color.fgTertiaryContainer, Theme.components.stateHover)
             : Theme.color.tertiaryContainer

        scale: ma.pressed ? 0.94 : 1.0
        Behavior on color { MotionColorAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "press" } }

        Row {
            id: contentRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.isPlaying ? "\ue034" : "\ue037"  // pause vs play_arrow
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgTertiaryContainer
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.displayTrack
                style: Theme.type.labelMedium
                color: Theme.color.fgTertiaryContainer
                elide: Text.ElideRight
                width: Math.min(150, implicitWidth)
            }
        }

        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.isPlaying ? "\ue034" : "\ue037"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgTertiaryContainer
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
            if (!root.activePlayer) return
            if (mouse.button === Qt.RightButton) {
                root.activePlayer.next()
            } else {
                // Fix: Manually toggle playback state using explicit methods
                if (root.isPlaying) {
                    root.activePlayer.pause()
                } else {
                    root.activePlayer.play()
                }
            }
        }
    }


    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(event) {
            if (!root.activePlayer) return
            if (event.angleDelta.y > 0) root.activePlayer.previous()
            else root.activePlayer.next()
        }
    }
}
