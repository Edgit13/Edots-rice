pragma ComponentBehavior: Bound
import "root:/"
import QtQuick
import QtQuick.Layouts

// Material 3 SegmentedButtons: options=[{icon,label}], selectedIndex.
Rectangle {
    id: seg
    property var options: []
    property int selectedIndex: 0
    signal selected(int index)

    Layout.fillWidth: true
    implicitHeight: 38
    radius: M3.rFull
    color: M3.surfaceContainerHigh
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 0

        Repeater {
            model: seg.options
            Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: M3.rFull
                color: seg.selectedIndex === index
                    ? M3.secondaryContainer
                    : (ma.containsMouse ? M3.hoverOf(M3.surfaceContainerHighest) : "transparent")
                Behavior on color { ColorAnimation { duration: M3.durFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: M3.s4
                    Text {
                        visible: modelData.icon !== undefined && modelData.icon.length > 0
                        text: modelData.icon || ""
                        color: seg.selectedIndex === index ? M3.m3OnSecondaryContainer : M3.m3OnSurface
                        font { family: "Material Symbols Rounded"; pixelSize: 16 }
                    }
                    Text {
                        text: modelData.label || String(modelData)
                        color: seg.selectedIndex === index ? M3.m3OnSecondaryContainer : M3.m3OnSurface
                        font: M3.labelLarge
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        seg.selectedIndex = index
                        seg.selected(index)
                    }
                }
            }
        }
    }
}
