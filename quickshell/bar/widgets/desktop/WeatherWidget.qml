import "root:/theme"
import "root:/services"
import "root:/settings"
import QtQuick

// WeatherWidget — значок, температура, опис, місто (WeatherService).
WidgetFrame {
    id: root
    kind: "weather"

    property real unit: 200
    readonly property bool ready: !WeatherService.loading && !WeatherService.error

    Column {
        anchors.centerIn: parent
        width: parent.width
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ready ? WeatherService.iconGlyph : "\ue9e3"
            font { family: Theme.type.icons; pixelSize: root.unit * 0.24 }
            color: root.onColor
            opacity: root.ready ? 1 : 0.4
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.ready
            text: isNaN(WeatherService.temperatureC) ? "—" : Math.round(WeatherService.temperatureC) + "°"
            style: Theme.type.displayMedium
            font.pixelSize: root.unit * 0.2
            emphasized: true
            color: root.onColor
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: WeatherService.loading ? Lang.t("ui.weather.loading")
                : WeatherService.error ? Lang.t("ui.weather.error") : WeatherService.description
            style: Theme.type.titleSmall
            font.pixelSize: root.unit * 0.07
            color: Theme.alpha(root.onColor, 0.8)
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: root.ready && WeatherService.city.length > 0
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: WeatherService.city
            style: Theme.type.labelSmall
            font.pixelSize: root.unit * 0.055
            color: Theme.alpha(root.onColor, 0.6)
        }
    }
}
