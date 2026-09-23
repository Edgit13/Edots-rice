import "root:/theme"
import "root:/shell"
import "root:/services"
import Quickshell
import QtQuick
import QtQuick.Layouts

// ClockModule — M3 Expressive годинник: compact (пігулка) ⇄ expanded (час, день, дата,
// швидкі перемикачі 12/24h · секунди · пояс) через MorphSurface. Формат/пояс — з ClockSettings
// (Stage 16 Settings матиме ту саму модель, тут — вбудований мінімум налаштувань).
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

    SystemClock {
        id: sysClock
        precision: ClockSettings.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }
    readonly property date shown: ClockSettings.displayDate(sysClock.date)

    function _timeFormat() {
        const h = ClockSettings.hour12 ? "h:mm" : "HH:mm"
        const s = ClockSettings.showSeconds ? ":ss" : ""
        const ap = ClockSettings.hour12 ? " AP" : ""
        return h + s + ap
    }
    readonly property string timeStr: Qt.formatDateTime(shown, _timeFormat())
    readonly property string timeStrVertical: Qt.formatDateTime(shown, ClockSettings.hour12 ? "h\nmm" : "HH\nmm")
    readonly property string dateStr: Qt.formatDateTime(shown, ClockSettings.dateFormat)
    readonly property string fullDateStr: Qt.formatDateTime(shown, ClockSettings.fullDateFormat)
    readonly property string zoneSuffix: ClockSettings.zoneLabel.length > 0 ? " · " + ClockSettings.zoneLabel : ""

    implicitWidth: morph.implicitWidth
    implicitHeight: morph.implicitHeight

    // Хост (BarWindow) читає це, щоб дорахувати вікно й mask під розгорнуту картку
    readonly property alias overflowTop: morph.overflowTop
    readonly property alias overflowBottom: morph.overflowBottom
    readonly property alias overflowLeft: morph.overflowLeft
    readonly property alias overflowRight: morph.overflowRight
    readonly property alias hitArea: morph.bodyItem

    component ToggleChip: Rectangle {
        id: chip
        property string label: ""
        property bool active: false
        signal clicked()
        implicitWidth: chipLbl.implicitWidth + Theme.space.lg * 2
        implicitHeight: Theme.components.buttonXS
        radius: Theme.shape.radius("full", height)
        color: active ? Theme.color.primary
             : cma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
             : cma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
             : Theme.color.surfaceContainerHighest
        Behavior on color { MotionColorAnimation { role: "hover" } }
        ThemedText { id: chipLbl; anchors.centerIn: parent; text: chip.label; style: Theme.type.labelMedium
                     color: chip.active ? Theme.color.fgPrimary : Theme.color.fgSurface }
        MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }

    MorphSurface {
        id: morph
        originX: 0.5; originY: 0
        expandedWidth: 300
        expandedHeight: 280
        compact: [
            Row {
                visible: !root.vertical
                spacing: Theme.space.xs
                ThemedText { anchors.verticalCenter: parent.verticalCenter; text: root.timeStr
                             style: Theme.type.monoMedium; emphasized: true; color: Theme.color.fgSurface }
                Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 3; height: 3; radius: 1.5; color: Theme.color.outlineVariant }
                ThemedText { anchors.verticalCenter: parent.verticalCenter; text: root.dateStr
                             style: Theme.type.labelSmall; color: Theme.color.fgSurfaceVariant }
            },
            ThemedText {
                visible: root.vertical
                text: root.timeStrVertical
                style: Theme.type.monoSmall
                emphasized: true
                horizontalAlignment: Text.AlignHCenter
                color: Theme.color.fgSurface
            }
        ]
        expanded: [
            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.space.sm

                ThemedText { text: root.timeStr; style: Theme.type.displaySmall; emphasized: true }
                ThemedText { text: root.fullDateStr + root.zoneSuffix; style: Theme.type.bodyLarge; color: Theme.color.fgSurfaceVariant }

                Item { Layout.preferredHeight: Theme.space.xs }

                RowLayout {
                    spacing: Theme.space.xs
                    ThemedText { text: "Формат"; style: Theme.type.labelSmall; color: Theme.color.fgSurfaceVariant; Layout.preferredWidth: 64 }
                    ToggleChip { label: "24h"; active: !ClockSettings.hour12; onClicked: ClockSettings.set("hour12", false) }
                    ToggleChip { label: "12h"; active: ClockSettings.hour12; onClicked: ClockSettings.set("hour12", true) }
                    Item { Layout.fillWidth: true }
                    ToggleChip { label: "Секунди"; active: ClockSettings.showSeconds; onClicked: ClockSettings.set("showSeconds", !ClockSettings.showSeconds) }
                }

                RowLayout {
                    spacing: Theme.space.xs
                    ThemedText { text: "Пояс"; style: Theme.type.labelSmall; color: Theme.color.fgSurfaceVariant; Layout.preferredWidth: 64 }
                    ToggleChip { label: "Тут"; active: ClockSettings.zoneLabel.length === 0; onClicked: ClockSettings.clearZone() }
                    Repeater {
                        model: [["UTC", 0], ["Kyiv", 180], ["London", 60], ["Tokyo", 540]]
                        ToggleChip {
                            required property var modelData
                            label: modelData[0]
                            active: ClockSettings.zoneLabel === modelData[0]
                            onClicked: ClockSettings.setZone(modelData[1], modelData[0])
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        ]
        onClicked: toggle()
    }
}
