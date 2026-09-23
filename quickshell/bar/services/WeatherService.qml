pragma Singleton
import QtQuick
import Quickshell

// WeatherService — IP-геолокація (ipapi.co) + погода (Open-Meteo, без ключа).
// Оновлення що 30 хв. Обидва запити — XMLHttpRequest (є в цьому Qt/QML движку, перевірено).
Singleton {
    id: root

    property bool loading: true
    property bool error: false
    property string city: ""
    property real latitude: NaN
    property real longitude: NaN

    property real temperatureC: NaN
    property int weatherCode: -1
    property bool isDay: true

    readonly property string description: _describe(weatherCode)
    readonly property string iconGlyph: _icon(weatherCode, isDay)

    function _describe(code) {
        if (code < 0) return ""
        if (code === 0) return "Ясно"
        if (code <= 2) return "Мінлива хмарність"
        if (code === 3) return "Хмарно"
        if (code === 45 || code === 48) return "Туман"
        if (code >= 51 && code <= 57) return "Мряка"
        if (code >= 61 && code <= 67) return "Дощ"
        if (code >= 71 && code <= 77) return "Сніг"
        if (code >= 80 && code <= 82) return "Зливи"
        if (code >= 85 && code <= 86) return "Снігопад"
        if (code >= 95) return "Гроза"
        return "Невідомо"
    }
    function _icon(code, day) {
        if (code < 0) return "\ue9e3"                          // help/unknown
        if (code === 0) return day ? "\ue81a" : "\uef1e"        // clear_day / clear_night(ish)
        if (code <= 2) return day ? "\ue42d" : "\uef1d"         // partly_cloudy_day/night
        if (code === 3) return "\ue2bd"                         // cloud
        if (code === 45 || code === 48) return "\ue818"         // foggy
        if (code >= 51 && code <= 67) return "\ue798"           // rainy
        if (code >= 71 && code <= 86) return "\ue2cd"           // weather_snowy
        if (code >= 95) return "\ue1ec"                         // thunderstorm
        return "\ue9e3"
    }

    function refresh() { _locate() }

    function _locate() {
        root.loading = true
        root.error = false
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            if (xhr.status !== 200) { root.error = true; root.loading = false; return }
            try {
                const d = JSON.parse(xhr.responseText)
                root.city = d.city || d.region || ""
                root.latitude = parseFloat(d.latitude)
                root.longitude = parseFloat(d.longitude)
                _fetchWeather()
            } catch (e) { root.error = true; root.loading = false }
        }
        xhr.open("GET", "https://ipapi.co/json/")
        xhr.send()
    }

    function _fetchWeather() {
        if (isNaN(latitude) || isNaN(longitude)) { root.error = true; root.loading = false; return }
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            root.loading = false
            if (xhr.status !== 200) { root.error = true; return }
            try {
                const d = JSON.parse(xhr.responseText)
                const cw = d.current_weather
                root.temperatureC = cw.temperature
                root.weatherCode = cw.weathercode
                root.isDay = cw.is_day === 1
                root.error = false
            } catch (e) { root.error = true }
        }
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude + "&current_weather=true"
        xhr.open("GET", url)
        xhr.send()
    }

    Component.onCompleted: refresh()
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; onTriggered: root.refresh() }
}
