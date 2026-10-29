pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// Colors — сумісний шар для старих поверхонь (Launcher/Clipboard/Power/Wallpaper/Mixer/Wifi).
// Старі імена (accent/fg/bg0…) тепер беруться з ThemeColors, тож працюють і в Material,
// і в Nothing, і в dynamic-палітрі (раніше читали окремий legacy-Colors, не знаний про Nothing).
Singleton {
    id: root

    // ---- акцент та текст на ньому ----
    readonly property color accent:   ThemeColors.primary
    readonly property color onAccent: ThemeColors.fgPrimary      // замість bg0 для тексту на акценті

    // ---- текст ----
    readonly property color fg:    ThemeColors.fgSurface
    readonly property color grey1: ThemeColors.fgSurfaceVariant
    readonly property color grey2: ThemeColors.mix(ThemeColors.fgSurfaceVariant, ThemeColors.surface, 0.25)

    // ---- поверхні ----
    readonly property color bg0: ThemeColors.surface
    readonly property color bg1: ThemeColors.surfaceContainerHigh
    readonly property color bg2: ThemeColors.surfaceContainerHighest
    readonly property color bg3: ThemeColors.surfaceBright
    readonly property color bg4: ThemeColors.outlineVariant

    // ---- семантика ----
    readonly property color red:    ThemeColors.error
    readonly property color green:  ThemeColors.success
    readonly property color orange: ThemeColors.warning

    // ---- дизайн ----
    readonly property bool nothing: ThemeSettings.nothing
    readonly property color nothingRed: ThemeNothing.red

    // ---- шрифти ----
    readonly property string uiFont:   ThemeTypography.sans
    readonly property string monoFont: ThemeTypography.mono
}
