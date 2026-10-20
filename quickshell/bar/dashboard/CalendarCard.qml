import "root:/theme"
import "root:/services"
import "root:/settings"
import Quickshell
import QtQuick
import QtQuick.Layouts

// CalendarCard — компактний блок "число/час" + сітка місяця.
DashCard {
    id: root

    SystemClock { id: clk; precision: SystemClock.Minutes }

    readonly property date today: clk.date
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    function shiftMonth(d) {
        let m = viewMonth + d, y = viewYear
        if (m < 0) { m = 11; y -= 1 }
        if (m > 11) { m = 0; y += 1 }
        viewMonth = m; viewYear = y
    }

    readonly property var dayNames: [0, 1, 2, 3, 4, 5, 6].map(i => Lang.t("ui.dow." + i))
    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1)
        const startOffset = (first.getDay() + 6) % 7
        const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        const arr = []
        for (let i = 0; i < startOffset; i++) arr.push(null)
        for (let d = 1; d <= daysInMonth; d++) arr.push(d)
        while (arr.length % 7 !== 0) arr.push(null)
        return arr
    }

    component NavButton: Rectangle {
        id: btn
        property string icon: ""
        signal clicked()

        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: nma.pressed
             ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
             : nma.containsMouse
                 ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
                 : "transparent"
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Text {
            anchors.centerIn: parent
            text: btn.icon
            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
            color: Theme.color.fgSurfaceVariant
        }

        MouseArea {
            id: nma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    RowLayout {
        width: parent.width
        height: implicitHeight
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
                spacing: Theme.space.xs
                ThemedText {
                    text: Lang.t("ui.month." + root.viewMonth) + " " + root.viewYear
                    style: Theme.type.labelLarge
                    Layout.fillWidth: true
                }
                NavButton { icon: "\ue5cb"; onClicked: root.shiftMonth(-1) }
                NavButton { icon: "\ue5cc"; onClicked: root.shiftMonth(1) }
            }

            GridLayout {
                columns: 7
                columnSpacing: 2
                rowSpacing: 2
                Repeater {
                    model: root.dayNames
                    ThemedText {
                        required property string modelData
                        text: modelData
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        Layout.preferredWidth: 24
                    }
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
                        Rectangle {                                    // є активні справи на цей день
                            readonly property string key: parent.modelData === null ? "" :
                                root.viewYear + "-" + (root.viewMonth < 9 ? "0" : "") + (root.viewMonth + 1) + "-" + (parent.modelData < 10 ? "0" : "") + parent.modelData
                            visible: key.length > 0 && (TodoService.dueMap[key] || 0) > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1
                            width: 4; height: 4; radius: 2
                            color: parent.isToday ? Theme.color.fgPrimary : Theme.color.primary
                        }
                    }
                }
            }
        }
    }
}
