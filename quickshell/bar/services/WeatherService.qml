pragma Singleton
import "root:/settings"
import QtQuick
import Quickshell

// WeatherService — wttr.in (format=j1, без ключа): зараз + погодинно + 3 дні.
// Місто — Settings → Загальні → «Місто для погоди» (порожньо = за IP). Тексти — через Lang.
Singleton {
    id: root

    property bool loading: true
    property bool error: false
    property string city: ""

    property real temperatureC: NaN
    property real feelsLikeC: NaN
    property int humidity: -1
    property int wttrCode: -1
    property real windKmh: NaN
    property real highC: NaN
    property real lowC: NaN
    property string sunrise: ""
    property string sunset: ""
    property var hourly: []          // [{hour, tempC, code, rain}]
    property var forecast: []        // [{date: Date, maxC, minC, code, rain}]

    readonly property string configCity: String(Settings.get("general", "weatherCity") || "").trim()
    readonly property string description: describe(wttrCode)
    readonly property string iconGlyph: iconFor(wttrCode)

    // worldweatheronline-коди wttr.in
    readonly property var _clear:   [113]
    readonly property var _cloudy:  [116, 119, 122]
    readonly property var _fog:     [143, 248, 260]
    readonly property var _thunder: [200, 386, 389, 392, 395]
    readonly property var _rain:    [176, 263, 266, 281, 284, 293, 296, 299, 302, 305, 308, 311, 314, 353, 356, 359]
    readonly property var _sleet:   [182, 185, 317, 320, 362, 365]
    readonly property var _snow:    [179, 227, 230, 323, 326, 329, 332, 335, 338, 350, 368, 371, 374, 377]

    function describe(code) {
        if (_clear.includes(code))   return Lang.t("ui.weather.clear")
        if (_cloudy.includes(code))  return Lang.t("ui.weather.cloudy")
        if (_fog.includes(code))     return Lang.t("ui.weather.fog")
        if (_thunder.includes(code)) return Lang.t("ui.weather.thunder")
        if (_rain.includes(code))    return Lang.t("ui.weather.rain")
        if (_sleet.includes(code))   return Lang.t("ui.weather.sleet")
        if (_snow.includes(code))    return Lang.t("ui.weather.snow")
        return code < 0 ? "" : Lang.t("ui.weather.unknown")
    }
    function iconFor(code) {
        if (_clear.includes(code))   return "\ue81a"      // clear_day
        if (_cloudy.includes(code))  return "\ue2bd"      // cloud
        if (_fog.includes(code))     return "\ue818"      // foggy
        if (_thunder.includes(code)) return "\ue1ec"      // thunderstorm
        if (_rain.includes(code))    return "\ue798"      // rainy
        if (_sleet.includes(code))   return "\ue3aa"      // weather_mix
        if (_snow.includes(code))    return "\ue2cd"      // weather_snowy
        return "\ue9e3"
    }

    function _parseDate(s) {                              // "2026-10-18" → Date (локальна північ)
        const p = s.split("-")
        return new Date(parseInt(p[0]), parseInt(p[1]) - 1, parseInt(p[2]))
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
                root.windKmh = parseFloat(cur.windspeedKmph)

                const area = d.nearest_area && d.nearest_area[0]
                if (area) {
                    const name = area.areaName?.[0]?.value || ""
                    const region = area.region?.[0]?.value || ""
                    root.city = region && region !== name ? (name + ", " + region) : name
                }

                // дні
                const days = d.weather || []
                const fc = []
                for (let i = 0; i < days.length; i++) {
                    const day = days[i]
                    let rain = 0
                    for (let h = 0; h < day.hourly.length; h++) rain = Math.max(rain, parseInt(day.hourly[h].chanceofrain) || 0)
                    const noon = day.hourly[Math.min(4, day.hourly.length - 1)]
                    fc.push({ date: root._parseDate(day.date), maxC: parseFloat(day.maxtempC), minC: parseFloat(day.mintempC),
                              code: parseInt(noon.weatherCode), rain: rain })
                }
                root.forecast = fc
                if (days.length > 0) {
                    root.highC = parseFloat(days[0].maxtempC)
                    root.lowC = parseFloat(days[0].mintempC)
                    const astro = days[0].astronomy && days[0].astronomy[0]
                    root.sunrise = astro ? astro.sunrise : ""
                    root.sunset = astro ? astro.sunset : ""
                }

                // найближчі години (кроки по 3 год)
                const now = new Date(), hr = []
                for (let i = 0; i < Math.min(2, days.length); i++) {
                    const base = root._parseDate(days[i].date)
                    for (let h = 0; h < days[i].hourly.length; h++) {
                        const e = days[i].hourly[h]
                        const hh = Math.floor(parseInt(e.time) / 100)
                        const t = new Date(base.getFullYear(), base.getMonth(), base.getDate(), hh)
                        if (t.getTime() < now.getTime() - 90 * 60 * 1000) continue
                        hr.push({ hour: hh, tempC: parseFloat(e.tempC), code: parseInt(e.weatherCode), rain: parseInt(e.chanceofrain) || 0 })
                    }
                }
                root.hourly = hr.slice(0, 6)
                root.error = false
            } catch (e) { root.error = true }
        }
        xhr.open("GET", "https://wttr.in/" + (configCity.length > 0 ? encodeURIComponent(configCity) : "") + "?format=j1")
        xhr.send()
    }

    Connections {
        target: Settings
        function onChanged(cat, key, value) { if (cat === "general" && key === "weatherCity") root.refresh() }
    }

    Component.onCompleted: refresh()
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
}
