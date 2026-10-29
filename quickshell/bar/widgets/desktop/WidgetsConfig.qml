pragma Singleton
import "root:/settings"
import "root:/theme"
import QtQuick
import Quickshell

// WidgetsConfig — фасад над Settings (категорія "widgets") + кольорові ролі віджетів за темою.
Singleton {
    id: root

    function _g(key) { return Settings.get("widgets", key) }

    readonly property bool enabled:      _g("enabled") !== false
    readonly property string monitor:    String(_g("monitor") || "")
    readonly property string anchor:     _g("anchor") || "top-right"
    readonly property string arrange:    _g("arrange") || "row"
    readonly property real margin:       Number(_g("margin") ?? 48)
    readonly property real spacing:      Number(_g("spacing") ?? 16)
    readonly property real scale:        Number(_g("scale") ?? 1)
    readonly property real opacity:      Number(_g("opacity") ?? 1)
    readonly property string colorStyle: _g("colorStyle") || "mixed"

    readonly property bool clockEnabled:   _g("clockEnabled") !== false
    readonly property string clockStyle:   _g("clockStyle") || "digital"
    readonly property string clockShape:   _g("clockShape") || "cookie"
    readonly property bool weatherEnabled: _g("weatherEnabled") !== false
    readonly property string weatherShape: _g("weatherShape") || "flower"
    readonly property bool mediaEnabled:   _g("mediaEnabled") !== false
    readonly property string mediaShape:   _g("mediaShape") || "pill"
    readonly property bool mediaHideIdle:  _g("mediaHideIdle") !== false
    readonly property bool resourcesEnabled: _g("resourcesEnabled") !== false
    readonly property string resourcesShape: _g("resourcesShape") || "sunny"
    readonly property string bgStyle:      _g("bgStyle") || "filled"
    readonly property real bgOpacity:      Number(_g("bgOpacity") ?? 1)

    // режим редагування (не зберігається): перетягування віджетів мишею
    readonly property bool editing: _g("edit") === true
    function setEditing(on) { Settings.set("widgets", "edit", !!on) }
    readonly property var kinds: ["clock", "weather", "media", "resources"]
    // без фону віджет лежить прямо на шпалерах — кольори ролей контейнера були б нечитні
    readonly property bool plain: bgStyle === "none" || bgStyle === "outline"

    function placementOf(kind) { return _g(kind + "Placement") === "free" ? "free" : "auto" }
    function fxOf(kind) { const v = Number(_g(kind + "X")); return isNaN(v) ? 0.5 : v }
    function fyOf(kind) { const v = Number(_g(kind + "Y")); return isNaN(v) ? 0.5 : v }
    function setFree(kind, fx, fy) {
        const v = {}
        v[kind + "X"] = fx; v[kind + "Y"] = fy; v[kind + "Placement"] = "free"
        Settings.setMany("widgets", v)
    }
    function resetPlacement() {
        const v = {}
        for (const k of kinds) v[k + "Placement"] = "auto"
        v.preset = "custom"
        Settings.setMany("widgets", v)
    }
    function startEdit() { Settings.setMany("widgets", { enabled: true, edit: true }) }

    // ---------- пресети ----------
    readonly property var presetIds: ["corner", "stack", "desk", "centered", "minimal", "outline"]
    readonly property var _base: ({
        enabled: true, anchor: "top-right", arrange: "row", margin: 48, spacing: 16, scale: 1,
        colorStyle: "mixed", bgStyle: "filled", bgOpacity: 1,
        clockEnabled: true, clockStyle: "digital", clockShape: "cookie",
        weatherEnabled: true, weatherShape: "flower",
        mediaEnabled: true, mediaShape: "pill", mediaHideIdle: true,
        resourcesEnabled: true, resourcesShape: "sunny",
        clockPlacement: "auto", weatherPlacement: "auto", mediaPlacement: "auto", resourcesPlacement: "auto"
    })
    readonly property var presets: ({
        corner:   {},
        stack:    { anchor: "left", arrange: "column", margin: 32, spacing: 14, colorStyle: "primary",
                    clockShape: "squircle", weatherShape: "squircle", mediaShape: "rounded", resourcesShape: "squircle" },
        desk:     { clockPlacement: "free", clockX: 0.03, clockY: 0.06,
                    weatherPlacement: "free", weatherX: 0.97, weatherY: 0.06,
                    mediaPlacement: "free", mediaX: 0.5, mediaY: 0.95,
                    resourcesPlacement: "free", resourcesX: 0.97, resourcesY: 0.55 },
        centered: { anchor: "center", clockStyle: "analog", clockShape: "circle", scale: 1.35, bgStyle: "glass",
                    weatherEnabled: false, mediaEnabled: false, resourcesEnabled: false },
        minimal:  { anchor: "bottom-left", margin: 56, bgStyle: "none", clockShape: "circle", weatherShape: "circle",
                    mediaEnabled: false, resourcesEnabled: false },
        outline:  { anchor: "bottom-right", arrange: "column", margin: 40, bgStyle: "outline",
                    clockShape: "circle", weatherShape: "circle", mediaShape: "squircle", resourcesShape: "circle" }
    })

    property bool _applying: false
    function applyPreset(id) {
        if (!presets[id]) return
        _applying = true
        const v = Object.assign({}, _base, presets[id])
        v.preset = id
        Settings.setMany("widgets", v)
        _applying = false
    }
    // вибір пресета у налаштуваннях → застосувати
    Connections {
        target: Settings
        function onChanged(cat, key, value) {
            if (cat === "widgets" && key === "preset" && !root._applying && value !== "custom") root.applyPreset(value)
        }
    }


    // ---------- кольори (за темою + стилем фону) ----------
    function _role(kind) {
        if (colorStyle !== "mixed") return colorStyle
        return kind === "clock" ? "primary" : kind === "weather" ? "tertiary"
             : kind === "media" ? "secondary" : "surface"
    }
    // базовий (непрозорий) колір контейнера ролі
    function baseFill(kind) {
        switch (_role(kind)) {
        case "primary":   return ThemeColors.primaryContainer
        case "secondary": return ThemeColors.secondaryContainer
        case "tertiary":  return ThemeColors.tertiaryContainer
        }
        return ThemeColors.surfaceContainerHigh
    }
    // те, що реально малюється
    function fill(kind) {
        if (plain) return "transparent"
        const a = bgStyle === "glass" ? 0.55 * bgOpacity : bgOpacity
        return Theme.alpha(baseFill(kind), a)
    }
    function borderWidth() { return bgStyle === "outline" ? 2 : (ThemeSettings.nothing || bgStyle === "glass") ? 1 : 0 }
    function on(kind) {
        if (plain) return ThemeColors.fgSurface
        switch (_role(kind)) {
        case "primary":   return ThemeColors.fgPrimaryContainer
        case "secondary": return ThemeColors.fgSecondaryContainer
        case "tertiary":  return ThemeColors.fgTertiaryContainer
        }
        return ThemeColors.fgSurface
    }
    function accent(kind) {
        if (ThemeSettings.nothing) return ThemeNothing.red
        if (plain) return ThemeColors.primary
        switch (_role(kind)) {
        case "secondary": return ThemeColors.fgSecondaryContainer
        case "tertiary":  return ThemeColors.fgTertiaryContainer
        }
        return ThemeColors.primary
    }
    function shapeFor(kind) {
        return kind === "clock" ? clockShape : kind === "weather" ? weatherShape
             : kind === "media" ? mediaShape : resourcesShape
    }
}
