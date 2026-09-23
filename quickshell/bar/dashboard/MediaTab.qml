import "root:/theme"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// MediaTab — повний плеєр (MPRIS): обкладинка, назва/виконавець, прогрес, керування.
Item {
    id: root

    readonly property var activePlayer: {
        const players = Mpris.players.values
        for (let i = 0; i < players.length; i++)
            if (players[i].playbackState === MprisPlaybackState.Playing) return players[i]
        return players.length > 0 ? players[0] : null
    }
    readonly property bool has: activePlayer !== null
    readonly property bool playing: has && activePlayer.playbackState === MprisPlaybackState.Playing

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.lg
        spacing: Theme.space.lg

        ThemedText {
            visible: !root.has
            text: "Нічого не грає"
            style: Theme.type.bodyLarge
            color: Theme.color.fgSurfaceVariant
            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: true
        }

        ColumnLayout {
            visible: root.has
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space.md

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 200
                Layout.preferredHeight: 200
                radius: Theme.shape.cardLarge
                color: Theme.color.surfaceContainerHighest
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.has ? root.activePlayer.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !root.has || root.activePlayer.trackArtUrl.length === 0
                    text: "\ue405"   // music_note
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconXL * 1.5 }
                    color: Theme.color.fgSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                ThemedText { text: root.has ? (root.activePlayer.trackTitle || "Без назви") : ""
                             style: Theme.type.titleMedium; Layout.fillWidth: true; elide: Text.ElideRight
                             horizontalAlignment: Text.AlignHCenter }
                ThemedText { text: root.has ? (root.activePlayer.trackArtist || "") : ""
                             style: Theme.type.bodyMedium; color: Theme.color.fgSurfaceVariant
                             Layout.fillWidth: true; elide: Text.ElideRight
                             horizontalAlignment: Text.AlignHCenter }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.md
                Layout.alignment: Qt.AlignHCenter

                Text {
                    text: "\ue045"   // skip_previous
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconL }
                    color: Theme.color.fgSurface
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.has) root.activePlayer.previous() }
                }
                Rectangle {
                    width: 56; height: 56; radius: 28
                    color: Theme.color.primary
                    Text {
                        anchors.centerIn: parent
                        text: root.playing ? "\ue034" : "\ue037"
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconL }
                        color: Theme.color.fgPrimary
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.has) { root.playing ? root.activePlayer.pause() : root.activePlayer.play() } }
                }
                Text {
                    text: "\ue044"   // skip_next
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconL }
                    color: Theme.color.fgSurface
                    MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.has) root.activePlayer.next() }
                }
            }
        }
    }
}
