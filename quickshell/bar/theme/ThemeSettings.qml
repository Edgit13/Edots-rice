pragma Singleton
import "root:/settings"
import "root:/states"
import Quickshell
import Quickshell.Io
import QtQuick

// ThemeSettings — тонкий фасад над Settings (категорія "theme").
// API не змінюється: mode/accent/animations/... та set(key, value).
Singleton {
    id: root

    readonly property string mode:             Settings.get("theme", "mode")
    readonly property bool dynamicColor:       Settings.get("theme", "dynamicColor")
    readonly property string accent:           Settings.get("theme", "accent")
    readonly property string cornerStyle:      Settings.get("theme", "cornerStyle")
    // у ігровому режимі shell не анімується (GameModeState.optMotion)
    readonly property bool _gm:                GameModeState.active && GameModeState.optMotion
    readonly property bool animations:         Settings.get("theme", "animations") && !_gm
    readonly property bool expressiveMotion:   Settings.get("theme", "expressiveMotion")
    readonly property real animationSpeed:     Settings.get("theme", "animationSpeed")
    readonly property bool reduceMotion:       Settings.get("theme", "reduceMotion") || _gm
    readonly property real uiScale:            Settings.get("theme", "uiScale")

    property bool systemDark: true
    readonly property bool resolvedDark: mode === "system" ? systemDark : mode === "dark"

    function set(key, value) { Settings.set("theme", key, value) }

    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"]
        running: root.mode === "system"
        stdout: StdioCollector {
            onStreamFinished: root.systemDark = String(text).indexOf("prefer-light") < 0
        }
    }
    Process {
        command: ["gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme"]
        running: root.mode === "system"
        stdout: SplitParser {
            onRead: function (line) { root.systemDark = String(line).indexOf("prefer-light") < 0 }
        }
    }
}
