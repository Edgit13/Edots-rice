pragma ComponentBehavior: Bound
import "../material"
import ".."
import "../controls"
import "../.."
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    width: parent ? parent.width : 0
    spacing: M3.s12

    SectionHeader { label: "Palette (live)" }
    Text {
        Layout.fillWidth: true
        text: "These write directly to ~/.config/quickshell/colors.json. Bar and lock screen repaint instantly."
        color: M3.m3OnSurfaceVariant
        font: M3.bodySmall
        wrapMode: Text.Wrap
    }

    SettingsCard {
        title: "Background"
        RowColor { category: "colors"; configKey: "bg0"; label: "bg0 — deepest" }
        RowColor { category: "colors"; configKey: "bg1"; label: "bg1 — surface" }
        RowColor { category: "colors"; configKey: "bg2"; label: "bg2 — container" }
        RowColor { category: "colors"; configKey: "bg3"; label: "bg3 — container high" }
        RowColor { category: "colors"; configKey: "bg4"; label: "bg4 — container highest" }
    }
    SettingsCard {
        title: "Foreground"
        RowColor { category: "colors"; configKey: "fg";    label: "fg — main text" }
        RowColor { category: "colors"; configKey: "grey1"; label: "grey1 — outline" }
        RowColor { category: "colors"; configKey: "grey2"; label: "grey2 — variant" }
    }
    SettingsCard {
        title: "Accents"
        RowColor { category: "colors"; configKey: "accent"; label: "accent — primary" }
        RowColor { category: "colors"; configKey: "red";    label: "red — error" }
        RowColor { category: "colors"; configKey: "blue";   label: "blue — secondary" }
        RowColor { category: "colors"; configKey: "purple"; label: "purple — tertiary" }
    }
}
