pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// PerformanceService — CPU / RAM / диск, з /proc і df (без зовнішніх моніторів).
// Опитується лише поки хтось підписаний (див. active), щоб не гріти CPU в фоні.
Singleton {
    id: root

    property int subscribers: 0
    readonly property bool active: subscribers > 0
    function subscribe() { subscribers += 1 }
    function unsubscribe() { subscribers = Math.max(0, subscribers - 1) }

    property real cpuPercent: 0
    property real ramPercent: 0
    property real ramUsedGiB: 0
    property real ramTotalGiB: 0
    property real diskPercent: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0

    property var _prevIdle: 0
    property var _prevTotal: 0
    property bool _havePrev: false

    function _parse(text) {
        const parts = text.split("--MEM--")
        const cpuLine = parts[0].trim()
        const rest = parts[1] ? parts[1].split("--DISK--") : ["", ""]
        const memText = rest[0]
        const diskText = rest[1] || ""

        // CPU: "cpu  user nice system idle iowait irq softirq steal ..."
        const f = cpuLine.replace(/^cpu\s+/, "").trim().split(/\s+/).map(Number)
        const idle = (f[3] || 0) + (f[4] || 0)
        const total = f.reduce((a, b) => a + b, 0)
        if (root._havePrev) {
            const dIdle = idle - root._prevIdle
            const dTotal = total - root._prevTotal
            if (dTotal > 0) root.cpuPercent = Math.max(0, Math.min(100, 100 * (1 - dIdle / dTotal)))
        }
        root._prevIdle = idle
        root._prevTotal = total
        root._havePrev = true

        // RAM: kB
        const memTotal = _grep(memText, "MemTotal")
        const memAvail = _grep(memText, "MemAvailable")
        if (memTotal > 0) {
            const used = memTotal - memAvail
            root.ramPercent = Math.max(0, Math.min(100, 100 * used / memTotal))
            root.ramUsedGiB = used / 1048576
            root.ramTotalGiB = memTotal / 1048576
        }

        // Disk: `df -B1 /` -> header + one line: fs, size, used, avail, use%, mount
        const dLines = diskText.trim().split("\n")
        if (dLines.length >= 2) {
            const cols = dLines[1].trim().split(/\s+/)
            const size = parseFloat(cols[1]), used = parseFloat(cols[2])
            if (size > 0) {
                root.diskPercent = 100 * used / size
                root.diskUsedGiB = used / 1073741824
                root.diskTotalGiB = size / 1073741824
            }
        }
    }
    function _grep(text, key) {
        const m = text.match(new RegExp(key + ":\\s*(\\d+)"))
        return m ? parseInt(m[1]) : 0
    }

    Process {
        id: proc
        command: ["sh", "-c", "cat /proc/stat | head -1; echo --MEM--; cat /proc/meminfo; echo --DISK--; df -B1 /"]
        stdout: StdioCollector { onStreamFinished: root._parse(text) }
    }

    Timer {
        interval: 2000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
