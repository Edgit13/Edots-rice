import "root:/theme"
import "root:/settings"
import "root:/services"
import "root:/media"
import QtQuick
import QtQuick.Layouts

// MediaTab — повний плеєр для дашборду (M3 Expressive, у дусі end-4):
// велика обкладинка з морфом, чіпи плеєрів, хвиляста шкала, shuffle/repeat + морф-кнопка play.
Item {
    id: root

    readonly property bool has: MediaService.has
    readonly property real artSide: Math.max(Theme.components.dp(160), Math.min(Theme.components.dp(300), root.height - Theme.space.lg * 2))

    component PlayerChip: Rectangle {
        id: chip
        property string label: ""
        property bool selected: false
        signal clicked()

        implicitHeight: Theme.components.chipHeight
        implicitWidth: chipText.implicitWidth + Theme.space.xl + Theme.space.xs
        radius: selected ? height / 2 : Theme.shape.chip           // форма морфиться при виборі
        color: selected && !Theme.settings.nothing ? Theme.color.secondaryContainer : "transparent"
        border.width: Theme.settings.nothing ? 1 : (selected ? 0 : 1)
        border.color: Theme.settings.nothing
            ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, selected ? 0.75 : 0.22)
            : Theme.color.outlineVariant
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "hover" } }

        ThemedText {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            style: Theme.type.labelLarge
            color: chip.selected ? (Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.fgSecondaryContainer) : Theme.color.fgSurfaceVariant
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    // ---- порожній стан ----
    ColumnLayout {
        anchors.centerIn: parent
        visible: !root.has
        spacing: Theme.space.sm
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\ue405"
            font { family: Theme.type.icons; pixelSize: Theme.type.iconXL * 1.5 }
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
        anchors.margins: Theme.space.lg
        visible: root.has
        spacing: Theme.space.lg * 2

        MediaArt {
            Layout.preferredWidth: root.artSide
            Layout.preferredHeight: root.artSide
            Layout.alignment: Qt.AlignVCenter
            source: MediaService.artUrl
            playing: MediaService.playing
            morphOnPause: true
            iconSize: Theme.type.iconXL * 1.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Theme.space.md

            // чіпи плеєрів (якщо їх кілька) або просто назва джерела
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.xs
                visible: MediaService.players.length > 1
                Repeater {
                    model: MediaService.players
                    PlayerChip {
                        required property var modelData
                        label: modelData.identity || Lang.t("ui.media.player")
                        selected: modelData === MediaService.player
                        onClicked: MediaService.manual = modelData
                    }
                }
                Item { Layout.fillWidth: true }
            }
            ThemedText {
                visible: MediaService.players.length <= 1
                text: MediaService.identity
                style: Theme.type.labelMedium
                color: Theme.color.primary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                ThemedText {
                    Layout.fillWidth: true
                    text: MediaService.title || Lang.t("ui.media.unknown")
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
                ThemedText {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: MediaService.album
                    style: Theme.type.labelSmall
                    color: Theme.color.outline
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.sm
                spacing: 0

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
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Theme.space.xs
                spacing: Theme.space.sm

                MediaButton {
                    icon: "\ue043"
                    variant: "toggle"
                    size: Theme.components.dp(40)
                    toggled: MediaService.shuffle
                    enabled: MediaService.shuffleSupported
                    onClicked: MediaService.toggleShuffle()
                }
                MediaButton {
                    icon: "\ue045"
                    variant: "tonal"
                    size: Theme.components.dp(56)
                    enabled: MediaService.canPrev
                    onClicked: MediaService.previous()
                }
                MediaButton {
                    icon: MediaService.playing ? "\ue034" : "\ue037"
                    variant: "filled"
                    size: Theme.components.dp(76)
                    morphed: MediaService.playing
                    enabled: MediaService.canToggle
                    onClicked: MediaService.togglePlay()
                }
                MediaButton {
                    icon: "\ue044"
                    variant: "tonal"
                    size: Theme.components.dp(56)
                    enabled: MediaService.canNext
                    onClicked: MediaService.next()
                }
                MediaButton {
                    icon: MediaService.loopTrack ? "\ue041" : "\ue040"
                    variant: "toggle"
                    size: Theme.components.dp(40)
                    toggled: MediaService.loopOn
                    enabled: MediaService.loopSupported
                    onClicked: MediaService.cycleLoop()
                }
            }
        }
    }
}
