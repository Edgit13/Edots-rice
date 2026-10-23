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

    // що обрано в налаштуваннях (миттєво) vs що застосовано (після анімації переходу, див. ThemeSwitch)
    readonly property string wantedMode:       Settings.get("theme", "mode")
    readonly property string wantedDesign:     Settings.get("theme", "design") || "material"
    property string _mode: ""
    property string _design: ""
    readonly property string mode:             _mode !== "" ? _mode : wantedMode
    readonly property string design:           _design !== "" ? _design : wantedDesign
    readonly property bool nothing:            design === "nothing"
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

    // після старту (ThemeSwitch.armed) зміни design/mode проходять через анімований перехід
    Connections {
        target: ThemeSwitch
        function onArmedChanged() {
            if (ThemeSwitch.armed) { root._mode = root.mode; root._design = root.design }
        }
    }
    function _sync() {
        if (_design === "") return                 // ще не «озброєно» — слідуємо напряму
        if (_design === wantedDesign && _mode === wantedMode) return
        ThemeSwitch.request(function () { root._design = root.wantedDesign; root._mode = root.wantedMode })
    }
    onWantedDesignChanged: _sync()
    onWantedModeChanged: _sync()

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
