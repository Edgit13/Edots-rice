pragma Singleton
import "root:/settings"
import Quickshell
import Quickshell.Io
import QtQuick

// RecordService — запис екрана. Сам запис робить scripts/screenrec.sh (wf-recorder, живе незалежно від shell);
// тут: стан для бару (таймер), запуск/зупинка, конфіг із Settings → Запис екрана.
Singleton {
    id: root

    readonly property string cache: Quickshell.env("HOME") + "/.cache/quickshell"
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/screenrec.sh"

    property bool recording: false
    property real startEpoch: 0
    property string file: ""
    property int elapsed: 0
    readonly property string elapsedText: {
        const s = Math.max(0, elapsed)
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), ss = s % 60
        const p = n => (n < 10 ? "0" : "") + n
        return h > 0 ? (h + ":" + p(m) + ":" + p(ss)) : (p(m) + ":" + p(ss))
    }

    // ---- налаштування ----
    readonly property string optAudio:   String(Settings.get("record", "audio") || "system")
    readonly property int    optFps:     Math.round(Number(Settings.get("record", "fps") ?? 30))
    readonly property string optEncoder: String(Settings.get("record", "encoder") || "software")
    readonly property string optDir:     String(Settings.get("record", "dir") || "~/Videos/Recordings")
    readonly property bool   optNotify:  Settings.get("record", "notify") !== false

    // ---- керування ----
    function start(geometry, output, delay) {
        const a = ["bash", script, "start", "--audio", optAudio, "--fps", String(optFps), "--encoder", optEncoder]
        if (geometry && geometry.length > 0) a.push("--geometry", geometry)
        else if (output && output.length > 0) a.push("--output", output)
        if (delay > 0) a.push("--delay", String(delay))
        Quickshell.execDetached(a)
        refresh.restart()
    }
    function stop()   { Quickshell.execDetached(["bash", script, "stop"]); refresh.restart() }
    function toggle() { recording ? stop() : start("", "", 0) }
    function ensure() { Quickshell.execDetached(["bash", script, "status"]); writeConf() }   // зі ShellNext: прибирає застарілий стан

    // ---- стан-файл (опитуємо раз на секунду: простіше й надійніше за inotify на файл, що зникає) ----
    FileView {
        id: stateFile
        path: root.cache + "/screenrec.state"
        printErrors: false
        onLoaded: root._parse(text())
        onLoadFailed: root._clear()
    }
    Timer { id: refresh; interval: 900; onTriggered: stateFile.reload() }
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (root.recording) root.elapsed = Math.max(0, Math.floor(Date.now() / 1000 - root.startEpoch))
            stateFile.reload()
        }
    }

    function _parse(t) {
        let pid = 0, start = 0, f = ""
        const lines = t.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const kv = lines[i].split("=")
            if (kv[0] === "pid") pid = parseInt(kv[1])
            else if (kv[0] === "start") start = parseInt(kv[1])
            else if (kv[0] === "file") f = kv.slice(1).join("=")
        }
        if (pid > 0 && start > 0) {
            startEpoch = start; file = f; recording = true
            elapsed = Math.max(0, Math.floor(Date.now() / 1000 - start))
        } else _clear()
    }
    function _clear() { recording = false; file = ""; elapsed = 0 }

    // ---- конфіг для скрипта ----
    function _q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    Process { id: writer }
    function writeConf() {
        const c =
            "AUDIO="   + _q(optAudio)   + "\n" +
            "FPS="     + optFps         + "\n" +
            "ENCODER=" + _q(optEncoder) + "\n" +
            "DIR="     + _q(optDir)     + "\n" +
            "NOTIFY="  + (optNotify ? "1" : "0") + "\n" +
            "MSG_DONE="    + _q(Lang.t("ui.rec.done"))    + "\n" +
            "MSG_FAIL="    + _q(Lang.t("ui.rec.fail"))    + "\n" +
            "MSG_SOON="    + _q(Lang.t("ui.rec.soon"))    + "\n" +
            "MSG_MISSING=" + _q(Lang.t("ui.rec.missing")) + "\n" +
            "LBL_OPEN="    + _q(Lang.t("ui.rec.open"))    + "\n" +
            "LBL_FOLDER="  + _q(Lang.t("ui.rec.folder"))  + "\n" +
            "LBL_COPY="    + _q(Lang.t("ui.rec.copy"))    + "\n"
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf %s "$2" > "$1"', "sh", cache + "/screenrec.conf", c]
        writer.running = true
    }
    Connections {
        target: Settings
        function onChanged(cat, key, value) { if (cat === "record") root.writeConf() }
    }
}
