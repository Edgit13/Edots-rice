pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeElevation — 6 рівнів (0..5): tonal-колір контейнера + параметри тіні.
Singleton {
    id: root

    readonly property real k: ThemeSettings.uiScale
    readonly property var _blur:    [0, 3, 6, 8, 10, 12]
    readonly property var _offsetY: [0, 1, 2, 3, 4, 6]
    readonly property var _opacity: [0, 0.18, 0.20, 0.22, 0.24, 0.26]

    function _lv(l) { return Math.max(0, Math.min(5, Math.round(l))) }
    // лінійна інтерполяція між рівнями — рівень можна анімувати (дробові значення)
    function _lerp(arr, l) {
        const c = Math.max(0, Math.min(5, l))
        const i = Math.floor(c), f = c - i
        return i >= 5 ? arr[5] : arr[i] + (arr[i + 1] - arr[i]) * f
    }

    function blur(level)    { return _lerp(_blur, level) * k }
    function offsetY(level) { return _lerp(_offsetY, level) * k }
    function opacity(level) { return _lerp(_opacity, level) * (ThemeSettings.resolvedDark ? 1.4 : 1.0) }

    // tonal surface для рівня (M3: контейнери замість surface tint)
    function surfaceFor(level) {
        switch (_lv(level)) {
        case 0: return ThemeColors.surface
        case 1: return ThemeColors.surfaceContainerLow
        case 2: return ThemeColors.surfaceContainer
        case 3: return ThemeColors.surfaceContainerHigh
        case 4: return ThemeColors.surfaceContainerHigh
        default: return ThemeColors.surfaceContainerHighest
        }
    }

    readonly property int flat: 0
    readonly property int resting: 1
    readonly property int raised: 2
    readonly property int floating: 3
    readonly property int overlay: 4
    readonly property int dialog: 5
}
