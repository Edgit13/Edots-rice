pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// TimerService — міст між `utimer` (фонові таймери/нагадування на дату й час) та інтерфейсом.
// Читає ~/.local/state/edots/timers.jsonl (його веде сам utimer), тож таймери бачать і календар, і планувальник,
// і Task Manager. Створення/скасування — через CLI `utimer`.
//   timers : [{ id, at (мс), message, state: "pending" | "ringing" }]  за зростанням at
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/edots"
    readonly property string file: dir + "/timers.jsonl"

    property var timers: []
    readonly property var next: timers.length > 0 ? timers[0] : null

    // "YYYY-MM-DD" → кількість таймерів (для крапок у календарі)
    readonly property var dayMap: {
        const m = {}
        for (let i = 0; i < timers.length; i++) {
            const k = ymd(timers[i].at)
            m[k] = (m[k] || 0) + 1
        }
        return m
    }

    function _pad(n) { return (n < 10 ? "0" : "") + n }
    function ymd(ms) { const d = new Date(ms); return d.getFullYear() + "-" + _pad(d.getMonth() + 1) + "-" + _pad(d.getDate()) }
    function hm(ms)  { const d = new Date(ms); return _pad(d.getHours()) + ":" + _pad(d.getMinutes()) }
    function short(ms) { const d = new Date(ms); return _pad(d.getDate()) + "." + _pad(d.getMonth() + 1) + " " + hm(ms) }

    // таймери вибраного дня; без дня — найближчі `limit`
    function listFor(day, limit) {
        if (day) return timers.filter(t => ymd(t.at) === day)
        return timers.slice(0, limit || 3)
    }

    // ---- створення ----
    // args: аргументи для utimer після "start", напр. ["10m"] або ["10.26.2026", "13:00"]
    property var _queue: []
    function schedule(args, message, cb) {
        _queue.push({ args: args, message: message || "", cb: cb })
        _pump()
    }
    // ymdStr "YYYY-MM-DD", time "HH:MM" → utimer start MM.DD.YYYY HH:MM
    function scheduleAt(ymdStr, time, message, cb) {
        const p = String(ymdStr).split("-")
        if (p.length !== 3) { if (cb) cb(""); return }
        schedule([p[1] + "." + p[2] + "." + p[0], time], message, cb)
    }
    function cancel(id) {
        if (!id) return
        _queue.push({ cancel: id })
        _pump()
    }
    function ensure() {}
    function restore() { _queue.push({ restore: true }); _pump() }
    function reload() { poll.restart() }

    property var _cur: null
    function _pump() {
        if (runner.running || _queue.length === 0) return
        _cur = _queue.shift()
        const c = _cur
        if (c.cancel)       runner.command = ["utimer", "cancel", c.cancel]
        else if (c.restore) runner.command = ["utimer", "restore"]
        else {
            const cmd = ["utimer", "start"].concat(c.args)
            if (c.message.length > 0) cmd.push(c.message)
            runner.command = cmd
        }
        runner.running = true
    }

    Process {
        id: runner
        stdout: StdioCollector {
            id: out
            onStreamFinished: {
                const c = root._cur
                if (c && c.cb) {
                    const m = /id=([0-9a-f]+)/.exec(text)
                    c.cb(m ? m[1] : "")
                }
            }
        }
        onExited: { root._cur = null; root._pump(); poll.restart() }
    }

    // ---- файл ----
    Timer { id: poll; interval: 400; onTriggered: reader.reload() }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: reader.reload() }

    FileView {
        id: reader
        path: root.file
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root._load(text())
    }

    function _load(t) {
        const out = []
        const lines = String(t).split("\n")
        for (let i = 0; i < lines.length; i++) {
            const l = lines[i].trim()
            if (l.length === 0) continue
            try {
                const o = JSON.parse(l)
                if (o && o.id && o.at) out.push({ id: o.id, at: o.at * 1000, message: o.message || "", state: o.state || "pending" })
            } catch (e) {}
        }
        out.sort((a, b) => a.at - b.at)
        timers = out
    }

    // після входу: заново запустити очікування таймерів (і подзвонити про пропущені)
    Component.onCompleted: restore()
}
