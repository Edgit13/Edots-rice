pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

// MediaSurface — Material You (Android 13 media player layout).
Item {
    id: root

    function fmt(ms) {
        const s = Math.max(0, Math.floor(ms / 1000))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    readonly property var player: {
        const list = Mpris.players.values
        if (!list || list.length === 0) return null
        for (let i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list[0]
    }

    component MediaBtn: Rectangle {
        id: mb
        property string glyph: ""
        property bool enabled_: true
        property bool filled: false
        signal clicked()
        width: filled ? 46 : 38
        height: width
        radius: width / 2
        opacity: enabled_ ? 1.0 : 0.38
        color: {
            if (filled) return mbMa.pressed ? Md.mix(Md.primaryContainer, Md.onSurface, 0.15) : Md.primaryContainer
            if (mbMa.pressed) return Md.pressedOf(Md.onSurface)
            if (mbMa.containsMouse) return Md.hoverOf(Md.onSurface)
            return "transparent"
        }
        Behavior on color { ColorAnimation { duration: Md.durFast } }
        Text {
            anchors.centerIn: parent
            text: mb.glyph
            color: mb.filled ? Md.onPrimaryContainer : Md.onSurfaceVariant
            font { family: "SF Pro Display"; pixelSize: mb.filled ? 17 : 13 }
        }
        MouseArea {
            id: mbMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: mb.enabled_
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mb.clicked()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 14

        // ---- art ----
        Rectangle {
            Layout.preferredWidth: 88
            Layout.preferredHeight: 88
            Layout.alignment: Qt.AlignVCenter
            radius: Md.rM
            color: Md.surfaceContainerHighest
            clip: true

            Image {
                id: artCover
                anchors.fill: parent
                source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            // Android 12 loading: кільце, поки обкладинка не завантажилась
            LoadingIndicator {
                anchors.centerIn: parent
                visible: !artCover.visible
            }
        }

        // ---- info + controls + progress ----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            // чіп виводу (Android 13): іконка + пристрій
            RowLayout {
                spacing: 5
                Text {
                    text: "\ue050"
                    color: Md.onSurfaceVariant
                    font { family: "Material Symbols Rounded"; pixelSize: 12 }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.player ? (root.player.identity || "Player") : "No players"
                    color: Md.onSurfaceVariant
                    font { family: "SF Pro Display"; pixelSize: 10; weight: 600 }
                    elide: Text.ElideRight
                }
            }
            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || "Unknown track") : "Nothing playing"
                color: Md.onSurface
                font { family: "SF Pro Display"; weight: 600; pixelSize: 15 }
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist || "\u2014") : ""
                color: Md.onSurfaceVariant
                font { family: "SF Pro Display"; pixelSize: 12 }
                elide: Text.ElideRight
            }

            Item { Layout.preferredHeight: 6 }

            RowLayout {
                spacing: 6
                MediaBtn {
                    glyph: "\u25C0\u25C0"
                    enabled_: root.player && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
                MediaBtn {
                    glyph: (root.player && root.player.isPlaying) ? "\u25AE\u25AE" : "\u25B6"
                    filled: true
                    enabled_: root.player && root.player.canTogglePlaying
                    onClicked: root.player.isPlaying = !root.player.isPlaying
                }
                MediaBtn {
                    glyph: "\u25B6\u25B6"
                    enabled_: root.player && root.player.canGoNext
                    onClicked: root.player.next()
                }
            }

            // ---- progress ----
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18
                    readonly property real fraction: {
                        if (!root.player || !root.player.length || root.player.length <= 0) return 0
                        return Math.min(1, root.player.position / root.player.length)
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Md.surfaceContainerHighest
                        Rectangle {
                            width: parent.width * parent.parent.fraction
                            height: parent.height
                            radius: 2
                            color: Md.primary
                        }
                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: -7
                            anchors.bottomMargin: -7
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (root.player && root.player.length > 0) {
                                    const f = Math.max(0, Math.min(1, mouse.x / width))
                                    root.player.position = f * root.player.length
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
