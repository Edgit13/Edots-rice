.pragma library

// BindsParser — розбір MangoWM binds.conf у список записів для шпаргалки.
// Повертає [{group, keys:[...], descKey, descArg, cmd}] (descKey — ключ Lang "ui.binds.*").

var MODS = { super: "Super", mod4: "Super", shift: "Shift", ctrl: "Ctrl", control: "Ctrl", alt: "Alt", mod1: "Alt" }
var KEYS = {
    "return": "Enter", "escape": "Esc", "space": "Space", "print": "PrtSc", "end": "End", "home": "Home",
    "left": "←", "right": "→", "up": "↑", "down": "↓", "slash": "/", "backslash": "\\", "minus": "−", "equal": "=",
    "comma": ",", "period": ".", "grave": "`", "page_up": "PgUp", "page_down": "PgDn",
    "xf86audioraisevolume": "Vol +", "xf86audiolowervolume": "Vol −", "xf86audiomute": "Mute",
    "xf86audiomicmute": "Mic", "xf86monbrightnessup": "Bright +", "xf86monbrightnessdown": "Bright −",
    "xf86audionext": "Next", "xf86audioprev": "Prev", "xf86audiopause": "Play", "xf86audioplay": "Play",
    "xf86audiostop": "Stop"
}
var DIRS = { left: "←", right: "→", up: "↑", down: "↓" }

var IPC = {
    "pill.toggleLauncher": "launcher", "pill.showLauncher": "launcher", "launcher.open": "launcher",
    "pill.toggleWallpaper": "wallpaper", "pill.toggleClipboard": "clipboard", "pill.toggleWifi": "wifi",
    "pill.toggleMixer": "mixer", "pill.toggleMedia": "media", "pill.togglePower": "power",
    "pill.toggleBinds": "binds", "pill.showBinds": "binds",
    "pill.toggleSettings": "settings", "settingsapp.toggle": "settings", "settingsapp.open": "settings",
    "dashboard.toggle": "dashboard", "dashboard.open": "dashboard",
    "tasks.toggle": "tasks", "tasks.open": "tasks",
    "notifications.toggle": "notifs", "notifications.open": "notifs",
    "notifications.clear": "notifsClear", "notifications.dnd": "dnd",
    "screentool.toggle": "screentool", "screentool.open": "screentool",
    "osd.volumeUp": "volUp", "osd.volumeDown": "volDown", "osd.volumeMute": "mute",
    "osd.brightnessUp": "brightUp", "osd.brightnessDown": "brightDown"
}

var ACTIONS = {
    "reload_config": "reload", "killclient": "kill", "togglefloating": "float",
    "toggle_scratchpad": "scratch", "minimized": "minimize", "switch_layout": "layout",
    "dwindle_toggle_split_direction": "dwindleSplit",
    "viewtoright_have_client": "viewRight", "viewtoleft_have_client": "viewLeft",
    "tagtoleft": "tagLeft", "tagtoright": "tagRight", "view": "view", "tag": "tag",
    "focusdir": "focus", "focusmon": "focusmon", "tagmon": "tagmon", "setlayout": "setlayout"
}

function prettyMod(m) {
    var l = m.trim().toLowerCase()
    if (l === "" || l === "none") return ""
    return MODS[l] || (m.charAt(0).toUpperCase() + m.slice(1))
}

function prettyKey(key, kind) {
    var k = key.trim(), l = k.toLowerCase()
    if (kind === "mouse") {
        if (l === "btn_left") return "LMB"
        if (l === "btn_right") return "RMB"
        if (l === "btn_middle") return "MMB"
        return k
    }
    if (kind === "axis") {
        if (l === "up") return "Scroll ↑"
        if (l === "down") return "Scroll ↓"
        return "Scroll " + k
    }
    if (KEYS[l] !== undefined) return KEYS[l]
    if (k.length === 1) return k.toUpperCase()
    return k.charAt(0).toUpperCase() + k.slice(1)
}

function basename(cmd) {
    var first = cmd.trim().split(/\s+/)[0] || ""
    first = first.replace(/^['"]|['"]$/g, "")
    var parts = first.split("/")
    return parts[parts.length - 1]
}

function describeSpawn(a) {
    var s = a.trim()
    // IPC до shell: ipc call <target> <fn>
    var calls = []
    var re = /ipc call (\w+) (\w+)/g, m
    while ((m = re.exec(s)) !== null) calls.push(m[1] + "." + m[2])
    if (calls.length > 1) {
        var allClose = true
        for (var i = 0; i < calls.length; i++) if (!/\.close$/.test(calls[i])) allClose = false
        if (allClose) return { key: "closeAll", arg: "" }
    }
    if (calls.length > 0) {
        if (IPC[calls[0]]) return { key: IPC[calls[0]], arg: "" }
        return { key: "ipc", arg: calls[0].replace(".", " ") }
    }
    if (/lock\.sh/.test(s)) return { key: "lock", arg: "" }
    if (/suspend\.sh/.test(s)) return { key: "suspend", arg: "" }
    if (/gamemode\.sh/.test(s)) return { key: "gamemode", arg: "" }
    if (/toggle-dock\.sh/.test(s)) return { key: "dock", arg: "" }
    if (/lens\.sh/.test(s)) return { key: "lens", arg: "" }
    if (/^reboot\b/.test(s)) return { key: "reboot", arg: "" }
    if (/mango msg quit/.test(s) || /mmsg quit/.test(s)) return { key: "quit", arg: "" }
    if (/cliphist/.test(s)) return { key: "cliphist", arg: "" }
    if (/wpctl set-volume.*\+\s*$/.test(s)) return { key: "volUp", arg: "" }
    if (/wpctl set-volume.*-\s*$/.test(s)) return { key: "volDown", arg: "" }
    if (/wpctl set-mute.*SOURCE/.test(s)) return { key: "micMute", arg: "" }
    if (/wpctl set-mute/.test(s)) return { key: "mute", arg: "" }
    if (/brightnessctl.*\+\s*$/.test(s)) return { key: "brightUp", arg: "" }
    if (/brightnessctl.*-\s*$/.test(s)) return { key: "brightDown", arg: "" }
    if (/playerctl next/.test(s)) return { key: "next", arg: "" }
    if (/playerctl previous/.test(s)) return { key: "prev", arg: "" }
    if (/playerctl play-pause/.test(s)) return { key: "playPause", arg: "" }
    if (/playerctl stop/.test(s)) return { key: "stop", arg: "" }
    return { key: "open", arg: basename(s) }
}

function describe(action, args, kind) {
    var a = action.trim()
    if (a === "spawn" || a === "spawn_shell") return describeSpawn(args)
    if (a === "moveresize") {
        return /curresize/.test(args) ? { key: "resize", arg: "" } : { key: "move", arg: "" }
    }
    var k = ACTIONS[a]
    if (!k) return { key: "action", arg: a + (args ? " " + args : "") }
    var arg = ""
    if (k === "focus" || k === "focusmon" || k === "tagmon") arg = DIRS[args.trim().toLowerCase()] || args.trim()
    else if (k === "view" || k === "tag" || k === "setlayout") arg = args.trim()
    return { key: k, arg: arg }
}

function parse(text) {
    var lines = text.split("\n")
    var group = "", pending = "", sawBind = false
    var out = []

    for (var i = 0; i < lines.length; i++) {
        var raw = lines[i].replace(/\r$/, "")
        var line = raw.trim()

        if (line === "") {
            pending = ""
            if (sawBind) { group = ""; sawBind = false }
            continue
        }
        if (line.charAt(0) === "#") {
            var t = line.replace(/^#+\s*/, "")
            // відступний/порожній коментар — це пояснення, не заголовок
            if (t === "" || /^#\s{3,}/.test(raw)) { pending = ""; continue }
            pending = t.replace(/\s*\(.*$/, "").replace(/:\s*$/, "")
            if (pending.length > 0) pending = pending.charAt(0).toUpperCase() + pending.slice(1)
            continue
        }

        var m = line.match(/^(bind[a-z]*|axisbind|mousebind|gesturebind|switchbind)\s*=\s*(.*)$/)
        if (!m) { pending = ""; continue }

        var kind = m[1] === "mousebind" ? "mouse" : (m[1] === "axisbind" ? "axis" : "key")
        var f = m[2].split(",")
        if (f.length < 3) continue
        var mods = f[0], key = f[1], action = f[2], args = f.slice(3).join(",")

        if (pending) { group = pending; pending = "" }
        sawBind = true

        var keys = []
        var ms = mods.split("+")
        for (var j = 0; j < ms.length; j++) { var pm = prettyMod(ms[j]); if (pm) keys.push(pm) }
        keys.push(prettyKey(key, kind))

        var d = describe(action, args, kind)
        out.push({
            group: group, keys: keys, descKey: d.key, descArg: d.arg,
            cmd: (action === "spawn" || action === "spawn_shell") ? args.trim() : "",
            _action: action.trim(), _mods: mods.trim().toUpperCase(), _key: key.trim()
        })
    }

    // 1…9 → один рядок (view / tag)
    var res = [], seen = {}
    for (var n = 0; n < out.length; n++) {
        var e = out[n]
        var isNum = (e._action === "view" || e._action === "tag") && /^[1-9]$/.test(e._key)
        if (!isNum) { res.push(e); continue }
        var id = e.group + "|" + e._action + "|" + e._mods
        if (seen[id] !== undefined) continue
        var count = 0
        for (var q = 0; q < out.length; q++)
            if (out[q].group === e.group && out[q]._action === e._action && out[q]._mods === e._mods && /^[1-9]$/.test(out[q]._key)) count++
        if (count < 3) { res.push(e); continue }
        seen[id] = true
        var ks = e.keys.slice(0, e.keys.length - 1)
        ks.push("1–9")
        res.push({ group: e.group, keys: ks, descKey: e.descKey, descArg: "N", cmd: "", _action: e._action, _mods: e._mods, _key: "1-9" })
    }
    return res
}

if (typeof module !== "undefined") module.exports = { parse: parse }
