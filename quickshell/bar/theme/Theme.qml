pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// Theme — єдина точка входу. Модулі імпортують лише її:
//   import "root:/theme"
//   color: Theme.color.surfaceContainer
//   radius: Theme.shape.card
//   Theme.type.titleMedium, Theme.space.lg, Theme.motion.duration("morph")
Singleton {
    id: root

    readonly property QtObject color: ThemeColors
    readonly property QtObject type: ThemeTypography
    readonly property QtObject shape: ThemeShapes
    readonly property QtObject elevation: ThemeElevation
    readonly property QtObject motion: ThemeMotion
    readonly property QtObject space: ThemeSpacing
    readonly property QtObject components: ThemeComponents
    readonly property QtObject settings: ThemeSettings

    readonly property bool dark: ThemeSettings.resolvedDark

    function set(key, value) { ThemeSettings.set(key, value) }

    // colour helpers
    function alpha(c, a) { return ThemeColors.alpha(c, a) }
    function mix(a, b, t) { return ThemeColors.mix(a, b, t) }
    function stateLayer(base, on, opacity) { return ThemeColors.layer(base, on, opacity) }
    function readableOn(bg) { return ThemeColors.readableOn(bg) }

    // responsive: compact | regular | large (за логічною шириною екрана)
    function sizeClass(width) { return width < 1400 ? "compact" : (width < 2300 ? "regular" : "large") }
}
