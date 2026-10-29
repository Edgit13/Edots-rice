pragma Singleton
import "root:/settings"
import "root:/services"
import Quickshell
import Quickshell.Io
import QtQuick

// GameModeState — стан ігрового режиму (файл ~/.cache/quickshell/gamemode.state пише scripts/gamemode.sh)
// + реакція самого shell: «Не турбувати», вимкнення анімацій, індикатор у барі.
// Налаштування — Settings → Ігровий режим; вони ж пишуться у ~/.cache/quickshell/gamemode.conf для скрипта.
Singleton {
    id: root

    property bool active: false
    property bool ready: false                    // стан прочитано хоча б раз (щоб не чіпати DND на старті)

    readonly property string cache: Quickshell.env("HOME") + "/.cache/quickshell"
    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/gamemode.sh"

    // ---- налаштування (за замовчуванням все ввімкнено) ----
    readonly property bool optEffects: Settings.get("gamemode", "effects") !== false
    readonly property bool optTearing: Settings.get("gamemode", "tearing") !== false
    readonly property bool optPower:   Settings.get("gamemode", "power") !== false
    readonly property bool optIdle:    Settings.get("gamemode", "idle") !== false
    readonly property bool optDnd:     Settings.get("gamemode", "dnd") !== false
    readonly property bool optMotion:  Settings.get("gamemode", "motion") !== false
    readonly property bool optNotify:  Settings.get("gamemode", "notify") !== false
    // лише shell: плоский бар і оверлей продуктивності
    readonly property bool optFlatBar: Settings.get("gamemode", "flatBar") !== false
    readonly property bool optOverlay: Settings.get("gamemode", "overlay") !== false
    readonly property bool optOverlayFps:   Settings.get("gamemode", "overlayFps") !== false
    readonly property bool optOverlayCpu:   Settings.get("gamemode", "overlayCpu") !== false
    readonly property bool optOverlayGpu:   Settings.get("gamemode", "overlayGpu") !== false
    readonly property bool optOverlayTemps: Settings.get("gamemode", "overlayTemps") === true
    readonly property string optOverlayPos: Settings.get("gamemode", "overlayPos") || "top-left"
    readonly property real optOverlayScale:   Math.max(0.6, Math.min(2.5, Number(Settings.get("gamemode", "overlayScale") ?? 1)))
    readonly property real optOverlayOpacity: Math.max(0.2, Math.min(1, Number(Settings.get("gamemode", "overlayOpacity") ?? 0.85)))

    function toggle()  { run("toggle") }
    function enable()  { run("on") }
    function disable() { run("off") }
    function run(arg)  { Quickshell.execDetached(["bash", script, arg]) }
    function ensure()  { writeConf() }            // зі ShellNext при старті

    // ---- стан-файл ----
    FileView {
        id: stateFile
        path: root.cache + "/gamemode.state"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root._apply(text().trim() === "1")
        onLoadFailed: root.ready = true
    }

    property bool _prevDnd: false
    function _apply(on) {
        const was = active
        active = on
        if (!ready) { ready = true; return }
        if (on === was || !optDnd) return
        if (on) { _prevDnd = NotificationService.dnd; NotificationService.setDnd(true) }
        else    { NotificationService.setDnd(_prevDnd) }
    }

    // ---- конфіг для скрипта ----
    function _q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    function _b(v) { return v ? "1" : "0" }

    Process { id: writer }
    function writeConf() {
        const c =
            "EFFECTS=" + _b(optEffects) + "\n" +
            "TEARING=" + _b(optTearing) + "\n" +
            "POWER="   + _b(optPower)   + "\n" +
            "IDLE="    + _b(optIdle)    + "\n" +
            "NOTIFY="  + _b(optNotify)  + "\n" +
            "MSG_ON="      + _q(Lang.t("ui.game.on"))     + "\n" +
            "MSG_ON_BODY=" + _q(Lang.t("ui.game.onBody")) + "\n" +
            "MSG_OFF="     + _q(Lang.t("ui.game.off"))    + "\n"
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf %s "$2" > "$1"', "sh", cache + "/gamemode.conf", c]
        writer.running = true
    }

    Connections {
        target: Settings
        function onChanged(cat, key, value) { if (cat === "gamemode") root.writeConf() }
    }
}
