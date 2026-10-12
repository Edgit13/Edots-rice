pragma Singleton
import "root:/settings"
import "root:/theme"
import Quickshell
import QtQuick

// BarConfig — тонкий фасад над Settings (категорії "bar", "modules").
Singleton {
    id: root

    readonly property var positions: ["top", "bottom", "left", "right"]
    readonly property var modes: ["compact", "expanded", "morphing"]

    readonly property string position: _valid(Settings.get("bar", "position"), positions, "top")
    readonly property string mode:     _valid(Settings.get("bar", "mode"), modes, "compact")
    readonly property int elevation:   Math.max(0, Math.min(5, Math.round(Settings.get("bar", "elevation"))))
    readonly property var perMonitor:  Settings.get("bar", "perMonitor") || ({})
    readonly property string mainMonitor: Settings.get("bar", "mainMonitor") || ""

    function _valid(v, list, fb) { return list.indexOf(v) >= 0 ? v : fb }
    function _mon(name) { return perMonitor[name] || ({}) }

    function positionFor(name) { return _valid(_mon(name).position, positions, position) }
    function modeFor(name)     { return _valid(_mon(name).mode, modes, mode) }

    function thicknessFor(name) {
        return modeFor(name) === "expanded" ? Theme.components.islandExpressive : Theme.components.islandCompact
    }

    function set(key, value) {
        if (key === "position" && positions.indexOf(value) < 0) return console.warn("[Bar] position: " + positions.join("|"))
        if (key === "mode" && modes.indexOf(value) < 0) return console.warn("[Bar] mode: " + modes.join("|"))
        Settings.set("bar", key, value)
    }

    function setMonitor(name, key, value) {
        const next = JSON.parse(JSON.stringify(perMonitor))
        const cur = next[name] || {}
        if (value === "") delete cur[key]; else cur[key] = value
        if (Object.keys(cur).length === 0) delete next[name]; else next[name] = cur
        Settings.set("bar", "perMonitor", next)
    }
}
