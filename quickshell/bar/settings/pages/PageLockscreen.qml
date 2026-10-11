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

    SectionHeader { label: "Lock screen" }

    SettingsCard {
        title: "Enabled"
        RowSwitch { category: "lockscreen"; configKey: "enabled"
            label: "Use Edots lock screen"
            description: "Turn off to fall back to swaylock." }
    }

    SettingsCard {
        title: "Background"
        RowSlider { category: "lockscreen"; configKey: "blurStrength"
            label: "Blur strength"; decimals: 2 }
        RowSlider { category: "lockscreen"; configKey: "blurRadius"
            label: "Blur radius"; suffix: " px"; decimals: 0 }
        RowSlider { category: "lockscreen"; configKey: "scrimOpacity"
            label: "Dim overlay"; decimals: 2 }
        RowSwitch { category: "lockscreen"; configKey: "kenBurns"
            label: "Ken Burns zoom" }
        RowSwitch { category: "lockscreen"; configKey: "parallax"
            label: "Mouse parallax" }
        RowSwitch { category: "lockscreen"; configKey: "floatingShapes"
            label: "Floating accent shapes" }
    }

    SettingsCard {
        title: "Clock & greeting"
        RowSlider { category: "lockscreen"; configKey: "clockSize"
            label: "Clock size"; suffix: " px"; decimals: 0 }
        RowSwitch { category: "lockscreen"; configKey: "greeting"
            label: "Show greeting pill" }
    }

    SettingsCard {
        title: "Password field"
        RowDropdown { category: "lockscreen"; configKey: "passwordStyle"
            label: "Hidden password style"
            description: "dots | shapes (M3 Expressive catalog) | text" }
    }

    SettingsCard {
        title: "Feedback"
        RowSwitch { category: "lockscreen"; configKey: "successFlash"
            label: "Success flash on unlock" }
        RowSwitch { category: "lockscreen"; configKey: "powerButtons"
            label: "Show power buttons" }
    }
}
