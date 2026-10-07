import "root:/theme"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// BrightnessManager — один повзунок, який одночасно керує вбудованою
// підсвіткою через brightnessctl і зовнішніми DDC/CI моніторами через ddcutil.
Item {
    id: root

    implicitHeight: col.implicitHeight

    property var backlightDevices: []
    property var ddcMonitors: []
    property int masterPercent: 0
    property bool ddcError: false
    property string _ddcReadBus: ""
    property int _applyPercent: -1
    property int _applyDelta: 0

    readonly property bool scanning: backlightScanProc.running || ddcScanProc.running
                                   || ddcReadProc.running || applyAllProc.running
    readonly property bool hasDevices: backlightDevices.length > 0 || ddcMonitors.length > 0

    function _clampPercent(v) { return Math.max(0, Math.min(100, Math.round(v))) }

    function _parseBrightnessLine(line) {
        const cols = line.trim().split(",")
        if (cols.length < 5 || cols[1] !== "backlight") return null

        // Актуальний brightnessctl -m повертає:
        // id,class,current,percent%,max. Старі/форкові версії можуть
        // додавати path після class, тому підтримуємо обидва формати.
        const device = cols[0]
        const hasPath = cols.length >= 6
        const path = hasPath ? cols[2] : ("/sys/class/backlight/" + device)
        const current = parseFloat(hasPath ? cols[3] : cols[2])
        const percent = parseFloat(hasPath ? cols[4] : cols[3])
        const max = parseFloat(hasPath ? cols[5] : cols[4])
        if (!isFinite(current) || !isFinite(percent) || !isFinite(max) || max <= 0) return null

        return {
            device: device,
            path: path,
            current: current,
            max: max,
            percent: _clampPercent(percent > 1 ? percent : percent * 100),
            label: path.split("/").filter(Boolean).pop() || device
        }
    }

    function parseBrightnessCtl(text) {
        const result = []
        const lines = text.split(/\r?\n/)
        for (let i = 0; i < lines.length; i++) {
            const item = _parseBrightnessLine(lines[i])
            if (item) result.push(item)
        }
        return result
    }

    function parseDdcDetect(text) {
        const result = []
        let current = null
        const lines = text.split(/\r?\n/)

        function flush() {
            if (current && isFinite(current.bus)) result.push(current)
            current = null
        }

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            const bus = line.match(/\/dev\/i2c-(\d+)/i)
            if (bus) {
                flush()
                current = { bus: Number(bus[1]), model: "", percent: -1 }
                continue
            }
            if (!current) continue

            const model = line.match(/Model:\s*(.+)$/i)
            if (model) current.model = model[1].trim()

            const mfg = line.match(/Mfg\s*id:\s*(.+)$/i)
            if (mfg && current.model.length === 0) current.model = mfg[1].trim()

            if (line.trim().length === 0) flush()
        }
        flush()
        return result
    }

    function parseVcpBrightness(text) {
        const cur = text.match(/current value\s*=\s*(\d+)/i)
        if (!cur) return -1
        const max = text.match(/max(?:imum)? value\s*=\s*(\d+)/i)
        const maxValue = max ? Number(max[1]) : 100
        if (!isFinite(maxValue) || maxValue <= 0) return -1
        return _clampPercent(Number(cur[1]) / maxValue * 100)
    }

    function _replaceDdcMonitor(bus, percent) {
        const next = []
        for (let i = 0; i < ddcMonitors.length; i++) {
            const mon = ddcMonitors[i]
            next.push(mon.bus === bus ? { bus: mon.bus, model: mon.model, percent: percent } : mon)
        }
        ddcMonitors = next
    }

    function _syncMasterFromDevices() {
        let sum = 0
        let count = 0
        for (let i = 0; i < backlightDevices.length; i++) {
            sum += backlightDevices[i].percent
            count++
        }
        for (let i = 0; i < ddcMonitors.length; i++) {
            if (ddcMonitors[i].percent >= 0) {
                sum += ddcMonitors[i].percent
                count++
            }
        }
        masterPercent = count > 0 ? Math.round(sum / count) : 0
    }

    function _readDdcAt(index) {
        if (index < 0 || index >= ddcMonitors.length) {
            _syncMasterFromDevices()
            return
        }
        _ddcReadBus = ddcMonitors[index].bus.toString()
        ddcReadProc.running = true
    }

    function refresh() {
        if (!backlightScanProc.running) backlightScanProc.running = true
        if (!ddcScanProc.running) ddcScanProc.running = true
    }

    function _shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\\''") + "'"
    }

    function _applyCommand(percent, delta) {
        const commands = []
        const target = _clampPercent(percent)

        for (let i = 0; i < backlightDevices.length; i++) {
            // brightnessctl: set +10% / set 10%-
            const operation = delta > 0 ? ("+" + delta + "%")
                            : delta < 0 ? (Math.abs(delta) + "%-")
                            : (target + "%")
            commands.push("brightnessctl -d " + _shellQuote(backlightDevices[i].device)
                          + " set " + operation)
        }

        // DDC/CI не має відносного інкременту, тому передаємо цільовий відсоток.
        for (let i = 0; i < ddcMonitors.length; i++) {
            commands.push("ddcutil --bus " + ddcMonitors[i].bus
                          + " setvcp 10 " + target)
        }
        return commands.join(" && ")
    }

    function _setLocalPercent(value) {
        masterPercent = value

        const nextBacklights = []
        for (let i = 0; i < backlightDevices.length; i++) {
            const dev = backlightDevices[i]
            nextBacklights.push({
                device: dev.device,
                path: dev.path,
                current: dev.max > 0 ? Math.round(dev.max * value / 100) : dev.current,
                max: dev.max,
                percent: value,
                label: dev.label
            })
        }
        backlightDevices = nextBacklights

        const nextDdc = []
        for (let i = 0; i < ddcMonitors.length; i++) {
            const mon = ddcMonitors[i]
            nextDdc.push({ bus: mon.bus, model: mon.model, percent: value })
        }
        ddcMonitors = nextDdc
    }

    function _apply(target, delta) {
        _applyPercent = target
        _applyDelta = delta
        applyAllProc.running = true
    }

    function setAll(percent) {
        if (!hasDevices) return
        _setLocalPercent(_clampPercent(percent))
        _apply(masterPercent, 0)
    }

    function step(delta) {
        if (!hasDevices) return
        _setLocalPercent(_clampPercent(masterPercent + delta))
        _apply(masterPercent, delta)
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshAfterApply
        interval: 500
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: backlightScanProc
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.backlightDevices = root.parseBrightnessCtl(text)
                root._syncMasterFromDevices()
            }
        }
    }

    Process {
        id: ddcScanProc
        command: ["ddcutil", "detect", "--brief"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.ddcMonitors = root.parseDdcDetect(text)
                root._readDdcAt(0)
            }
        }
        stderr: StdioCollector {
            onStreamFinished: root.ddcError = text.trim().length > 0
        }
    }

    Process {
        id: ddcReadProc
        command: ["ddcutil", "--bus", root._ddcReadBus, "getvcp", "10"]
        stdout: StdioCollector {
            onStreamFinished: {
                const bus = Number(root._ddcReadBus)
                if (isFinite(bus)) root._replaceDdcMonitor(bus, root.parseVcpBrightness(text))
                const current = root.ddcMonitors.findIndex(function(mon) { return mon.bus === bus })
                root._readDdcAt(current + 1)
            }
        }
    }

    Process {
        id: applyAllProc
        command: ["sh", "-c", root._applyCommand(root._applyPercent, root._applyDelta)]
        stdout: StdioCollector { onStreamFinished: refreshAfterApply.restart() }
        stderr: StdioCollector {
            onStreamFinished: {
                root.ddcError = text.trim().length > 0
                refreshAfterApply.restart()
            }
        }
    }

    component BrightnessSlider: Item {
        id: slider
        property real value: 0
        property bool enabled: true
        signal commit(real value)

        implicitHeight: 28

        function setFromMouse(mouseX) {
            value = Math.max(0, Math.min(100, mouseX / width * 100))
        }

        Rectangle {
            id: track
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 8
            radius: 4
            color: Theme.color.surfaceContainerHighest

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, slider.value / 100))
                height: parent.height
                radius: 4
                color: Theme.color.primary
                Behavior on width { MotionAnimation { role: "stateChange" } }
            }
        }

        Rectangle {
            id: handle
            width: 20
            height: 20
            radius: 10
            color: slider.enabled ? Theme.color.primary : Theme.color.surfaceContainerHighest
            x: Math.max(0, Math.min(track.width - width, track.width * slider.value / 100 - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            Behavior on x { MotionAnimation { role: "morph" } }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            enabled: slider.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: function(mouse) { slider.setFromMouse(mouse.x) }
            onPositionChanged: function(mouse) { if (pressed) slider.setFromMouse(mouse.x) }
            onReleased: function(mouse) { slider.setFromMouse(mouse.x); slider.commit(slider.value) }
        }
    }

    component StepButton: Rectangle {
        id: btn
        property string icon: ""
        property bool active: true
        signal clicked()

        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        opacity: active ? 1 : 0.45
        color: bma.pressed && active ? Theme.color.primary : Theme.color.surfaceContainerHighest

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
            color: btn.active ? Theme.color.fgSurface : Theme.color.fgSurfaceVariant
        }

        MouseArea {
            id: bma
            anchors.fill: parent
            anchors.margins: -5
            enabled: btn.active
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.clicked()
        }
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: Theme.space.md

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            Text {
                text: "\ue3ae"   // brightness_5
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.primary
            }
            ThemedText {
                text: "Яскравість дисплеїв"
                style: Theme.type.titleSmall
                Layout.fillWidth: true
            }
            ThemedText {
                text: root.masterPercent + "%"
                style: Theme.type.titleSmall
                color: Theme.color.primary
            }
            Text {
                text: "\ue5d5"   // refresh
                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                color: Theme.color.fgSurfaceVariant
                opacity: root.scanning ? 0.45 : 1
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refresh()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            StepButton {
                icon: "\ue15b"   // remove
                active: root.hasDevices && root.masterPercent > 0
                onClicked: root.step(-10)
            }

            BrightnessSlider {
                id: masterSlider
                Layout.fillWidth: true
                enabled: root.hasDevices
                value: root.masterPercent
                onCommit: function(value) { root.setAll(value) }
            }

            StepButton {
                icon: "\ue145"   // add
                active: root.hasDevices && root.masterPercent < 100
                onClicked: root.step(10)
            }
        }

        ThemedText {
            visible: root.hasDevices
            Layout.fillWidth: true
            text: "Вбудованих: " + root.backlightDevices.length
                  + " · DDC/CI: " + root.ddcMonitors.length
            style: Theme.type.labelSmall
            color: Theme.color.fgSurfaceVariant
        }

        ThemedText {
            visible: !root.hasDevices && !root.scanning
            Layout.fillWidth: true
            text: "Яскравість недоступна. Перевір brightnessctl і ddcutil."
            style: Theme.type.labelMedium
            color: Theme.color.fgSurfaceVariant
            wrapMode: Text.WordWrap
        }

        ThemedText {
            visible: root.ddcError && root.ddcMonitors.length > 0
            Layout.fillWidth: true
            text: "DDC/CI: частину моніторів не вдалося прочитати."
            style: Theme.type.labelSmall
            color: Theme.color.fgSurfaceVariant
            wrapMode: Text.WordWrap
        }
    }
}
