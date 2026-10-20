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
    property real cpuTemp: 0
    property real ramPercent: 0
    property real ramUsedGiB: 0
    property real ramTotalGiB: 0
    property real swapPercent: 0
    property real swapUsedGiB: 0
    property real swapTotalGiB: 0
    property real diskPercent: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 0
    property string uptime: ""
    property var topProcesses: []

    property var _prevIdle: 0
    property var _prevTotal: 0
    property bool _havePrev: false

    function _parse(text) {
        const parts = text.split("--MEM--")
        const cpuLine = parts[0].trim()
        const rest1 = parts[1] ? parts[1].split("--DISK--") : ["", ""]
        const memText = rest1[0]
        const rest2 = rest1[1] ? rest1[1].split("--TEMP--") : ["", ""]
        const diskText = rest2[0]
        const rest3 = rest2[1] ? rest2[1].split("--UPTIME--") : ["", ""]
        const tempText = rest3[0]
        const rest4 = rest3[1] ? rest3[1].split("--PROCS--") : ["", ""]
        const uptimeText = rest4[0]
        const procsText = rest4[1] || ""

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

        // Swap: kB
        const swapTotal = _grep(memText, "SwapTotal")
        const swapFree = _grep(memText, "SwapFree")
        if (swapTotal > 0) {
            const swapUsed = swapTotal - swapFree
            root.swapPercent = Math.max(0, Math.min(100, 100 * swapUsed / swapTotal))
            root.swapUsedGiB = swapUsed / 1048576
            root.swapTotalGiB = swapTotal / 1048576
        } else {
            root.swapPercent = 0
            root.swapUsedGiB = 0
            root.swapTotalGiB = 0
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

        // Temp
        const rawTemp = parseFloat(tempText.trim())
        if (!isNaN(rawTemp) && rawTemp > 0) {
            root.cpuTemp = rawTemp > 1000 ? Math.round(rawTemp / 1000) : Math.round(rawTemp)
        }

        // Uptime
        const upSec = parseFloat(uptimeText.trim().split(/\s+/)[0])
        if (!isNaN(upSec) && upSec > 0) {
            const d = Math.floor(upSec / 86400)
            const h = Math.floor((upSec % 86400) / 3600)
            const m = Math.floor((upSec % 3600) / 60)
            let s = ""
            if (d > 0) s += d + "d "
            if (h > 0 || d > 0) s += h + "h "
            s += m + "m"
            root.uptime = s
        }

        // Top processes
        const pLines = procsText.trim().split("\n")
        const procs = []
        for (let i = 0; i < pLines.length; i++) {
            const line = pLines[i].trim()
            if (!line) continue
            const tokens = line.split(/\s+/)
            if (tokens.length >= 4) {
                const pid = tokens[0]
                const mem = tokens[tokens.length - 1]
                const cpu = tokens[tokens.length - 2]
                const name = tokens.slice(1, tokens.length - 2).join(" ")
                procs.push({ pid: pid, name: name, cpu: cpu, mem: mem })
            }
        }
        root.topProcesses = procs
    }
    function _grep(text, key) {
        const m = text.match(new RegExp(key + ":\\s*(\\d+)"))
        return m ? parseInt(m[1]) : 0
    }

    Process {
        id: proc
        command: ["sh", "-c", "cat /proc/stat | head -1; echo --MEM--; cat /proc/meminfo; echo --DISK--; df -B1 /; echo --TEMP--; for z in /sys/class/thermal/thermal_zone*; do [ -f \"$z/temp\" ] && t=$(cat \"$z/temp\" 2>/dev/null) && [ \"$t\" -gt 0 ] && echo \"$t\" && break; done; echo --UPTIME--; cat /proc/uptime; echo --PROCS--; ps -eo pid,comm,%cpu,%mem --sort=-%cpu --no-headers | head -n 6"]
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
