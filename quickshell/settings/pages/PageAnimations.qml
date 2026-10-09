pragma ComponentBehavior: Bound
import "../material"
import ".."
import "../controls"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    Layout.fillWidth: true
    width: parent ? parent.width : 0
    spacing: M3.s12

    SectionHeader { label: "Motion" }
    SettingsCard {
        title: "Global"
        RowSwitch { category: "animations"; configKey: "enabled"
            label: "Enable animations"
            description: "Master switch for every Behavior and transition." }
        RowSwitch { category: "animations"; configKey: "expressiveMotion"
            label: "Expressive motion"
            description: "Adds spring overshoot to spatial transitions." }
        RowSwitch { category: "animations"; configKey: "reduceMotion"
            label: "Reduce motion"
            description: "Instant spatial, minimal effects (accessibility)." }
        RowSlider { category: "animations"; configKey: "globalSpeed"
            label: "Global speed"; suffix: "×"; decimals: 2 }
    }
}
