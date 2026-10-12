import "root:/theme"
import "root:/services"
import "root:/media"
import QtQuick
import QtQuick.Layouts

// MiniMediaCard — компактний плеєр для сітки на вкладці "Огляд" (смуга на всю ширину).
DashCard {
    id: root

    implicitHeight: 240

    // ---- порожній стан ----
    RowLayout {
        anchors.centerIn: parent
        visible: !MediaService.has
        spacing: Theme.space.sm
        Text {
            text: "\ue405"
            font { family: Theme.type.icons; pixelSize: Theme.type.iconL }
            color: Theme.color.fgSurfaceVariant
        }
        ThemedText {
            text: "Нічого не грає"
            style: Theme.type.bodyLarge
            color: Theme.color.fgSurfaceVariant
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: MediaService.has
        spacing: Theme.space.lg

        MediaArt {
            Layout.preferredWidth: Math.min(Theme.components.dp(152), root.height - Theme.space.lg * 2)
            Layout.preferredHeight: Layout.preferredWidth
            Layout.alignment: Qt.AlignVCenter
            source: MediaService.artUrl
            playing: MediaService.playing
            morphOnPause: true
            baseRadius: Theme.shape.card
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            ThemedText {
                text: MediaService.identity
                style: Theme.type.labelSmall
                color: Theme.color.primary
            }
            ThemedText {
                Layout.fillWidth: true
                text: MediaService.title || "Без назви"
                style: Theme.type.titleMedium
                emphasized: true
                elide: Text.ElideRight
            }
            ThemedText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: MediaService.artist
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
                elide: Text.ElideRight
            }

            MediaProgress {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.sm
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
                spacing: Theme.space.xs
                MediaButton {
                    icon: "\ue045"
                    size: Theme.components.dp(40)
                    enabled: MediaService.canPrev
                    onClicked: MediaService.previous()
                }
                MediaButton {
                    icon: MediaService.playing ? "\ue034" : "\ue037"
                    variant: "filled"
                    size: Theme.components.dp(52)
                    morphed: MediaService.playing
                    enabled: MediaService.canToggle
                    onClicked: MediaService.togglePlay()
                }
                MediaButton {
                    icon: "\ue044"
                    size: Theme.components.dp(40)
                    enabled: MediaService.canNext
                    onClicked: MediaService.next()
                }
            }
        }
    }
}
