pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell
import Quickshell.Io

// BarConfig — налаштування бару (позиція/режим/тінь), глобальні + override per monitor.
// Persist: ~/.config/quickshell/bar.json (live-watch). Stage 16 Settings UI викликає set()/setMonitor().
Singleton {
    id: root

    readonly property var positions: ["top", "bottom", "left", "right"]
    readonly property var modes: ["compact", "expanded", "morphing"]

    readonly property string position: _valid(a.position, positions, "top")
    readonly property string mode: _valid(a.mode, modes, "compact")
    readonly property int elevation: Math.max(0, Math.min(5, Math.round(a.elevation)))
    readonly property var perMonitor: (a.perMonitor && typeof a.perMonitor === "object") ? a.perMonitor : ({})

    function _valid(v, list, fb) { return list.indexOf(v) >= 0 ? v : fb }
    function _mon(name) { return perMonitor[name] || ({}) }

    function positionFor(name) { return _valid(_mon(name).position, positions, position) }
    function modeFor(name) { return _valid(_mon(name).mode, modes, mode) }

    // compact/morphing: тонкий island; expanded: вища смуга
    function thicknessFor(name) {
        return modeFor(name) === "expanded" ? Theme.components.islandExpressive : Theme.components.islandCompact
    }

    function set(key, value) {
        if (key === "position" && positions.indexOf(value) < 0) return console.warn("[Bar] position: " + positions.join("|"))
        if (key === "mode" && modes.indexOf(value) < 0) return console.warn("[Bar] mode: " + modes.join("|"))
        if (typeof a[key] === "undefined") return console.warn("[Bar] unknown setting: " + key)
        a[key] = value
    }

    // value === "" → прибрати override (повернутись до глобального)
    function setMonitor(name, key, value) {
        const next = JSON.parse(JSON.stringify(perMonitor))
        const cur = next[name] || {}
        if (value === "") delete cur[key]; else cur[key] = value
        if (Object.keys(cur).length === 0) delete next[name]; else next[name] = cur
        a.perMonitor = next
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/bar.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        adapter: JsonAdapter {
            id: a
            property string position: "top"
            property string mode: "compact"
            property real elevation: 1
            property var perMonitor: ({})
        }
    }
}
