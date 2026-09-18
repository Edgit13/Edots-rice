import "root:/"
import Quickshell
import QtQuick

Item {
    id: root
    implicitWidth: timeText.implicitWidth
    implicitHeight: timeText.implicitHeight
    property bool showSeconds: false

    Text {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatTime(new Date(), root.showSeconds ? "hh:mm:ss" : "hh:mm")
        color: Colors.fg
        font { family: "SF Mono"; pixelSize: 15; weight: 600 }
        Timer {
            interval: 1000
            repeat: true
            running: true
            onTriggered: timeText.text = Qt.formatTime(new Date(), root.showSeconds ? "hh:mm:ss" : "hh:mm")
        }
    }
}
