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

        SectionLabel { label: "Media" }

        Card {
            title: "Display"

            SwitchRow {
                category: "media"; configKey: "showAlbumArt"
                label: "Show album art"
            }
            SwitchRow {
                category: "media"; configKey: "showProgress"
                label: "Show progress bar"
                description: "Progress bar is not yet implemented (planned)."
            }
        }

        Card {
            title: "Controls"

            SliderRow {
                category: "media"; configKey: "controlsSize"
                label: "Control icon size"; from: 16; to: 48; suffix: " px"
            }
            SliderRow {
                category: "media"; configKey: "controlsSpacing"
                label: "Control spacing"; from: 8; to: 60; suffix: " px"
            }
        }
    }
}
