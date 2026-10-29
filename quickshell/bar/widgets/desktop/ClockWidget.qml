import "root:/theme"
import "root:/services"
import QtQuick
import Quickshell

// ClockWidget — digital (час + день + дата) або analog (стрілки). Формат бере з Settings → Годинник.
WidgetFrame {
    id: root
    kind: "clock"

    property real unit: 200

    SystemClock { id: sc; precision: ClockSettings.showSeconds ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property date shown: ClockSettings.displayDate(sc.date)
    readonly property bool analog: WidgetsConfig.clockStyle === "analog"

    // ---- digital ----
    Column {
        anchors.centerIn: parent
        visible: !root.analog
        spacing: 0
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.shown, ClockSettings.hour12 ? "h:mm" : "HH:mm")
            style: Theme.type.displayLarge
            font.pixelSize: root.unit * 0.27
            emphasized: true
            color: root.onColor
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.shown, "dddd")
            style: Theme.type.titleMedium
            font.pixelSize: root.unit * 0.085
            color: root.onColor
        }
        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.shown, ClockSettings.dateFormat)
            style: Theme.type.bodyMedium
            font.pixelSize: root.unit * 0.07
            color: Theme.alpha(root.onColor, 0.7)
        }
    }

    // ---- analog ----
    Item {
        id: face
        visible: root.analog
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width

        Repeater {
            model: 12
            Item {
                required property int index
                anchors.fill: parent
                rotation: index * 30
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 0
                    width: index % 3 === 0 ? 3 : 2
                    height: face.height * (index % 3 === 0 ? 0.08 : 0.045)
                    radius: width / 2
                    color: Theme.alpha(root.onColor, index % 3 === 0 ? 0.9 : 0.45)
                }
            }
        }
        Item {   // година
            anchors.fill: parent
            rotation: ((root.shown.getHours() % 12) + root.shown.getMinutes() / 60) * 30
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(4, face.height * 0.035); height: face.height * 0.26
                y: face.height / 2 - height; radius: width / 2; color: root.onColor
            }
        }
        Item {   // хвилина
            anchors.fill: parent
            rotation: root.shown.getMinutes() * 6 + root.shown.getSeconds() / 10
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(3, face.height * 0.025); height: face.height * 0.38
                y: face.height / 2 - height; radius: width / 2; color: root.onColor
            }
        }
        Item {   // секунди
            anchors.fill: parent
            visible: ClockSettings.showSeconds
            rotation: root.shown.getSeconds() * 6
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 2; height: face.height * 0.42
                y: face.height / 2 - height; radius: 1; color: root.accentColor
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: face.height * 0.07; height: width; radius: width / 2
            color: ClockSettings.showSeconds ? root.accentColor : root.onColor
        }
    }
}
