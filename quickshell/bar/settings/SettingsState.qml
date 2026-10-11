pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/quickshell"

    // ---- UI-facing schema (nested by category, keeps the pages simple) ----
    readonly property var schema: ({
        appearance: {
            mode:          { type: "enum", options: ["system","light","dark"], default: "dark" },
            dynamicColor:  { type: "bool", default: true },
            accent:        { type: "color", default: "#74e7c8" },
            cornerStyle:   { type: "enum", options: ["material","expressive","rounded"], default: "expressive" },
            uiScale:       { type: "num", min: 0.75, max: 1.5, step: 0.05, default: 1.0 }
        },
        animations: {
            enabled:          { type: "bool", default: true },
            expressiveMotion: { type: "bool", default: true },
            reduceMotion:     { type: "bool", default: false },
            globalSpeed:      { type: "num", min: 0.25, max: 3.0, step: 0.05, default: 1.0 }
        },
        bar: {
            position:    { type: "enum", options: ["top","bottom","left","right"], default: "top" },
            mode:        { type: "enum", options: ["compact","expanded","morphing"], default: "compact" },
            elevation:   { type: "num", min: 0, max: 5, step: 1, default: 1 },
            mainMonitor: { type: "str", default: "" }
        },
        modules: {
            order:         { type: "arr", default: ["workspaces","clock","launcher","window","media","mixer","wifi","notifications","battery","power"] },
            workspaces:    { type: "bool", default: true },
            clock:         { type: "bool", default: true },
            launcher:      { type: "bool", default: true },
            window:        { type: "bool", default: true },
            media:         { type: "bool", default: true },
            mixer:         { type: "bool", default: true },
            wifi:          { type: "bool", default: true },
            notifications: { type: "bool", default: true },
            battery:       { type: "bool", default: true },
            power:         { type: "bool", default: true }
        },
        lockscreen: {
            enabled:        { type: "bool", default: true },
            blurStrength:   { type: "num", min: 0, max: 1, step: 0.05, default: 0.35 },
            blurRadius:     { type: "num", min: 8, max: 128, step: 8, default: 32 },
            scrimOpacity:   { type: "num", min: 0, max: 1, step: 0.05, default: 0.55 },
            kenBurns:       { type: "bool", default: true },
            parallax:       { type: "bool", default: true },
            floatingShapes: { type: "bool", default: true },
            clockSize:      { type: "num", min: 60, max: 200, step: 4, default: 112 },
            greeting:       { type: "bool", default: true },
            passwordStyle:  { type: "enum", options: ["dots","shapes","text"], default: "shapes" },
            powerButtons:   { type: "bool", default: true },
            successFlash:   { type: "bool", default: true }
        },
        clock: {
            hour12:      { type: "bool", default: false },
            showSeconds: { type: "bool", default: false },
            dateFormat:  { type: "str", default: "d MMMM" }
        },
        colors: {
            bg0:    { type: "color", default: "#060f0c" },
            bg1:    { type: "color", default: "#0a1a16" },
            bg2:    { type: "color", default: "#0f2922" },
            bg3:    { type: "color", default: "#15372e" },
            bg4:    { type: "color", default: "#1c4a3d" },
            fg:     { type: "color", default: "#dae7e3" },
            grey1:  { type: "color", default: "#31816c" },
            grey2:  { type: "color", default: "#90d5c2" },
            accent: { type: "color", default: "#74e7c8" },
            red:    { type: "color", default: "#d27c79" },
            blue:   { type: "color", default: "#d27c79" },
            purple: { type: "color", default: "#d1df9f" }
        }
    })

    // ---- mapping (category.key) → (file, flatField) ----
    readonly property var map: ({
        "appearance.mode":             { file: "theme.json",  field: "mode" },
        "appearance.dynamicColor":     { file: "theme.json",  field: "dynamicColor" },
        "appearance.accent":           { file: "theme.json",  field: "accent" },
        "appearance.cornerStyle":      { file: "theme.json",  field: "cornerStyle" },
        "appearance.uiScale":          { file: "theme.json",  field: "uiScale" },
        "animations.enabled":          { file: "theme.json",  field: "animations" },
        "animations.expressiveMotion": { file: "theme.json",  field: "expressiveMotion" },
        "animations.reduceMotion":     { file: "theme.json",  field: "reduceMotion" },
        "animations.globalSpeed":      { file: "theme.json",  field: "animationSpeed" },
        "bar.position":    { file: "bar.json", field: "position" },
        "bar.mode":        { file: "bar.json", field: "mode" },
        "bar.elevation":   { file: "bar.json", field: "elevation" },
        "bar.mainMonitor": { file: "bar.json", field: "mainMonitor" },
        "clock.hour12":      { file: "clock.json", field: "hour12" },
        "clock.showSeconds": { file: "clock.json", field: "showSeconds" },
        "clock.dateFormat":  { file: "clock.json", field: "dateFormat" }
    })

    function _target(cat, key) {
        const direct = root.map[cat + "." + key]
        if (direct) return direct
        if (cat === "lockscreen") return { file: "lockscreen.json", field: key }
        if (cat === "colors")     return { file: "colors.json",     field: key }
        if (cat === "modules")    return { file: "settings.json",   field: "modules." + key }
        return null
    }

    property var files: ({
        "theme.json": ({}), "bar.json": ({}), "settings.json": ({}),
        "clock.json": ({}), "colors.json": ({}), "lockscreen.json": ({})
    })

    function _getField(file, field) {
        const f = root.files[file] || {}
        if (field.indexOf(".") < 0) return f[field]
        const parts = field.split(".")
        let cur = f
        for (let i = 0; i < parts.length; i++) {
            if (cur === undefined || cur === null) return undefined
            cur = cur[parts[i]]
        }
        return cur
    }

    function _setField(file, field, value) {
        const next = JSON.parse(JSON.stringify(root.files[file] || {}))
        if (field.indexOf(".") < 0) {
            next[field] = value
        } else {
            const parts = field.split(".")
            let cur = next
            for (let i = 0; i < parts.length - 1; i++) {
                if (typeof cur[parts[i]] !== "object" || cur[parts[i]] === null)
                    cur[parts[i]] = {}
                cur = cur[parts[i]]
            }
            cur[parts[parts.length - 1]] = value
        }
        const merged = Object.assign({}, root.files)
        merged[file] = next
        root.files = merged
    }

    function get(cat, key) {
        const t = root._target(cat, key)
        if (!t) return undefined
        const v = root._getField(t.file, t.field)
        if (v !== undefined) return v
        const s = root.schema[cat] && root.schema[cat][key]
        return s ? s.default : undefined
    }

    function set(cat, key, value) {
        const s = root.schema[cat] && root.schema[cat][key]
        if (!s) { console.warn("[Settings] unknown " + cat + "." + key); return false }
        let v = value
        if (s.type === "num") v = Math.max(s.min, Math.min(s.max, Number(v)))
        else if (s.type === "enum" && s.options.indexOf(v) < 0) return false
        else if (s.type === "bool") v = !!v
        const t = root._target(cat, key)
        if (!t) return false
        root._setField(t.file, t.field, v)
        root._save(t.file)
        return true
    }

    function isDirty(cat, key) {
        const s = root.schema[cat] && root.schema[cat][key]
        if (!s) return false
        return root.get(cat, key) !== s.default
    }
    function resetKey(cat, key) {
        const s = root.schema[cat] && root.schema[cat][key]
        if (!s) return false
        return root.set(cat, key, s.default)
    }
    function resetCategory(cat) {
        const sc = root.schema[cat] || {}
        for (const k in sc) if (sc[k] && sc[k].default !== undefined) root.set(cat, k, sc[k].default)
    }
    function resetAll() { for (const c in root.schema) root.resetCategory(c) }
    function moveModule(id, dir) {
        const order = (root.get("modules", "order") || []).slice()
        const i = order.indexOf(id); const j = i + dir
        if (i < 0 || j < 0 || j >= order.length) return
        const t = order[i]; order[i] = order[j]; order[j] = t
        root.set("modules", "order", order)
    }

    property var _saveTimers: ({})
    function _save(file) {
        const name = file.replace(/\.json$/, "")
        let t = root._saveTimers[name]
        if (!t) { t = timerComp.createObject(root, { file: file }); root._saveTimers[name] = t }
        t.restart()
    }
    Component {
        id: timerComp
        Timer {
            property string file: ""
            interval: 200
            repeat: false
            onTriggered: root._flush(file)
        }
    }

    function _flush(file) {
        const w = root.writers[file]
        if (!w) return
        w.setText(JSON.stringify(root.files[file] || {}, null, 2))
    }

    FileView { id: wTheme;      path: root.dir + "/theme.json";      watchChanges: false }
    FileView { id: wBar;        path: root.dir + "/bar.json";        watchChanges: false }
    FileView { id: wSettings;   path: root.dir + "/settings.json";   watchChanges: false }
    FileView { id: wClock;      path: root.dir + "/clock.json";      watchChanges: false }
    FileView { id: wColors;     path: root.dir + "/colors.json";     watchChanges: false }
    FileView { id: wLockscreen; path: root.dir + "/lockscreen.json"; watchChanges: false }

    readonly property var writers: ({
        "theme.json": wTheme, "bar.json": wBar, "settings.json": wSettings,
        "clock.json": wClock, "colors.json": wColors, "lockscreen.json": wLockscreen
    })

    function _load(file, text) {
        if (!text || text.trim().length === 0) return
        try {
            const d = JSON.parse(text)
            const merged = Object.assign({}, root.files)
            merged[file] = d
            root.files = merged
        } catch (e) { console.warn("[Settings] parse " + file + ": " + e) }
    }

    FileView {
        path: root.dir + "/theme.json"; watchChanges: true
        onFileChanged: reload(); onTextChanged: root._load("theme.json", text())
    }
    FileView {
        path: root.dir + "/bar.json"; watchChanges: true
        onFileChanged: reload(); onTextChanged: root._load("bar.json", text())
    }
    FileView {
        path: root.dir + "/settings.json"; watchChanges: true
        onFileChanged: reload(); onTextChanged: root._load("settings.json", text())
    }
    FileView {
        path: root.dir + "/clock.json"; watchChanges: true
        onFileChanged: reload(); onTextChanged: root._load("clock.json", text())
    }
    FileView {
        path: root.dir + "/colors.json"; watchChanges: true
        onFileChanged: reload(); onTextChanged: root._load("colors.json", text())
    }
    FileView {
        path: root.dir + "/lockscreen.json"; watchChanges: true; printErrors: false
        onFileChanged: reload(); onTextChanged: root._load("lockscreen.json", text())
    }
}
