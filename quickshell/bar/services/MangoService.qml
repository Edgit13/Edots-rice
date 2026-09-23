pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// MangoService — єдина точка інтеграції з MangoWM (mmsg). Нічого не вгадує:
//   • backend визначається пробою `mmsg get version`
//       – відповідь є  → "json"   (новий mmsg: get / watch / dispatch)
//       – помилка      → "legacy" (старий mmsg: -g / -w / -s, формат описаний у документації)
//   • EDOTS_MOCK_MANGO=1 → "mock" (фейкові теги для перевірки UI без compositor'а)
//   • json: потік `mmsg watch all-tags` читається й логуються сирі дані; мапінг полів додається
//     після tools/mango-probe.sh (схему JSON в документації не описано).
//
// Модель (нормалізована, backend-незалежна):
//   tagCount(mon) → int,  tag(mon, i) → { index, active, occupied, urgent, clients },  activeIndex(mon)
Singleton {
    id: root

    property string backend: "detecting"      // detecting | legacy | json | mock | none
    property var monitors: ({})               // { name: { count, tags: [ {index,active,occupied,urgent,clients} ] } }
    readonly property int defaultTags: 9
    readonly property bool mock: Quickshell.env("EDOTS_MOCK_MANGO") === "1"
    readonly property bool debug: Quickshell.env("EDOTS_BAR_DEBUG") === "1"

    // ---------- публічний API ----------
    function tagCount(mon) { const m = monitors[mon]; return m ? m.count : defaultTags }
    function tag(mon, i) {
        const m = monitors[mon]
        const t = m ? m.tags[i - 1] : undefined
        return t ? t : { index: i, active: false, occupied: false, urgent: false, clients: 0 }
    }
    function activeIndex(mon) {
        const m = monitors[mon]
        if (!m) return 0
        for (let i = 0; i < m.tags.length; i++) if (m.tags[i].active) return m.tags[i].index
        return 0
    }
    // Перемкнути тег на моніторі: legacy `-o <mon> -s -t N`,
    // json — один перевірений виклик `dispatch viewcrossmon,<tag>,<monitor_spec>`
    // (wiki/keys: "viewcrossmon | tag,monitor_spec | View specified tag on specified monitor.")
    function switchTag(mon, i) {
        if (backend === "mock") { _mockSwitch(mon, i); return }
        if (backend === "legacy") Quickshell.execDetached(["mmsg", "-o", mon, "-s", "-t", String(i)])
        else if (backend === "json") Quickshell.execDetached(["mmsg", "dispatch", "viewcrossmon," + i + "," + mon])
    }
    // Крок вперед/назад по тегах (без невідомих команд: рахуємо з активного індексу)
    function stepTag(mon, delta) {
        const cur = activeIndex(mon) || 1
        const next = Math.max(1, Math.min(tagCount(mon), cur + delta))
        if (next !== cur) switchTag(mon, next)
    }

    // Дії над активним клієнтом
    function closeFocusedClient() {
        if (backend === "json") Quickshell.execDetached(["mmsg", "dispatch", "killclient"])
    }
    function toggleFloatingFocusedClient() {
        if (backend === "json") Quickshell.execDetached(["mmsg", "dispatch", "togglefloating"])
    }

    property var focusedClient: ({ id: null, title: "", appid: "", monitor: "", fullscreen: false, floating: false })

    // ---------- внутрішній стан ----------
    property var _work: ({})
    property bool _dirty: false
    function _commit() {
        _dirty = false
        monitors = Object.assign({}, _work)
    }
    function _touch() { if (!_dirty) { _dirty = true; Qt.callLater(_commit) } }

    function _ensure(mon) {
        if (!_work[mon]) _work[mon] = { count: 0, tags: [] }
        return _work[mon]
    }

    // legacy: `<mon> tag N state clients focused`  |  `<mon> tags occ sel urg` (decimal; binary-варіант ігноруємо)
    function _legacyLine(line) {
        const t = String(line).trim().split(/\s+/)
        if (t.length < 5) return
        const mon = t[0]
        if (t[1] === "tag" && t.length >= 6) {
            const idx = parseInt(t[2]), st = parseInt(t[3]), cl = parseInt(t[4])
            if (isNaN(idx) || isNaN(st)) return
            const m = _ensure(mon)
            m.tags[idx - 1] = { index: idx, active: st === 1, urgent: st === 2, occupied: cl > 0, clients: isNaN(cl) ? 0 : cl }
            for (let i = 0; i < m.tags.length; i++) if (!m.tags[i]) m.tags[i] = { index: i + 1, active: false, occupied: false, urgent: false, clients: 0 }
            m.count = Math.max(m.count, idx)
            _touch()
        } else if (t[1] === "tags" && /^\d+$/.test(t[2]) && t[2].length < 9) {
            // маски: occupied selected urgent — уточнюють стан, якщо рядки `tag` не прийшли
            const occ = parseInt(t[2]), sel = parseInt(t[3]), urg = parseInt(t[4])
            const m = _ensure(mon)
            const n = Math.max(m.count, root.defaultTags)
            for (let i = 0; i < n; i++) {
                const bit = 1 << i
                const prev = m.tags[i]
                m.tags[i] = { index: i + 1, active: !!(sel & bit), urgent: !!(urg & bit), occupied: !!(occ & bit), clients: prev ? prev.clients : 0 }
            }
            m.count = n
            _touch()
        }
    }

    // json: буфер (потік може бути багаторядковий) → JSON.parse → _applyJson
    property string _buf: ""
    function _jsonLine(line) {
        _buf += line + "\n"
        let obj
        try { obj = JSON.parse(_buf) } catch (e) { if (_buf.length > 400000) _buf = ""; return }
        _buf = ""
        _applyJson(obj)
    }

    function _applyJson(obj) {
        if (!obj) return
        if (Array.isArray(obj.all_tags)) {
            for (let i = 0; i < obj.all_tags.length; i++) {
                const item = obj.all_tags[i]
                if (item && item.monitor && Array.isArray(item.tags)) {
                    _applyMonitorTags(item.monitor, item.tags)
                }
            }
        } else if (obj.monitor && Array.isArray(obj.tags)) {
            _applyMonitorTags(obj.monitor, obj.tags)
        }
    }

    function _applyMonitorTags(monName, tagList) {
        const m = _ensure(monName)
        m.count = tagList.length
        m.tags = []
        for (let i = 0; i < tagList.length; i++) {
            const t = tagList[i]
            m.tags.push({
                index: t.index !== undefined ? t.index : (i + 1),
                active: !!t.is_active,
                urgent: !!t.is_urgent,
                occupied: (t.client_count > 0),
                clients: isNaN(t.client_count) ? 0 : t.client_count,
                layout: t.layout || ""
            })
        }
        _touch()
    }

    function _applyClient(line) {
        if (!line || !line.trim()) return
        try {
            const obj = JSON.parse(line)
            if (obj && typeof obj === "object") {
                focusedClient = {
                    id: (obj.id !== undefined && obj.id !== null) ? obj.id : null,
                    title: obj.title || "",
                    appid: obj.appid || "",
                    monitor: obj.monitor || "",
                    fullscreen: !!obj.is_fullscreen,
                    floating: !!obj.is_floating
                }
            }
        } catch (e) {}
    }

    // ---------- mock ----------
    function _initMock() {
        backend = "mock"
        const names = []
        for (let i = 0; i < Quickshell.screens.length; i++) names.push(Quickshell.screens[i].name)
        const w = {}
        for (const n of names) {
            const tags = []
            for (let i = 1; i <= defaultTags; i++)
                tags.push({ index: i, active: i === 1, occupied: i === 1 || i === 2 || i === 4, urgent: i === 6, clients: (i === 1 ? 2 : (i === 2 || i === 4 ? 1 : 0)) })
            w[n] = { count: defaultTags, tags: tags }
        }
        _work = w
        _commit()
    }
    function _mockSwitch(mon, i) {
        const m = _work[mon]
        if (!m) return
        for (let k = 0; k < m.tags.length; k++) {
            m.tags[k].active = m.tags[k].index === i
            if (m.tags[k].index === i) m.tags[k].urgent = false
        }
        _touch()
    }

    // ---------- backend detection ----------
    Component.onCompleted: {
        if (mock) _initMock()
        else probe.running = true
    }
    Timer {
        id: probeTimeout
        interval: 4000
        running: root.backend === "detecting" && !root.mock
        onTriggered: { if (root.backend === "detecting") root.backend = "none" }
    }
    Process {
        id: probe
        command: ["mmsg", "get", "version"]
        stdout: StdioCollector { id: probeOut }
        onExited: function (exitCode) {
            if (exitCode === 0 && probeOut.text.trim().length > 0) root.backend = "json"
            else root.backend = "legacy"
            console.log("[Mango] backend=" + root.backend + (exitCode === 0 ? " version=" + probeOut.text.trim() : ""))
        }
    }

    // legacy: початковий дамп + потік
    Process {
        command: ["mmsg", "-g", "-t"]
        running: root.backend === "legacy"
        stdout: SplitParser { onRead: function (line) { root._legacyLine(line) } }
    }
    Process {
        command: ["mmsg", "-w", "-t"]
        running: root.backend === "legacy"
        stdout: SplitParser { onRead: function (line) { root._legacyLine(line) } }
    }
    // json
    Process {
        command: ["mmsg", "get", "all-tags"]
        running: root.backend === "json"
        stdout: SplitParser { onRead: function (line) { root._jsonLine(line) } }
    }
    Process {
        command: ["mmsg", "watch", "all-tags"]
        running: root.backend === "json"
        stdout: SplitParser { onRead: function (line) { root._jsonLine(line) } }
    }
    Process {
        command: ["mmsg", "get", "focusing-client"]
        running: root.backend === "json"
        stdout: SplitParser { onRead: function (line) { root._applyClient(line) } }
    }
    Process {
        command: ["mmsg", "watch", "focusing-client"]
        running: root.backend === "json"
        stdout: SplitParser { onRead: function (line) { root._applyClient(line) } }
    }
}
