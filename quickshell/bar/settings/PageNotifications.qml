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

        SectionLabel { label: "Notifications" }

        Card {
            title: "Position"

            DropdownRow {
                category: "notifications"; configKey: "positionX"
                label: "Horizontal position"
                options: ["left", "center", "right"]
                description: "Passed to swaync. Requires swaync reload."
            }
            DropdownRow {
                category: "notifications"; configKey: "positionY"
                label: "Vertical position"
                options: ["top", "bottom"]
                description: "Passed to swaync. Requires swaync reload."
            }
        }

        Card {
            title: "Timing"

            SliderRow {
                category: "notifications"; configKey: "timeoutSec"
                label: "Normal timeout"; from: 1; to: 60; suffix: " s"
            }
            SliderRow {
                category: "notifications"; configKey: "timeoutLowSec"
                label: "Low-priority timeout"; from: 1; to: 30; suffix: " s"
            }
        }

        Card {
            title: "Appearance"

            SliderRow {
                category: "notifications"; configKey: "width"
                label: "Popup width"; from: 200; to: 800; stepSize: 10; suffix: " px"
            }
            SliderRow {
                category: "notifications"; configKey: "iconSize"
                label: "Icon size"; from: 16; to: 96; suffix: " px"
            }
            SliderRow {
                category: "notifications"; configKey: "transitionMs"
                label: "Transition duration"; from: 0; to: 1000; stepSize: 10; suffix: " ms"
            }
        }

        Card {
            title: "Note"

            InfoRow {
                title: "swaync config"
                detail: "These values are stored in settings.json. Applying them to swaync requires a separate sync step (planned)."
            }
        }
    }
}
