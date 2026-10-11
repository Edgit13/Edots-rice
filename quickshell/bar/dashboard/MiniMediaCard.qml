import "root:/theme"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// MiniMediaCard — компактний плеєр для сітки на вкладці "Огляд".
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

    implicitHeight: 260

    component MediaButton: Rectangle {
        id: btn
        property string icon: ""
        property bool emphasized: false
        signal clicked()

        implicitWidth: emphasized ? 40 : 32
        implicitHeight: emphasized ? 40 : 32
        radius: width / 2

        color: emphasized
             ? (ma.pressed
                 ? Theme.stateLayer(Theme.color.primary, Theme.color.fgPrimary, Theme.components.statePressed)
                 : ma.containsMouse
                     ? Theme.stateLayer(Theme.color.primary, Theme.color.fgPrimary, Theme.components.stateHover)
                     : Theme.color.primary)
             : (ma.pressed
                 ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
                 : ma.containsMouse
                     ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
                     : "transparent")
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font { family: Theme.type.icons; pixelSize: btn.emphasized ? Theme.type.iconM : Theme.type.iconS }
            color: btn.emphasized ? Theme.color.fgPrimary : Theme.color.fgSurface
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
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
            spacing: Theme.space.sm
            visible: root.has

            MediaButton { icon: "\ue045"; onClicked: if (root.has) root.activePlayer.previous() }
            MediaButton {
                icon: root.playing ? "\ue034" : "\ue037"
                emphasized: true
                onClicked: if (root.has) { root.playing ? root.activePlayer.pause() : root.activePlayer.play() }
            }
            MediaButton { icon: "\ue044"; onClicked: if (root.has) root.activePlayer.next() }
        }
    }
}
