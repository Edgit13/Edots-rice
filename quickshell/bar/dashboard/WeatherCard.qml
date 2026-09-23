import "root:/theme"
import "root:/services"
import QtQuick
import QtQuick.Layouts

DashCard {
    id: root

    RowLayout {
        width: parent.width
        spacing: Theme.space.md

        Text {
            text: WeatherService.iconGlyph
            font { family: Theme.type.icons; pixelSize: Theme.type.iconXL * 1.4 }
            color: Theme.color.primary
            visible: !WeatherService.loading
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            ThemedText {
                visible: WeatherService.loading
                text: "Завантаження…"
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
            }
            ThemedText {
                visible: WeatherService.error && !WeatherService.loading
                text: "Погода недоступна"
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
            }
            ThemedText {
                visible: !WeatherService.loading && !WeatherService.error
                text: Math.round(WeatherService.temperatureC) + "°C"
                style: Theme.type.displaySmall
                emphasized: true
            }
            ThemedText {
                visible: !WeatherService.loading && !WeatherService.error
                text: WeatherService.description
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
            }
            ThemedText {
                visible: WeatherService.city.length > 0
                text: WeatherService.city
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
            }
        }
    }
}
