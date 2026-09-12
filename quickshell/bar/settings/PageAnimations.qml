pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// "Animations everywhere" — глобальні перемикачі, що керують Anim.ms()
// у барі та всім Settings UI.

Item {
    id: pageAnimationsRoot
    implicitHeight: animCol.implicitHeight

    ColumnLayout {
        id: animCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "Animations" }

        Card {
            title: "Playback"

            SwitchRow {
                category: "animations"; configKey: "enabled"
                label: "Enable animations"
                description: "Instantly disables every animated transition in the bar and Settings."
            }
            SliderRow {
                category: "animations"; configKey: "globalSpeed"
                label: "Global speed"; from: 0.25; to: 3.0
                stepSize: 0.05; decimals: 2; suffix: "\u00d7"
                description: "Multiplier for all animation durations. 2\u00d7 = twice as fast."
            }
        }

        Card {
            title: "Where it applies"

            InfoRow {
                title: "Bar"
                detail: "Pill morph, glow breathing, hover scale, icon pops, surface fades."
            }
            InfoRow {
                title: "Settings"
                detail: "Window open/close, page fades, sidebar transitions, sliders, buttons."
            }
            InfoRow {
                title: "Note"
                detail: "Per-element durations live on the Pill page; this page controls the global master switch and speed."
            }
        }
    }
}
