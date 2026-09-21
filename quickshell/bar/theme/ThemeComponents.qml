pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeComponents — токени розмірів компонентів (M3 / M3 Expressive), × uiScale.
Singleton {
    id: root

    function dp(v) { return ThemeSpacing.dp(v) }

    // Buttons / IconButtons: XS S M L XL (M3E)
    readonly property int buttonXS: dp(32)
    readonly property int buttonS:  dp(40)
    readonly property int buttonM:  dp(56)
    readonly property int buttonL:  dp(96)
    readonly property int buttonXL: dp(136)

    // Switch
    readonly property int switchTrackW: dp(52)
    readonly property int switchTrackH: dp(32)
    readonly property int switchThumbOff: dp(16)
    readonly property int switchThumbOn: dp(24)
    readonly property int switchThumbPressed: dp(28)

    // Slider (M3E track heights)
    readonly property int sliderXS: dp(16)
    readonly property int sliderS:  dp(24)
    readonly property int sliderM:  dp(40)
    readonly property int sliderL:  dp(56)
    readonly property int sliderXL: dp(96)
    readonly property int sliderHandleW: dp(4)

    // List / chip / field
    readonly property int listItemOne: dp(56)
    readonly property int listItemTwo: dp(72)
    readonly property int listItemThree: dp(88)
    readonly property int chipHeight: dp(32)
    readonly property int fieldHeight: dp(56)
    readonly property int tooltipHeight: dp(24)

    // Dialog / navigation
    readonly property int dialogMinW: dp(280)
    readonly property int dialogMaxW: dp(560)
    readonly property int navRail: dp(80)
    readonly property int navBar: dp(64)

    // Shell: висоти bar/island (compact → regular → expressive)
    readonly property int islandCompact: dp(32)
    readonly property int islandRegular: dp(40)
    readonly property int islandExpressive: dp(48)

    // Accessibility: focus ring
    readonly property int focusRingWidth: dp(3)
    readonly property int focusRingOffset: dp(2)

    // State layers (M3)
    readonly property real stateHover: 0.08
    readonly property real stateFocus: 0.10
    readonly property real statePressed: 0.10
    readonly property real stateDragged: 0.16
    readonly property real disabledContent: 0.38
    readonly property real disabledContainer: 0.12
}
