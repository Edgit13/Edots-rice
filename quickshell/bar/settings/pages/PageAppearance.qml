pragma ComponentBehavior: Bound
import "../material"
import ".."
import "../controls"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    Layout.fillWidth: true
    spacing: M3.s12

    SectionHeader { label: "Theme" }
    SettingsCard {
        title: "Mode & Color"
        RowDropdown { category: "appearance"; configKey: "mode"; label: "Color mode"
            description: "Follow the system theme or force dark/light." }
        RowSwitch { category: "appearance"; configKey: "dynamicColor"
            label: "Dynamic colors from wallpaper"
            description: "Reads the current wallpaper palette from colors.json." }
        RowColor { category: "appearance"; configKey: "accent"; label: "Custom accent"
            description: "Used when dynamic colors are off." }
    }

    SectionHeader { label: "Shape & Size" }
    SettingsCard {
        title: "Corner & Scale"
        RowDropdown { category: "appearance"; configKey: "cornerStyle"; label: "Corner style"
            description: "material | expressive | rounded." }
        RowSlider { category: "appearance"; configKey: "uiScale"; label: "UI scale"
            suffix: "×"; decimals: 2 }
    }
}
