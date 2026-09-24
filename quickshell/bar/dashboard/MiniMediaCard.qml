import "root:/theme"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// MiniMediaCard — компактний плеєр для сітки на вкладці "Огляд" (той самий MPRIS, що й MediaTab).
DashCard {
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
        width: parent.width
        spacing: Theme.space.sm

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            radius: Theme.shape.card
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
                text: "\ue405"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconXL }
                color: Theme.color.fgSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            ThemedText {
                Layout.fillWidth: true
                text: root.has ? (root.activePlayer.trackTitle || "Без назви") : "Нічого не грає"
                style: Theme.type.bodyMedium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
            ThemedText {
                visible: root.has
                Layout.fillWidth: true
                text: root.has ? (root.activePlayer.trackArtist || "") : ""
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.space.lg
            visible: root.has

            Text {
                text: "\ue045"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgSurface
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.has) root.activePlayer.previous() }
            }
            Text {
                text: root.playing ? "\ue034" : "\ue037"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                color: Theme.color.primary
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.has) { root.playing ? root.activePlayer.pause() : root.activePlayer.play() } }
            }
            Text {
                text: "\ue044"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgSurface
                MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.has) root.activePlayer.next() }
            }
        }
    }
}
