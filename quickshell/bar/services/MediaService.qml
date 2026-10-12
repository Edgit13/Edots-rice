pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// MediaService — єдине джерело правди для всіх медіа-віджетів (MPRIS).
// Активний плеєр: вибраний вручну → той, що грає → перший із треком → перший.
Singleton {
    id: root

    property var manual: null                       // плеєр, вибраний користувачем (чіпи у MediaTab)

    readonly property var players: Mpris.players.values
    readonly property var player: {
        const l = players
        if (!l || l.length === 0) return null
        if (manual && l.indexOf(manual) >= 0) return manual
        for (let i = 0; i < l.length; i++)
            if (l[i].playbackState === MprisPlaybackState.Playing) return l[i]
        for (let i = 0; i < l.length; i++)
            if (l[i].trackTitle) return l[i]
        return l[0]
    }

    readonly property bool has: player !== null
    readonly property bool playing: !!player && player.playbackState === MprisPlaybackState.Playing

    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    readonly property string identity: player ? (player.identity || "") : ""

    // секунди
    readonly property real length: (player && player.lengthSupported) ? player.length : 0
    readonly property real position: (player && player.positionSupported) ? player.position : 0
    readonly property real fraction: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    readonly property bool canPrev: !!player && !!player.canGoPrevious
    readonly property bool canNext: !!player && !!player.canGoNext
    readonly property bool canToggle: !!player && !!player.canTogglePlaying
    readonly property bool canSeek: !!player && !!player.canSeek && length > 0

    readonly property bool shuffleSupported: !!player && !!player.shuffleSupported
    readonly property bool shuffle: !!player && !!player.shuffle
    readonly property bool loopSupported: !!player && !!player.loopSupported
    readonly property bool loopOn: !!player && player.loopState !== MprisLoopState.None
    readonly property bool loopTrack: !!player && player.loopState === MprisLoopState.Track

    // ---- дії ----
    function togglePlay() {
        if (!player) return
        if (playing) player.pause()
        else player.play()
    }
    function previous() { if (canPrev) player.previous() }
    function next() { if (canNext) player.next() }
    function seek(fraction) {
        if (!canSeek) return
        player.position = Math.max(0, Math.min(1, fraction)) * length
    }
    function toggleShuffle() { if (shuffleSupported) player.shuffle = !player.shuffle }
    function cycleLoop() {
        if (!loopSupported) return
        const s = player.loopState
        player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
                         : s === MprisLoopState.Playlist ? MprisLoopState.Track
                         : MprisLoopState.None
    }
    // MPRIS не повідомляє позицію сам — смикаємо сигнал, поки щось видиме
    function poll() { if (player) player.positionChanged() }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) sec = 0
        const s = Math.floor(sec)
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const ss = String(s % 60).padStart(2, "0")
        return h > 0 ? (h + ":" + String(m).padStart(2, "0") + ":" + ss) : (m + ":" + ss)
    }
}
