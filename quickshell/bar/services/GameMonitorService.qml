pragma Singleton
import "root:/settings"
import Quickshell
import Quickshell.Io
import QtQuick

// GameMonitorService — дані для ігрового оверлея: FPS, навантаження CPU/GPU, температури.
//  • FPS: якщо є свіжий лог MangoHud → FPS гри; інакше — частота кадрів дисплея (скільки кадрів/с отримує оверлей).
//  • CPU: PerformanceService (або MangoHud), GPU: sysfs (AMD) / nvidia-smi (NVIDIA) / MangoHud.
// Опитування лише поки оверлей видимий (subscribe/unsubscribe).
Singleton {
    id: root

    property int subscribers: 0
    readonly property bool active: subscribers > 0
    function subscribe() { subscribers += 1 }
    function unsubscribe() { subscribers = Math.max(0, subscribers - 1) }
    onActiveChanged: active ? PerformanceService.subscribe() : PerformanceService.unsubscribe()

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/gamemon.sh"

    // ---- налаштування ----
    readonly property string fpsSource: Settings.get("gamemode", "fpsSource") || "auto"
    readonly property string mhDir: Settings.get("gamemode", "mangohudDir") || "/tmp/MangoHud"

    // ---- сирі дані ----
    property real displayFps: 0            // виставляє оверлей (FrameAnimation)
    property real gpuLoadSys: -1
    property real gpuTempSys: -1
    property real mhAge: -1
    property real mhFps: 0
    property real mhGpu: -1
    property real mhCpu: -1

    // ---- підсумок ----
    readonly property bool mhFresh: mhAge >= 0 && mhAge <= 3
    readonly property bool useMangoHud: fpsSource === "mangohud" || (fpsSource === "auto" && mhFresh)
    readonly property real fps: useMangoHud ? mhFps : displayFps
    readonly property string fpsUnit: useMangoHud ? "FPS" : "Hz"
    readonly property real cpuLoad: (useMangoHud && mhCpu >= 0) ? mhCpu : PerformanceService.cpuPercent
    readonly property real gpuLoad: (useMangoHud && mhGpu >= 0) ? mhGpu : gpuLoadSys
    readonly property real cpuTemp: PerformanceService.cpuTemp
    readonly property real gpuTemp: gpuTempSys

    function _parse(text) {
        const num = (k, d) => { const m = text.match(new RegExp(k + "=(-?[0-9.]+)")); return m ? parseFloat(m[1]) : d }
        gpuLoadSys = num("gpu", -1)
        gpuTempSys = num("gtemp", -1)
        mhAge = num("mh", -1)
        mhFps = num("mhfps", 0)
        mhGpu = num("mhgpu", -1)
        mhCpu = num("mhcpu", -1)
    }

    Process {
        id: proc
        command: ["bash", root.script, root.mhDir]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }
}
