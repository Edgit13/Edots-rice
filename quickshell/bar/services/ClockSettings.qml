pragma Singleton
import "root:/settings"
import QtQuick
import Quickshell

// ClockSettings — тонкий фасад над Settings (категорія "clock").
Singleton {
    id: root

    readonly property bool hour12:             Settings.get("clock", "hour12")
    readonly property bool showSeconds:        Settings.get("clock", "showSeconds")
    readonly property string dateFormat:       Settings.get("clock", "dateFormat")
    readonly property string fullDateFormat:   Settings.get("clock", "fullDateFormat")
    readonly property var utcOffsetMinutes:    Settings.get("clock", "utcOffsetMinutes")
    readonly property string zoneLabel:        Settings.get("clock", "zoneLabel")

    readonly property var dateFormatPresets: ["d MMMM", "dd.MM.yyyy", "yyyy-MM-dd", "MMM d, yyyy"]

    function set(key, value) { Settings.set("clock", key, value) }
    function clearZone() {
        Settings.set("clock", "utcOffsetMinutes", null)
        Settings.set("clock", "zoneLabel", "")
    }
    function setZone(offsetMinutes, label) {
        Settings.set("clock", "utcOffsetMinutes", offsetMinutes)
        Settings.set("clock", "zoneLabel", label)
    }

    function displayDate(base) {
        if (utcOffsetMinutes === null || utcOffsetMinutes === undefined) return base
        const utcMs = base.getTime() + base.getTimezoneOffset() * 60000
        return new Date(utcMs + utcOffsetMinutes * 60000)
    }
}
