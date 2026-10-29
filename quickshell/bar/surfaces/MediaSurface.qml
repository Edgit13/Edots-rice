import "root:/theme"
import "root:/settings"
import "root:/services"
import "root:/media"
import QtQuick
import QtQuick.Layouts

// MediaSurface — M3 Expressive плеєр для оверлею (460×320 картка).
// Обкладинка морфиться (пауза → коло), хвиляста шкала, кнопка play морфиться коло ↔ squircle.
Item {
    id: root

    // ---- порожній стан ----
    ColumnLayout {
        anchors.centerIn: parent
        visible: !MediaService.has
        spacing: Theme.space.sm

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\ue405"
            font { family: Theme.type.icons; pixelSize: Theme.type.iconXL }
            color: Theme.color.fgSurfaceVariant
        }
        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: Lang.t("ui.media.none")
            style: Theme.type.bodyLarge
            color: Theme.color.fgSurfaceVariant
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: MediaService.has
        spacing: Theme.space.lg

        MediaArt {
            Layout.preferredWidth: Math.min(Theme.components.dp(148), root.height)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            source: MediaService.artUrl
            playing: MediaService.playing
            morphOnPause: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            // чіп джерела (клік — наступний плеєр)
            Rectangle {
                id: chip
                Layout.alignment: Qt.AlignLeft
                implicitHeight: Theme.components.tooltipHeight
                implicitWidth: Math.min(parent.width, chipRow.implicitWidth + Theme.space.xl)
                radius: chipMa.pressed ? Theme.shape.xs : height / 2
                color: Theme.settings.nothing ? "transparent" : Theme.color.secondaryContainer
                border.width: Theme.settings.nothing ? 1 : 0
                border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.25)
                Behavior on radius { MotionAnimation { role: "morph" } }

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: Theme.space.xxs
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\ue405"
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                        color: Theme.settings.nothing ? Theme.color.fgSurfaceVariant : Theme.color.fgSecondaryContainer
                    }
                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: MediaService.identity || Lang.t("ui.media.player")
                        style: Theme.type.labelSmall
                        color: Theme.settings.nothing ? Theme.color.fgSurfaceVariant : Theme.color.fgSecondaryContainer
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, chip.parent.width - Theme.space.xxxl - Theme.space.sm)
                    }
                    ThemedText {
                        visible: MediaService.players.length > 1
                        anchors.verticalCenter: parent.verticalCenter
                        text: "· " + MediaService.players.length
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSecondaryContainer
                    }
                }
                MouseArea {
                    id: chipMa
                    anchors.fill: parent
                    enabled: MediaService.players.length > 1
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        const l = MediaService.players
                        MediaService.manual = l[(l.indexOf(MediaService.player) + 1) % l.length]
                    }
                }
            }

            ThemedText {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.xs
                text: MediaService.title || Lang.t("ui.media.unknown")
                style: Theme.type.titleMedium
                emphasized: true
                elide: Text.ElideRight
            }
            ThemedText {
                Layout.fillWidth: true
                text: MediaService.artist || "\u2014"
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
                elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            MediaProgress {
                Layout.fillWidth: true
                value: MediaService.fraction
                playing: MediaService.playing
                seekable: MediaService.canSeek
                onSeeked: f => MediaService.seek(f)
            }
            RowLayout {
                Layout.fillWidth: true
                ThemedText {
                    text: MediaService.fmt(MediaService.position)
                    style: Theme.type.labelSmall
                    color: Theme.color.fgSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                ThemedText {
                    text: MediaService.length > 0 ? MediaService.fmt(MediaService.length) : "--:--"
                    style: Theme.type.labelSmall
                    color: Theme.color.fgSurfaceVariant
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.space.xxs
                spacing: Theme.space.xs

                MediaButton {
                    icon: "\ue045"
                    size: Theme.components.dp(44)
                    enabled: MediaService.canPrev
                    onClicked: MediaService.previous()
                }
                MediaButton {
                    icon: MediaService.playing ? "\ue034" : "\ue037"
                    variant: "filled"
                    size: Theme.components.dp(56)
                    morphed: MediaService.playing
                    enabled: MediaService.canToggle
                    onClicked: MediaService.togglePlay()
                }
                MediaButton {
                    icon: "\ue044"
                    size: Theme.components.dp(44)
                    enabled: MediaService.canNext
                    onClicked: MediaService.next()
                }
            }
        }
    }
}
