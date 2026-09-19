import "root:/"
import Quickshell
import QtQuick

// Clock module — Material 3 (mono, onSurfaceVariant / accent секунди).
Item {
    id: root
    implicitWidth: timeText.implicitWidth
    implicitHeight: timeText.implicitHeight

    property bool showSeconds: false

    Text {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatTime(new Date(), root.showSeconds ? "hh:mm:ss" : "hh:mm")
        color: M3.m3OnSurfaceVariant
        font: M3.monoLarge

        Timer {
            interval: 1000
            repeat: true
            running: true
            onTriggered: timeText.text = Qt.formatTime(new Date(), root.showSeconds ? "hh:mm:ss" : "hh:mm")
        }
    }
}
