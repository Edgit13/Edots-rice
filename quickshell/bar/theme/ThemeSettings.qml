pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell
import Quickshell.Io

// ThemeSettings — єдине джерело користувацьких налаштувань теми/руху.
// Persist: ~/.config/quickshell/theme.json (live-watch). Змінюється через set(key, value)
// (Stage 16 Settings UI просто викликає ThemeSettings.set / Theme.set).
Singleton {
    id: root

    readonly property string mode: _valid(a.mode, ["system", "light", "dark"], "dark")        // system | light | dark
    readonly property bool dynamicColor: a.dynamicColor                                        // кольори з шпалер (colors.json)
    readonly property string accent: a.accent                                                  // custom accent (коли dynamicColor=false)
    readonly property string cornerStyle: _valid(a.cornerStyle, ["material", "expressive", "rounded"], "expressive")
    readonly property bool animations: a.animations
    readonly property bool expressiveMotion: a.expressiveMotion
    readonly property real animationSpeed: Math.max(0.25, Math.min(3, a.animationSpeed))
    readonly property bool reduceMotion: a.reduceMotion
    readonly property real uiScale: Math.max(0.75, Math.min(2, a.uiScale))

    // system light/dark (gsettings; якщо недоступний — dark)
    property bool systemDark: true
    readonly property bool resolvedDark: mode === "system" ? systemDark : mode === "dark"

    function _valid(v, list, fb) { return list.indexOf(v) >= 0 ? v : fb }

    function set(key, value) {
        if (typeof a[key] === "undefined") {
            console.warn("[Theme] unknown setting: " + key)
            return
        }
        a[key] = value
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/theme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        adapter: JsonAdapter {
            id: a
            property string mode: "dark"
            property bool dynamicColor: true
            property string accent: "#6750A4"
            property string cornerStyle: "expressive"
            property bool animations: true
            property bool expressiveMotion: true
            property real animationSpeed: 1.0
            property bool reduceMotion: false
            property real uiScale: 1.0
        }
    }

    // Подієво (без polling): одноразове читання + monitor лише в режимі "system"
    function _applyScheme(text) { root.systemDark = String(text).indexOf("prefer-light") < 0 }

    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        running: root.mode === "system"
        stdout: StdioCollector { onStreamFinished: root._applyScheme(text) }
    }
    Process {
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
        running: root.mode === "system"
        stdout: SplitParser { onRead: function (line) { root._applyScheme(line) } }
    }
}
