import "root:/theme"
import "root:/settings"
import "root:/services"
import "root:/media"
import "root:/modules/common"
import QtQuick

// MediaModule — M3 Expressive міні-плеєр у барі (MPRIS).
// Кільце прогресу з іконкою play/pause + «виконавець — назва».
// Клік: Play/Pause; правий клік: Next; середній: відкрити Media surface; колесо: prev/next.
// Ховається (BarModule.shown), якщо нічого не грає.
BarModule {
    id: root

    signal mediaRequested()

    readonly property bool hasMedia: MediaService.has && (MediaService.title.length > 0 || MediaService.playing)
    readonly property string displayTrack: MediaService.artist.length > 0
        ? (MediaService.artist + " — " + MediaService.title)
        : (MediaService.title || Lang.t("ui.media.title"))
    readonly property real ringSize: Math.max(Theme.components.dp(20), cross - Theme.space.md)

    shown: hasMedia
    animate: true
    contentW: Math.min(Theme.components.dp(240), stat.implicitWidth + Theme.space.sm * 2)
    contentH: ringSize + Theme.space.xs * 2 + Theme.space.sm

    // позиція в MPRIS сама не оновлюється
    Timer {
        interval: 500
        repeat: true
        running: root.visible && MediaService.playing
        onTriggered: MediaService.poll()
    }

    BarButton {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        pressScale: 0.96
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) MediaService.next()
            else if (mouse.button === Qt.MiddleButton) root.mediaRequested()
            else MediaService.togglePlay()
        }
        onWheeled: e => {
            if (e.angleDelta.y > 0) MediaService.previous()
            else MediaService.next()
        }

        BarRingStat {
            id: stat
            anchors.centerIn: parent
            vertical: root.vertical
            ringSize: root.ringSize
            value: MediaService.fraction
            glyph: MediaService.playing ? "\ue034" : "\ue037"
            text: root.hasMedia ? root.displayTrack : ""
            maxTextWidth: Theme.components.dp(160)
        }
    }
}
