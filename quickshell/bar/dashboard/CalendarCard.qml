import "root:/theme"
import Quickshell
import QtQuick
import QtQuick.Layouts

// CalendarCard — компактний блок "число/час" + сітка місяця, як у референсі.
DashCard {
    id: root

    SystemClock { id: clk; precision: SystemClock.Minutes }

    readonly property date today: clk.date
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()   // 0-based

    function shiftMonth(d) {
        let m = viewMonth + d, y = viewYear
        if (m < 0) { m = 11; y -= 1 }
        if (m > 11) { m = 0; y += 1 }
        viewMonth = m; viewYear = y
    }

    readonly property var dayNames: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Нд"]
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1)
        const startOffset = (first.getDay() + 6) % 7   // понеділок = 0
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        const arr = []
        for (let i = 0; i < startOffset; i++) arr.push(null)
        for (let d = 1; d <= daysInMonth; d++) arr.push(d)
        while (arr.length % 7 !== 0) arr.push(null)
        return arr
    }
    readonly property var monthNames: ["Січень", "Лютий", "Березень", "Квітень", "Травень", "Червень",
        "Липень", "Серпень", "Вересень", "Жовтень", "Листопад", "Грудень"]

    RowLayout {
        width: parent.width
        spacing: Theme.space.lg

        ColumnLayout {
            spacing: 2
            ThemedText { text: Qt.formatDateTime(root.today, "d"); style: Theme.type.displaySmall; emphasized: true }
            ThemedText { text: Qt.formatDateTime(root.today, "MMM"); style: Theme.type.labelMedium; color: Theme.color.fgSurfaceVariant }
        }

        ColumnLayout {
            spacing: Theme.space.xs
            Layout.fillWidth: true

            RowLayout {
                Layout.fillWidth: true
                ThemedText { text: root.monthNames[root.viewMonth] + " " + root.viewYear; style: Theme.type.labelLarge; Layout.fillWidth: true }
                Text { text: "\ue5cb"; font { family: Theme.type.icons; pixelSize: Theme.type.iconXS } color: Theme.color.fgSurfaceVariant
                       MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root.shiftMonth(-1) } }
                Text { text: "\ue5cc"; font { family: Theme.type.icons; pixelSize: Theme.type.iconXS } color: Theme.color.fgSurfaceVariant
                       MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: root.shiftMonth(1) } }
            }

            GridLayout {
                columns: 7
                columnSpacing: 2
                rowSpacing: 2
                Repeater {
                    model: root.dayNames
                    ThemedText { required property string modelData; text: modelData; style: Theme.type.labelSmall
                                 color: Theme.color.fgSurfaceVariant; horizontalAlignment: Text.AlignHCenter
                                 Layout.preferredWidth: 24 }
                }
                Repeater {
                    model: root.cells
                    Item {
                        required property var modelData
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        readonly property bool isToday: modelData === root.today.getDate()
                                                       && root.viewMonth === root.today.getMonth()
                                                       && root.viewYear === root.today.getFullYear()
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.shape.radius("full", height)
                            color: parent.isToday ? Theme.color.primary : "transparent"
                            visible: parent.modelData !== null
                        }
                        ThemedText {
                            anchors.centerIn: parent
                            visible: parent.modelData !== null
                            text: parent.modelData || ""
                            style: Theme.type.labelSmall
                            color: parent.isToday ? Theme.color.fgPrimary : Theme.color.fgSurface
                        }
                    }
                }
            }
        }
    }
}
