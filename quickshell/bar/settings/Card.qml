pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Card — M3 tonal card (radius 16, surfaceContainer, без рамки).
Rectangle {
    id: card
    property string title: ""
    default property alias content: cardCol.children

    Layout.fillWidth: true
    radius: Md.rL
    color: Qt.rgba(Md.surfaceContainerHigh.r, Md.surfaceContainerHigh.g, Md.surfaceContainerHigh.b, 0.55)
    implicitHeight: cardCol.implicitHeight + 24

    ColumnLayout {
        id: cardCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        Text {
            visible: card.title.length > 0
            Layout.fillWidth: true
            text: card.title
            color: Md.onSurface
            font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
        }
    }
}
