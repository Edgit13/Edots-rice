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

        SectionLabel { label: "Surfaces" }

        Card {
            title: "Geometry"

            SliderRow {
                category: "surfaces"; configKey: "margins"
                label: "Surface margins"; from: 0; to: 40; suffix: " px"
                description: "Gap between the pill and popup surfaces."
            }
            SliderRow {
                category: "surfaces"; configKey: "radius"
                label: "Corner radius"; from: 0; to: 40; suffix: " px"
            }
        }

        Card {
            title: "Row heights"

            SliderRow {
                category: "surfaces"; configKey: "wifiRowHeight"
                label: "Wi-Fi network row"; from: 28; to: 64; suffix: " px"
            }
            SliderRow {
                category: "surfaces"; configKey: "linkRowHeight"
                label: "Link row"; from: 32; to: 72; suffix: " px"
            }
            SliderRow {
                category: "surfaces"; configKey: "clipboardRowHeight"
                label: "Clipboard row"; from: 24; to: 56; suffix: " px"
            }
            SliderRow {
                category: "surfaces"; configKey: "powerRowHeight"
                label: "Power row"; from: 28; to: 56; suffix: " px"
            }
        }

        Card {
            title: "Controls"

            SliderRow {
                category: "surfaces"; configKey: "sliderHeight"
                label: "Slider track height"; from: 2; to: 16; suffix: " px"
            }
        }
    }
}
