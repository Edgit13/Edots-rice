pragma Singleton
import "root:/settings"
import Quickshell
import Quickshell.Io
import QtQuick

// LayoutService — вибір розкладки вікон MangoWM у Settings → Вікна.
//  • пише ~/.config/mango/layout.conf (tag_rule=id:N,layout_name:… для тегів 1–9 + circle_layout)
//    MangoWM ≥ 0.18 перейменував ключі у snake_case (tagrule → tag_rule); для старих збірок — tagrule.
//    Який варіант — визначається автоматично за іншими *.conf у ~/.config/mango.
//  • одразу ставить розкладку на поточному теґу (mmsg dispatch setlayout) і перечитує конфіг
// У ~/.config/mango/config.conf має бути (останнім рядком, щоб перекрити старі tagrule):
//     source=~/.config/mango/layout.conf
Singleton {
    id: root

    readonly property string layoutName: String(Settings.get("layout", "active") || "dwindle")
    readonly property string cycleList: String(Settings.get("layout", "cycle") || "")
    readonly property string file: Quickshell.env("HOME") + "/.config/mango/layout.conf"
    readonly property int tagCount: 9

    // tag_rule (0.18+) або tagrule (старіші); визначаємо за ключами в інших конфігах
    property string keyword: "tag_rule"
    property bool detected: false

    Process {
        id: detect
        command: ["sh", "-c",
            "d=\"$HOME/.config/mango\"; " +
            "if grep -rEq '^[[:space:]]*(tag_rule|window_rule|monitor_rule|layer_rule|exec_once)' \"$d\" --include='*.conf' --exclude=layout.conf 2>/dev/null; then echo new; " +
            "elif grep -rEq '^[[:space:]]*(tagrule|windowrule|monitorrule|layerrule|exec-once)' \"$d\" --include='*.conf' --exclude=layout.conf 2>/dev/null; then echo old; " +
            "else echo new; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.keyword = text.trim() === "old" ? "tagrule" : "tag_rule"
                root.detected = true
                root.writeFile()
            }
        }
    }

    function ensure() { detect.running = true }    // викликається зі ShellNext при старті

    function content() {
        let s = "# Згенеровано Edots → Settings → Вікна. Підключи в config.conf (останнім рядком):\n"
              + "#   source=~/.config/mango/layout.conf\n"
        for (let i = 1; i <= tagCount; i++)
            s += keyword + "=id:" + i + ",layout_name:" + layoutName + "\n"
        const c = cycleList.split(",").map(x => x.trim()).filter(x => x.length > 0)
        if (c.length > 0) s += "circle_layout=" + c.join(",") + "\n"
        return s
    }

    Process { id: writer }
    function writeFile() {
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf %s "$2" > "$1"', "sh", file, content()]
        writer.running = true
    }

    function dispatch(cmd) {
        if (MangoService.backend === "legacy") Quickshell.execDetached(["mmsg", "-d", cmd])
        else Quickshell.execDetached(["mmsg", "dispatch", cmd])
    }

    Timer {
        id: reloadTimer
        interval: 400
        onTriggered: root.dispatch("reload_config")
    }

    Connections {
        target: Settings
        function onChanged(cat, key, value) {
            if (cat !== "layout") return
            root.writeFile()
            if (key === "active") {
                root.dispatch("setlayout," + value)       // поточний тег — одразу
                reloadTimer.restart()                     // решта тегів — з layout.conf
            }
        }
    }
}
