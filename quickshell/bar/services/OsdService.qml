pragma Singleton
import "root:/settings"
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// OsdService — стежить за гучністю (Pipewire) і яскравістю (sysfs backlight) і показує OSD-пігулку.
// Реагує на будь-які зміни (клавіші, колесо в барі, mixer), тож нічого більше прив'язувати не треба.
// Для клавіш можна також смикати IPC:  qs -c <cfg> ipc call osd volumeUp   (див. ShellNext.qml)
Singleton {
    id: root

    // ---- стан для OsdWindow ----
    property string kind: "volume"       // volume | brightness
    property real value: 0               // volume: 0..1.5, brightness: 0..1
    property bool muted: false
    property bool shown: false
    signal pulse()

    // ---- налаштування (Settings → OSD) ----
    readonly property bool enabled:      Settings.get("osd", "enabled") !== false
    readonly property bool showVolume:   Settings.get("osd", "volume") !== false
    readonly property bool showBright:   Settings.get("osd", "brightness") !== false
    readonly property string position:   String(Settings.get("osd", "position") || "bottom")
    readonly property real margin:       Number(Settings.get("osd", "margin") ?? 110)
    readonly property real size:         Number(Settings.get("osd", "size") ?? 1.0)
    readonly property int hideAfter:     Math.round(Number(Settings.get("osd", "duration") ?? 1.8) * 1000)

    // попередній перегляд при зміні налаштувань OSD
    Connections {
        target: Settings
        function onChanged(cat, key, value) {
            if (cat !== "osd" || key === "enabled") return
            root.preview()
        }
    }
    function preview() {
        kind = "volume"
        value = sinkVol >= 0 ? Math.min(1, sinkVol) : 0.6
        muted = false
        shown = true
        hideTimer.restart()
        pulse()
    }

    // ---- на якому екрані показувати: де сфокусоване вікно, інакше перший ----
    function isTarget(scr) {
        const m = MangoService.focusedClient ? MangoService.focusedClient.monitor : ""
        let found = false
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === m) found = true
        return found ? scr.name === m : scr === Quickshell.screens[0]
    }

    // не показуємо OSD на старті і одразу після зміни пристрою
    property bool armed: false
    Timer { id: armTimer; interval: 2000; running: true; onTriggered: root.armed = true }

    function present() {
        if (!armed || !enabled) return
        shown = true
        hideTimer.restart()
        pulse()
    }
    function hide() { shown = false }
    Timer { id: hideTimer; interval: root.hideAfter; onTriggered: root.shown = false }

    // =============== VOLUME ===============
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: !!sink && sink.ready && !!sink.audio
    readonly property real sinkVol: sinkReady ? sink.audio.volume : -1
    readonly property bool sinkMuted: sinkReady && sink.audio.muted

    PwObjectTracker { objects: [root.sink] }

    property real _lastVol: -1
    property bool _lastMuted: false

    onSinkChanged: { armed = false; _lastVol = -1; armTimer.restart() }

    onSinkVolChanged: {
        if (sinkVol < 0) return
        if (_lastVol < 0) { _lastVol = sinkVol; _lastMuted = sinkMuted; return }
        if (Math.abs(sinkVol - _lastVol) > 0.0005) {
            _lastVol = sinkVol
            _showVolume()
        }
    }
    onSinkMutedChanged: {
        if (_lastVol < 0 || sinkMuted === _lastMuted) return
        _lastMuted = sinkMuted
        _showVolume()
    }
    function _showVolume() {
        if (!showVolume) return
        kind = "volume"
        value = Math.max(0, sinkVol)
        muted = sinkMuted
        present()
    }

    function volumeStep(delta) {
        if (!sinkReady) return
        const a = sink.audio
        a.volume = Math.max(0, Math.min(1.5, a.volume + delta))
        if (a.muted && delta > 0) a.muted = false
    }
    function volumeMute() { if (sinkReady) sink.audio.muted = !sink.audio.muted }

    // =============== BRIGHTNESS ===============
    property string blDir: ""
    property real blMax: 0
    property real _lastBl: -1

    Process {
        command: ["sh", "-c", "ls -d /sys/class/backlight/* 2>/dev/null | head -n1"]
        running: true
        stdout: StdioCollector { onStreamFinished: root.blDir = text.trim() }
    }

    FileView {
        id: blMaxFile
        path: root.blDir.length > 0 ? root.blDir + "/max_brightness" : ""
        printErrors: false
        onLoaded: { root.blMax = parseInt(text()); blCur.reload() }
    }
    FileView {
        id: blCur
        path: root.blDir.length > 0 ? root.blDir + "/brightness" : ""
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._readBl()
    }
    // sysfs не завжди шле inotify при зміні — підстраховуємось легким опитуванням
    Timer {
        interval: 350
        repeat: true
        running: root.blDir.length > 0
        onTriggered: blCur.reload()
    }

    function _readBl() {
        const cur = parseInt(blCur.text())
        if (isNaN(cur) || blMax <= 0) return
        const v = Math.max(0, Math.min(1, cur / blMax))
        if (_lastBl < 0) { _lastBl = v; return }
        if (Math.abs(v - _lastBl) > 0.004) {
            _lastBl = v
            if (!showBright) return
            kind = "brightness"
            value = v
            muted = false
            present()
        }
    }

    Process { id: blSet }
    function brightnessStep(deltaPercent) {
        if (blDir.length === 0) return
        const n = Math.abs(deltaPercent) + "%"
        blSet.command = ["brightnessctl", "-c", "backlight", "set", deltaPercent > 0 ? ("+" + n) : (n + "-")]
        blSet.running = true
    }
}
