pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ClockSettings — 12/24h, дата, секунди, часовий пояс.
// Persist: ~/.config/quickshell/clock.json (live). Stage 16 Settings UI викликає set().
//
// Часовий пояс: без UTC-офсету (utcOffsetMinutes: null) — показує локальний час пристрою.
// З офсетом — показує час іншого поясу за зсувом у хвилинах відносно UTC (напр. Kyiv влітку: 180).
// IANA-назви (Europe/Kyiv) не використовуються: у цій збірці Quickshell немає Intl у QML JS-рушії
// (перевірено), тож коректний переклад між поясами з урахуванням DST неможливий без нього.
Singleton {
    id: root

    readonly property bool hour12: a.hour12
    readonly property bool showSeconds: a.showSeconds
    readonly property string dateFormat: a.dateFormat            // qt date-format рядок для компактної дати
    readonly property string fullDateFormat: a.fullDateFormat    // те саме для розгорнутої картки
    readonly property var utcOffsetMinutes: a.utcOffsetMinutes   // null = локальний час пристрою
    readonly property string zoneLabel: a.zoneLabel              // довільна підпис зони ("Tokyo", "UTC+3"…)

    readonly property var dateFormatPresets: ["d MMMM", "dd.MM.yyyy", "yyyy-MM-dd", "MMM d, yyyy"]

    function set(key, value) {
        if (typeof a[key] === "undefined") { console.warn("[Clock] unknown setting: " + key); return }
        a[key] = value
    }
    function clearZone() { a.utcOffsetMinutes = null; a.zoneLabel = "" }
    function setZone(offsetMinutes, label) { a.utcOffsetMinutes = offsetMinutes; a.zoneLabel = label }

    // date, зсунута під obraний пояс (якщо є) — для формату Qt.formatDateTime у компонентах
    function displayDate(base) {
        if (utcOffsetMinutes === null || utcOffsetMinutes === undefined) return base
        const utcMs = base.getTime() + base.getTimezoneOffset() * 60000
        return new Date(utcMs + utcOffsetMinutes * 60000)
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/clock.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: function (error) {
            if (error === FileViewError.FileNotFound) writeAdapter()
        }

        adapter: JsonAdapter {
            id: a
            property bool hour12: false
            property bool showSeconds: false
            property string dateFormat: "d MMMM"
            property string fullDateFormat: "dddd, d MMMM"
            property var utcOffsetMinutes: null
            property string zoneLabel: ""
        }
    }
}
