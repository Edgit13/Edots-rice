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

        SectionLabel { label: "Network" }

        Card {
            title: "Polling"

            SliderRow {
                category: "network"; configKey: "pollMs"
                label: "Stats poll interval"; from: 1000; to: 60000; stepSize: 1000; suffix: " ms"
                description: "How often to read network speed statistics."
            }
        }

        Card {
            title: "Display"

            SwitchRow {
                category: "network"; configKey: "showTooltip"
                label: "Show speed tooltip"
                description: "Display upload/download speed on hover."
            }
        }
    }
}
