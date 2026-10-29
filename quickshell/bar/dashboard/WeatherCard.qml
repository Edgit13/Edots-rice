import "root:/theme"
import "root:/services"
import "root:/settings"
import QtQuick
import QtQuick.Layouts

// WeatherCard — компактна погода для Overview: значок у squircle, температура, опис, min/max, відчувається.
DashCard {
    id: root

    function _t(v) { return isNaN(v) ? "—" : Math.round(v) + "°" }

    RowLayout {
        width: parent.width
        height: implicitHeight
        spacing: Theme.space.md

        Rectangle {
            Layout.preferredWidth: Theme.components.dp(64)
            Layout.preferredHeight: Theme.components.dp(64)
            radius: Theme.shape.radius("lg", height)
            color: Theme.settings.nothing ? "transparent" : Theme.color.primaryContainer
            border.width: Theme.settings.nothing ? 1 : 0
            border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.28)
            Text {
                anchors.centerIn: parent
                text: WeatherService.iconGlyph
                font { family: Theme.type.icons; pixelSize: Theme.type.iconXL }
                color: Theme.color.fgPrimaryContainer
                opacity: WeatherService.loading ? 0.4 : 1
                Behavior on opacity { MotionAnimation { role: "fade" } }
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            ThemedText {
                visible: WeatherService.loading
                text: Lang.t("ui.weather.loading")
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
            }
            ThemedText {
                visible: WeatherService.error && !WeatherService.loading
                text: Lang.t("ui.weather.error")
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
            }
            ThemedText {
                visible: !WeatherService.loading && !WeatherService.error
                text: root._t(WeatherService.temperatureC) + "C"
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
                visible: !WeatherService.loading && !WeatherService.error
                text: "↑" + root._t(WeatherService.highC) + "  ↓" + root._t(WeatherService.lowC)
                         + (isNaN(WeatherService.feelsLikeC) ? "" : "  ·  " + Lang.t("ui.weather.feels") + " " + root._t(WeatherService.feelsLikeC))
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
            }
            ThemedText {
                visible: WeatherService.city.length > 0
                text: WeatherService.city
                style: Theme.type.labelSmall
                color: Theme.color.outline
            }
        }
    }
}
