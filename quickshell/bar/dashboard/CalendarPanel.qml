pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings"
import "root:/settings/material"
import Quickshell
import QtQuick
import QtQuick.Layouts

// CalendarPanel — місяць із вибором дня, «сьогодні» і крапками там, де є активні справи (TodoService).
DashCard {
    id: root

    property string selectedDay: ""                // "YYYY-MM-DD" або ""
    signal daySelected(string day)

    SystemClock { id: clk; precision: SystemClock.Minutes }
    readonly property string todayStr: TodoService.ymd(clk.date)

    property int viewYear: clk.date.getFullYear()
    property int viewMonth: clk.date.getMonth()

    function shiftMonth(d) {
        let m = viewMonth + d, y = viewYear
        while (m < 0) { m += 12; y -= 1 }
        while (m > 11) { m -= 12; y += 1 }
        viewMonth = m; viewYear = y
    }
    function goToday() { viewYear = clk.date.getFullYear(); viewMonth = clk.date.getMonth(); daySelected(todayStr) }

    // 42 клітинки: понеділок-перший
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1)
        const offset = (first.getDay() + 6) % 7
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(viewYear, viewMonth, 1 - offset + i)
            out.push({ day: d.getDate(), ymd: TodoService.ymd(d), inMonth: d.getMonth() === viewMonth })
        }
        return out
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space.sm

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.xs
            ThemedText {
                Layout.fillWidth: true
                text: Lang.t("ui.month." + root.viewMonth) + " " + root.viewYear
                style: Theme.type.titleMedium
                emphasized: true
            }
            MaterialButton {
                text: Lang.t("ui.cal.today")
                style: "tonal"
                implicitHeight: Theme.components.dp(32)
                onClicked: root.goToday()
            }
            MaterialIconButton { icon: "chevron_left"; width: Theme.components.dp(36); height: width; onClicked: root.shiftMonth(-1) }
            MaterialIconButton { icon: "chevron_right"; width: Theme.components.dp(36); height: width; onClicked: root.shiftMonth(1) }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            columnSpacing: 2
            rowSpacing: 2

            Repeater {
                model: 7
                ThemedText {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Lang.t("ui.dow." + index)
                    style: Theme.type.labelSmall
                    color: index > 4 ? Theme.color.tertiary : Theme.color.fgSurfaceVariant
                }
            }

            Repeater {
                model: root.cells
                Item {
                    id: cell
                    required property var modelData
                    readonly property bool isToday: modelData.ymd === root.todayStr
                    readonly property bool isSel: modelData.ymd === root.selectedDay
                    readonly property int due: TodoService.dueMap[modelData.ymd] || 0
                    readonly property bool overdue: due > 0 && modelData.ymd < root.todayStr

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Theme.components.dp(26)

                    Rectangle {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width
                        radius: ma.pressed ? Theme.shape.radius("md", height) : height / 2
                        color: cell.isToday ? Theme.color.primary
                             : cell.isSel ? Theme.color.secondaryContainer
                             : "transparent"
                        Behavior on radius { MotionAnimation { role: "morph" } }
                        Behavior on color { MotionColorAnimation { role: "stateChange" } }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.color.fgSurface
                            opacity: ma.containsMouse ? Theme.components.stateHover : 0
                            Behavior on opacity { MotionAnimation { role: "hover" } }
                        }
                    }
                    ThemedText {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: cell.due > 0 ? -2 : 0
                        text: cell.modelData.day
                        style: Theme.type.labelMedium
                        emphasized: cell.isToday || cell.isSel
                        color: cell.isToday ? Theme.color.fgPrimary
                             : cell.isSel ? Theme.color.fgSecondaryContainer
                             : cell.modelData.inMonth ? Theme.color.fgSurface : Theme.color.outline
                    }
                    Rectangle {                                    // крапка «є справи»
                        visible: cell.due > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: Math.min(parent.width, parent.height) * 0.3
                        width: 4; height: 4; radius: 2
                        color: cell.overdue ? Theme.color.error : (cell.isToday ? Theme.color.fgPrimary : Theme.color.primary)
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.daySelected(cell.isSel ? "" : cell.modelData.ymd)
                    }
                }
            }
        }
    }
}
