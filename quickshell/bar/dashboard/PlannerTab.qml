import "root:/theme"
import QtQuick
import QtQuick.Layouts

// PlannerTab — планувальник: ліворуч погода і календар, праворуч список справ.
// Вибраний у календарі день фільтрує справи й стає датою для нових.
Flickable {
    id: root

    property string selectedDay: ""

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: Math.max(height, Theme.components.dp(580))

    Item {
        width: root.width
        height: root.contentHeight

        RowLayout {
            id: row
            anchors.fill: parent
            spacing: Theme.space.md

            // ліва колонка має фіксовану ширину: min = max = preferred, щоб вона не могла
            // «з'їсти» увесь рядок і витиснути список справ
            readonly property real leftW: Math.round((width - spacing) * 0.46)

            ColumnLayout {
                Layout.preferredWidth: row.leftW
                Layout.minimumWidth: row.leftW
                Layout.maximumWidth: row.leftW
                Layout.fillHeight: true
                spacing: Theme.space.md

                WeatherPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.components.dp(292)
                }
                CalendarPanel {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    selectedDay: root.selectedDay
                    onDaySelected: day => root.selectedDay = day
                }
            }

            TodoPanel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Theme.components.dp(260)
                selectedDay: root.selectedDay
                onDayCleared: root.selectedDay = ""
            }
        }
    }
}
