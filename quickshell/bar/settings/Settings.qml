pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Settings.qml — єдиний кор для всіх розділених JSON-файлів.
Singleton {
    id: root

    readonly property string base: Quickshell.env("HOME") + "/.config/quickshell/"

    property var data: ({})
    property var _raw: ({})
    property bool loaded: false
    signal changed(string cat, string key, var value)

    FileView { path: root.base + "general.json";    watchChanges: true; printErrors: false
               onFileChanged: reload(); onTextChanged: root._onFile("general.json", text()) }
    FileView { path: root.base + "theme.json";      watchChanges: true; printErrors: false
               onFileChanged: reload(); onTextChanged: root._onFile("theme.json", text()) }
    FileView { path: root.base + "bar.json";        watchChanges: true; printErrors: false
               onFileChanged: reload(); onTextChanged: root._onFile("bar.json", text()) }
    FileView { path: root.base + "clock.json";      watchChanges: true; printErrors: false
               onFileChanged: reload(); onTextChanged: root._onFile("clock.json", text()) }
    FileView { path: root.base + "lockscreen.json"; watchChanges: true; printErrors: false
               onFileChanged: reload(); onTextChanged: root._onFile("lockscreen.json", text()) }
    FileView { path: root.base + "colors.json";     watchChanges: true; printErrors: false
               onFileChanged: reload(); onTextChanged: root._onFile("colors.json", text()) }

    FileView { id: wGeneral; path: root.base + "general.json";   atomicWrites: true; printErrors: false }
    FileView { id: wTheme;  path: root.base + "theme.json";      atomicWrites: true; printErrors: false }
    FileView { id: wBar;    path: root.base + "bar.json";        atomicWrites: true; printErrors: false }
    FileView { id: wClock;  path: root.base + "clock.json";      atomicWrites: true; printErrors: false }
    FileView { id: wLock;   path: root.base + "lockscreen.json"; atomicWrites: true; printErrors: false }
    FileView { id: wColors; path: root.base + "colors.json";     atomicWrites: true; printErrors: false }

    function _writer(file) {
        switch (file) {
        case "general.json":    return wGeneral
        case "theme.json":      return wTheme
        case "bar.json":        return wBar
        case "clock.json":      return wClock
        case "lockscreen.json": return wLock
        case "colors.json":     return wColors
        }
        return null
    }

    function _getPath(obj, path) {
        var parts = path.split(".")
        var cur = obj
        for (var i = 0; i < parts.length; i++) {
            if (cur === undefined || cur === null) return undefined
            cur = cur[parts[i]]
        }
        return cur
    }
    function _setPath(obj, path, value) {
        var parts = path.split(".")
        var cur = obj
        for (var i = 0; i < parts.length - 1; i++) {
            if (typeof cur[parts[i]] !== "object" || cur[parts[i]] === null) cur[parts[i]] = {}
            cur = cur[parts[i]]
        }
        cur[parts[parts.length - 1]] = value
    }

    function _onFile(name, text) {
        var parsed = {}
        if (text && text.trim().length > 0) {
            try { parsed = JSON.parse(text) }
            catch (e) { console.warn("[Settings] parse", name, e); return }
        }
        var raw = Object.assign({}, root._raw)
        raw[name] = parsed
        root._raw = raw
        root._rebuild()
    }

    function _rebuild() {
        var merged = {}
        for (var cat in Schema.schema) {
            var cs = Schema.schema[cat]
            if (!cs.fields) continue
            merged[cat] = {}
            var fileData = root._raw[cs.file] || {}
            for (var key in cs.fields) {
                var f = cs.fields[key]
                var v = _getPath(fileData, f.path || key)
                merged[cat][key] = (v === undefined) ? f.default : _clamp(f, v)
            }
        }
        root.data = merged
        root.loaded = true
    }

    function _clamp(f, v) {
        switch (f.type) {
        case "bool":  return !!v
        case "num": {
            if (f.nullable && (v === null || v === undefined)) return null
            var n = Number(v)
            if (isNaN(n)) return f.default
            if (f.min !== undefined) n = Math.max(f.min, n)
            if (f.max !== undefined) n = Math.min(f.max, n)
            return n
        }
        case "enum":  return f.options.indexOf(v) >= 0 ? v : f.default
        case "str":   return String(v)
        case "color": return (typeof v === "string" && /^#[0-9a-fA-F]{3,8}$/.test(v)) ? v : f.default
        case "arr":   return Array.isArray(v) ? v : f.default
        case "map":   return (v && typeof v === "object" && !Array.isArray(v)) ? v : f.default
        }
        return v
    }

    function get(cat, key) {
        if (root.data[cat] && root.data[cat][key] !== undefined) return root.data[cat][key]
        var s = Schema.schema[cat]
        return (s && s.fields && s.fields[key]) ? s.fields[key].default : undefined
    }
    function defaults(cat, key) {
        var s = Schema.schema[cat]
        return (s && s.fields && s.fields[key]) ? s.fields[key].default : undefined
    }
    function isDirty(cat, key) {
        return JSON.stringify(get(cat, key)) !== JSON.stringify(defaults(cat, key))
    }
    function schemaFor(cat, key) {
        var s = Schema.schema[cat]
        return (s && s.fields) ? (s.fields[key] || null) : null
    }

    function fieldsForPage(idx) {
        var p = Schema.pages[idx]
        if (!p) return []
        var out = []
        for (var ci = 0; ci < p.cats.length; ci++) {
            var cat = p.cats[ci]
            var cs = Schema.schema[cat]
            if (!cs || !cs.fields) continue
            for (var key in cs.fields) {
                var f = cs.fields[key]
                if (f.hidden) continue
                out.push({ cat: cat, key: key, field: f })
            }
        }
        return out
    }

    function sectionsForPage(idx) {
        var p = Schema.pages[idx]
        if (!p) return []
        var out = []
        for (var ci = 0; ci < p.cats.length; ci++) {
            var cat = p.cats[ci]
            var cs = Schema.schema[cat]
            if (!cs || !cs.fields) continue
            var fields = []
            for (var key in cs.fields) {
                var f = cs.fields[key]
                if (f.hidden) continue
                fields.push({ cat: cat, key: key, field: f })
            }
            if (fields.length > 0) out.push({ cat: cat, label: cs.label || cat, fields: fields })
        }
        return out
    }

    function set(cat, key, value) {
        var s = Schema.schema[cat]
        if (!s || !s.fields || !s.fields[key]) {
            console.warn("[Settings] unknown", cat + "." + key); return false
        }
        var v = _clamp(s.fields[key], value)
        var file = s.file
        var path = s.fields[key].path || key

        var raw = Object.assign({}, root._raw)
        var fileData = Object.assign({}, raw[file] || {})
        _setPath(fileData, path, v)
        raw[file] = fileData
        root._raw = raw

        var merged = Object.assign({}, root.data)
        var catObj = Object.assign({}, merged[cat] || {}, { [key]: v })
        merged[cat] = catObj
        root.data = merged

        var w = _writer(file)
        if (w) w.setText(JSON.stringify(fileData, null, 2))
        changed(cat, key, v)
        return true
    }

    function resetKey(cat, key) { return set(cat, key, defaults(cat, key)) }
    function resetCategory(cat) {
        var cs = Schema.schema[cat]
        if (!cs || !cs.fields) return false
        for (var k in cs.fields) set(cat, k, cs.fields[k].default)
        return true
    }
    function resetAll() {
        for (var cat in Schema.schema) resetCategory(cat)
        return true
    }

    Component.onCompleted: {
        wTheme.reload(); wBar.reload(); wClock.reload()
    }
}
