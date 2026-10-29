pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings"
import QtQuick
import QtQuick.Layouts

// WeatherPanel — погода у планувальнику: зараз, найближчі години, 3 дні. Дані — WeatherService (wttr.in).
DashCard {
    id: root

    function _t(v) { return isNaN(v) ? "—" : Math.round(v) + "°" }
    function _day(d, i) {
        if (i === 0) return Lang.t("ui.weather.today")
        if (i === 1) return Lang.t("ui.weather.tomorrow")
        return Lang.t("ui.dow." + ((d.getDay() + 6) % 7))
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space.md

        // ---- зараз ----
        RowLayout {
            Layout.fillWidth: true
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
                Layout.fillWidth: true
                spacing: 0
                RowLayout {
                    spacing: Theme.space.sm
                    ThemedText {
                        text: WeatherService.loading || WeatherService.error ? "—" : root._t(WeatherService.temperatureC) + "C"
                        style: Theme.type.displaySmall
                        emphasized: true
                    }
                    ThemedText {
                        Layout.alignment: Qt.AlignBottom
                        Layout.bottomMargin: Theme.space.xs
                        visible: !WeatherService.loading && !WeatherService.error
                        text: "↑" + root._t(WeatherService.highC) + "  ↓" + root._t(WeatherService.lowC)
                        style: Theme.type.labelMedium
                        color: Theme.color.fgSurfaceVariant
                    }
                }
                ThemedText {
                    Layout.fillWidth: true
                    text: WeatherService.loading ? Lang.t("ui.weather.loading")
                        : WeatherService.error ? Lang.t("ui.weather.error")
                        : WeatherService.description + (WeatherService.city.length > 0 ? "  ·  " + WeatherService.city : "")
                    style: Theme.type.bodyMedium
                    color: Theme.color.fgSurfaceVariant
                    elide: Text.ElideRight
                }
            }

            // оновити
            Rectangle {
                Layout.preferredWidth: Theme.components.dp(36)
                Layout.preferredHeight: Theme.components.dp(36)
                Layout.alignment: Qt.AlignTop
                radius: refMa.pressed ? Theme.shape.iconButtonPressed : height / 2
                color: refMa.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainer, Theme.color.fgSurface, Theme.components.stateHover) : "transparent"
                Behavior on radius { MotionAnimation { role: "morph" } }
                Text {
                    id: refIcon
                    anchors.centerIn: parent
                    text: "\ue5d5"                                           // refresh
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                    color: Theme.color.fgSurfaceVariant
                    RotationAnimator on rotation { running: WeatherService.loading; loops: Animation.Infinite; from: 0; to: 360; duration: 900 }
                }
                MouseArea { id: refMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: WeatherService.refresh() }
            }
        }

        // ---- деталі ----
        Flow {
            Layout.fillWidth: true
            spacing: Theme.space.xs
            visible: !WeatherService.loading && !WeatherService.error
            Repeater {
                model: [
                    { ok: !isNaN(WeatherService.feelsLikeC), icon: "\ue1ff", text: Lang.t("ui.weather.feels") + " " + root._t(WeatherService.feelsLikeC) },
                    { ok: WeatherService.humidity >= 0, icon: "\ue798", text: WeatherService.humidity + "%" },
                    { ok: !isNaN(WeatherService.windKmh), icon: "\uefd8", text: Math.round(WeatherService.windKmh) + " " + Lang.t("ui.weather.kmh") },
                    { ok: WeatherService.sunrise.length > 0, icon: "\ue1c6", text: WeatherService.sunrise + " – " + WeatherService.sunset }
                ]
                Rectangle {
                    id: chip
                    required property var modelData
                    implicitHeight: Theme.components.dp(26)
                    implicitWidth: chipRow.implicitWidth + Theme.space.md
                    radius: Theme.shape.chip
                    color: Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainerHighest
                    border.width: Theme.settings.nothing ? 1 : 0
                    border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.2)
                    visible: chip.modelData.ok
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Theme.space.xs
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.icon
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                            color: Theme.color.fgSurfaceVariant
                        }
                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData.text
                            style: Theme.type.labelSmall
                            color: Theme.color.fgSurface
                        }
                    }
                }
            }
        }

        // ---- найближчі години ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.xs
            visible: WeatherService.hourly.length > 0
            Repeater {
                model: WeatherService.hourly
                Rectangle {
                    id: hcell
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.components.dp(64)
                    radius: Theme.shape.md
                    color: Theme.settings.nothing ? "transparent" : (index === 0 ? Theme.color.secondaryContainer : Theme.color.surfaceContainerHighest)
                    border.width: Theme.settings.nothing ? 1 : 0
                    border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, index === 0 ? 0.6 : 0.18)
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (hcell.modelData.hour < 10 ? "0" : "") + hcell.modelData.hour + ":00"
                            style: Theme.type.labelSmall
                            color: Theme.color.fgSurfaceVariant
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: WeatherService.iconFor(hcell.modelData.code)
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                            color: Theme.color.primary
                        }
                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root._t(hcell.modelData.tempC)
                            style: Theme.type.labelMedium
                            emphasized: true
                        }
                    }
                }
            }
        }

        // ---- 3 дні ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.xs
            visible: WeatherService.forecast.length > 0
            Repeater {
                model: WeatherService.forecast
                Rectangle {
                    id: dcell
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.components.dp(44)
                    radius: Theme.shape.md
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.color.outlineVariant
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.space.sm
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: WeatherService.iconFor(dcell.modelData.code)
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                            color: Theme.color.primary
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            ThemedText { text: root._day(dcell.modelData.date, dcell.index); style: Theme.type.labelSmall; color: Theme.color.fgSurfaceVariant }
                            ThemedText {
                                text: root._t(dcell.modelData.maxC) + " / " + root._t(dcell.modelData.minC)
                                style: Theme.type.labelMedium
                                emphasized: true
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
