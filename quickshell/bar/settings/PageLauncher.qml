pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "Launcher" }

        Card {
            title: "Layout"

            SliderRow {
                category: "launcher"; configKey: "fieldHeight"
                label: "Search field height"; from: 24; to: 64; suffix: " px"
            }
            SliderRow {
                category: "launcher"; configKey: "fieldRadius"
                label: "Search field radius"; from: 0; to: 24; suffix: " px"
            }
            SliderRow {
                category: "launcher"; configKey: "rowHeight"
                label: "Result row height"; from: 28; to: 80; suffix: " px"
            }
            SliderRow {
                category: "launcher"; configKey: "iconSize"
                label: "Icon size"; from: 16; to: 48; suffix: " px"
            }
            SliderRow {
                category: "launcher"; configKey: "rowSpacing"
                label: "Row spacing"; from: 0; to: 20; suffix: " px"
            }
            SliderRow {
                category: "launcher"; configKey: "iconTextSpacing"
                label: "Icon→text gap"; from: 4; to: 24; suffix: " px"
            }
        }

        Card {
            title: "Typography"

            SliderRow {
                category: "launcher"; configKey: "fontSize"
                label: "Primary font size"; from: 8; to: 20; suffix: " px"
            }
            SliderRow {
                category: "launcher"; configKey: "subFontSize"
                label: "Subtitle font size"; from: 7; to: 16; suffix: " px"
            }
        }

        Card {
            title: "Behaviour"

            SwitchRow {
                category: "launcher"; configKey: "showDescriptions"
                label: "Show app descriptions"
            }
            SliderRow {
                category: "launcher"; configKey: "maxResults"
                label: "Max results"; from: 5; to: 200; stepSize: 5
            }
        }
    }
}
