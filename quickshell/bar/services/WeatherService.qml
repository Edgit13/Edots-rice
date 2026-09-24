pragma Singleton
import QtQuick
import Quickshell

// WeatherService — погода з wttr.in (format=j1, автовизначення міста по IP, без ключа).
// Один HTTP-запит замість окремої геолокації + окремого прогнозу.
Singleton {
    id: root

    property bool loading: true
    property bool error: false
    property string city: ""

    property real temperatureC: NaN
    property real feelsLikeC: NaN
    property int humidity: -1
    property int wttrCode: -1

    readonly property string description: _describe(wttrCode)
    readonly property string iconGlyph: _icon(wttrCode)

    // worldweatheronline-коди, які повертає wttr.in (current_condition[0].weatherCode)
    readonly property var _clear:   [113]
    readonly property var _cloudy:  [116, 119, 122]
    readonly property var _fog:     [143, 248, 260]
    readonly property var _thunder: [200, 386, 389, 392, 395]
    readonly property var _rain:    [176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359]
    readonly property var _sleet:   [182, 185, 317, 320, 362, 365]
    readonly property var _snow:    [179, 227, 230, 323, 326, 329, 332, 335, 338, 350, 368, 371, 374, 377]

    function _describe(code) {
        if (_clear.includes(code)) return "Ясно"
        if (_cloudy.includes(code)) return "Хмарно"
        if (_fog.includes(code)) return "Туман"
        if (_thunder.includes(code)) return "Гроза"
        if (_rain.includes(code)) return "Дощ"
        if (_sleet.includes(code)) return "Мокрий сніг"
        if (_snow.includes(code)) return "Сніг"
        return code < 0 ? "" : "Невідомо"
    }
    function _icon(code) {
        if (_clear.includes(code)) return "\ue81a"      // clear_day
        if (_cloudy.includes(code)) return "\ue2bd"      // cloud
        if (_fog.includes(code)) return "\ue818"         // foggy
        if (_thunder.includes(code)) return "\ue1ec"      // thunderstorm
        if (_rain.includes(code)) return "\ue798"        // rainy
        if (_sleet.includes(code)) return "\ue3aa"       // weather_mix
        if (_snow.includes(code)) return "\ue2cd"        // weather_snowy
        return "\ue9e3"                                  // help/unknown
    }

    function refresh() {
        root.loading = true
        root.error = false
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            root.loading = false
            if (xhr.status !== 200) { root.error = true; return }
            try {
                const d = JSON.parse(xhr.responseText)
                const cur = d.current_condition[0]
                root.temperatureC = parseFloat(cur.temp_C)
                root.feelsLikeC = parseFloat(cur.FeelsLikeC)
                root.humidity = parseInt(cur.humidity)
                root.wttrCode = parseInt(cur.weatherCode)

                const area = d.nearest_area && d.nearest_area[0]
                if (area) {
                    const name = area.areaName?.[0]?.value || ""
                    const region = area.region?.[0]?.value || ""
                    root.city = region && region !== name ? (name + ", " + region) : name
                }
                root.error = false
            } catch (e) { root.error = true }
        }
        xhr.open("GET", "https://wttr.in/?format=j1")
        xhr.send()
    }

    Component.onCompleted: refresh()
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
}
