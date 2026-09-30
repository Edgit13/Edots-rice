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

        SectionLabel { label: "Workspaces" }

        Card {
            title: "Layout"

            SliderRow {
                category: "workspaces"; configKey: "count"
                label: "Workspace count"; from: 1; to: 20; stepSize: 1
            }
            SliderRow {
                category: "workspaces"; configKey: "spacing"
                label: "Button spacing"; from: 0; to: 20; suffix: " px"
            }
            SliderRow {
                category: "workspaces"; configKey: "buttonWidth"
                label: "Button width"; from: 16; to: 48; suffix: " px"
            }
            SliderRow {
                category: "workspaces"; configKey: "buttonHeight"
                label: "Button height"; from: 16; to: 48; suffix: " px"
            }
            SliderRow {
                category: "workspaces"; configKey: "radius"
                label: "Button radius"; from: 0; to: 20; suffix: " px"
            }
        }

        Card {
            title: "Display"

            SwitchRow {
                category: "workspaces"; configKey: "showNumbers"
                label: "Show workspace numbers"
            }
        }
    }
}
