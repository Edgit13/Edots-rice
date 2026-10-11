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

    component MediaButton: Rectangle {
        id: btn
        property string icon: ""
        property bool emphasized: false
        property bool big: false
        signal clicked()

        implicitWidth: big ? 56 : 40
        implicitHeight: big ? 56 : 40
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
            font { family: Theme.type.icons; pixelSize: btn.big ? Theme.type.iconL : Theme.type.iconM }
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
                    text: "\ue405"
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconXL * 1.5 }
                    color: Theme.color.fgSurfaceVariant
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                ThemedText {
                    text: root.has ? (root.activePlayer.trackTitle || "Без назви") : ""
                    style: Theme.type.titleMedium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
                ThemedText {
                    text: root.has ? (root.activePlayer.trackArtist || "") : ""
                    style: Theme.type.bodyMedium
                    color: Theme.color.fgSurfaceVariant
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.md
                Layout.alignment: Qt.AlignHCenter

                MediaButton {
                    icon: "\ue045"
                    onClicked: if (root.has) root.activePlayer.previous()
                }
                MediaButton {
                    icon: root.playing ? "\ue034" : "\ue037"
                    emphasized: true
                    big: true
                    onClicked: if (root.has) { root.playing ? root.activePlayer.pause() : root.activePlayer.play() }
                }
                MediaButton {
                    icon: "\ue044"
                    onClicked: if (root.has) root.activePlayer.next()
                }
            }
        }
    }
}
