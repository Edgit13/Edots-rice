pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeTypography — M3 type scale (display/headline/title/body/label × L/M/S).
// Використання: font.family/pixelSize/weight/letterSpacing + lineHeight (див. ThemedText.qml).
Singleton {
    id: root

    readonly property real k: ThemeSettings.uiScale

    function _pick(list) {
        try {
            const fams = Qt.fontFamilies()
            for (let i = 0; i < list.length; i++)
                if (fams.indexOf(list[i]) >= 0) return list[i]
        } catch (e) {}
        return list[0]
    }
    readonly property string sans: _pick(["SF Pro Display", "Inter", "Roboto", "Noto Sans", "Cantarell"])
    readonly property string mono: _pick(["SF Mono", "JetBrainsMono Nerd Font", "JetBrains Mono", "monospace"])
    readonly property string icons: "Material Symbols Rounded"

    // size / line-height / weight / tracking (px, M3 spec) × uiScale
    function _t(size, line, weight, tracking, family) {
        return {
            family: family || sans,
            size: Math.round(size * k),
            line: Math.round(line * k),
            weight: weight,
            emphasizedWeight: Math.min(weight + 200, 700),   // M3 Expressive: emphasized варіант
            tracking: tracking * k
        }
    }

    readonly property var displayLarge:  _t(57, 64, 400, -0.25)
    readonly property var displayMedium: _t(45, 52, 400, 0)
    readonly property var displaySmall:  _t(36, 44, 400, 0)
    readonly property var headlineLarge:  _t(32, 40, 400, 0)
    readonly property var headlineMedium: _t(28, 36, 400, 0)
    readonly property var headlineSmall:  _t(24, 32, 400, 0)
    readonly property var titleLarge:  _t(22, 28, 400, 0)
    readonly property var titleMedium: _t(16, 24, 500, 0.15)
    readonly property var titleSmall:  _t(14, 20, 500, 0.1)
    readonly property var bodyLarge:  _t(16, 24, 400, 0.5)
    readonly property var bodyMedium: _t(14, 20, 400, 0.25)
    readonly property var bodySmall:  _t(12, 16, 400, 0.4)
    readonly property var labelLarge:  _t(14, 20, 500, 0.1)
    readonly property var labelMedium: _t(12, 16, 500, 0.5)
    readonly property var labelSmall:  _t(11, 16, 500, 0.5)

    // моно (годинник, числа): tabular-вигляд
    readonly property var monoLarge:  _t(22, 28, 500, 0, mono)
    readonly property var monoMedium: _t(14, 20, 500, 0, mono)
    readonly property var monoSmall:  _t(12, 16, 500, 0, mono)

    // іконки (Material Symbols Rounded — єдиний icon pack)
    readonly property int iconXS: Math.round(16 * k)
    readonly property int iconS:  Math.round(20 * k)
    readonly property int iconM:  Math.round(24 * k)
    readonly property int iconL:  Math.round(32 * k)
    readonly property int iconXL: Math.round(40 * k)
}
