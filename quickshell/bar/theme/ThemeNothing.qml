pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeNothing — токени дизайну "Nothing" (Nothing OS / Glyph естетика):
//   • майже чисто чорно-білий моноколір + ОДИН червоний акцент (#D71921)
//   • плоскі поверхні без тіней, тонкі 1px контури
//   • dot-matrix шрифт для цифр/заголовків (Ndot 57 → Doto → моно), моно для підписів
//   • точкова сітка (dotSize/dotGap) — для індикаторів, прогресу, фону
// Вмикається: Settings → Вигляд → Дизайн → Nothing (theme.design = "nothing").
Singleton {
    id: root

    readonly property bool active: ThemeSettings.nothing

    // ---- акцент ----
    readonly property color red: "#D71921"
    readonly property color redSoft: "#3A0D10"

    // ---- шрифти (перший наявний у системі) ----
    function _pick(list) {
        try {
            const fams = Qt.fontFamilies()
            for (let i = 0; i < list.length; i++)
                if (fams.indexOf(list[i]) >= 0) return list[i]
        } catch (e) {}
        return list[list.length - 1]
    }
    readonly property string dot:   _pick(["Ndot57", "NDot57", "Ndot 57", "Doto", "DotGothic16", "Space Mono", "monospace"])
    readonly property string sans:  _pick(["NType 82", "NType82", "Inter", "SF Pro Display", "Roboto", "Noto Sans", "Cantarell"])
    readonly property string mono:  _pick(["Lettera Mono", "Lettera Mono LL", "Space Mono", "JetBrainsMono Nerd Font", "JetBrains Mono", "monospace"])

    // ---- точкова сітка ----
    readonly property real k: ThemeSettings.uiScale
    readonly property int dotSize: Math.max(2, Math.round(3 * k))
    readonly property int dotGap:  Math.max(2, Math.round(3 * k))
    readonly property int dotPitch: dotSize + dotGap

    // ---- контури / форма ----
    readonly property int hairline: 1
    readonly property real dotOpacityOff: 0.14      // "вимкнена" точка
    readonly property real dotOpacityOn: 1.0

    // ---- кутові радіуси (Nothing: великі, але не "таблетка" скрізь) ----
    readonly property var corners: ({ none: 0, xs: 6, sm: 10, md: 16, lg: 22, xl: 30, xxl: 42 })

    // ---- палітра: повертає схему у форматі ThemeTonal.makeScheme ----
    function makeScheme(dark) {
        if (dark) return {
            primary: "#FFFFFF", onPrimary: "#000000",
            primaryContainer: "#262626", onPrimaryContainer: "#FFFFFF",
            secondary: "#C4C4C4", onSecondary: "#000000",
            secondaryContainer: "#1A1A1A", onSecondaryContainer: "#E6E6E6",
            tertiary: "#D71921", onTertiary: "#FFFFFF",
            tertiaryContainer: "#3A0D10", onTertiaryContainer: "#FFB3B6",
            error: "#D71921", onError: "#FFFFFF",
            errorContainer: "#3A0D10", onErrorContainer: "#FFB3B6",
            success: "#8FD694", onSuccess: "#000000",
            successContainer: "#14301A", onSuccessContainer: "#C6F0C9",
            warning: "#F2B84B", onWarning: "#000000",
            warningContainer: "#3A2B08", onWarningContainer: "#FFE2A8",
            background: "#000000", onBackground: "#FFFFFF",
            surface: "#000000", onSurface: "#FFFFFF",
            surfaceVariant: "#1C1C1C", onSurfaceVariant: "#A3A3A3",
            surfaceDim: "#000000", surfaceBright: "#2A2A2A",
            surfaceContainerLowest: "#000000", surfaceContainerLow: "#0B0B0B",
            surfaceContainer: "#121212", surfaceContainerHigh: "#1A1A1A",
            surfaceContainerHighest: "#242424",
            outline: "#5C5C5C", outlineVariant: "#2B2B2B",
            inverseSurface: "#FFFFFF", inverseOnSurface: "#000000",
            inversePrimary: "#000000", surfaceTint: "#FFFFFF",
            shadow: "#000000", scrim: "#000000"
        }
        return {
            primary: "#0A0A0A", onPrimary: "#FFFFFF",
            primaryContainer: "#E3E3E3", onPrimaryContainer: "#0A0A0A",
            secondary: "#4A4A4A", onSecondary: "#FFFFFF",
            secondaryContainer: "#ECECEC", onSecondaryContainer: "#1A1A1A",
            tertiary: "#D71921", onTertiary: "#FFFFFF",
            tertiaryContainer: "#FFDADB", onTertiaryContainer: "#4A0509",
            error: "#D71921", onError: "#FFFFFF",
            errorContainer: "#FFDADB", onErrorContainer: "#4A0509",
            success: "#1F7A2C", onSuccess: "#FFFFFF",
            successContainer: "#CDEFD1", onSuccessContainer: "#0B2E11",
            warning: "#9A6200", onWarning: "#FFFFFF",
            warningContainer: "#FFE3B0", onWarningContainer: "#3A2400",
            background: "#F2F2F2", onBackground: "#0A0A0A",
            surface: "#F2F2F2", onSurface: "#0A0A0A",
            surfaceVariant: "#E6E6E6", onSurfaceVariant: "#5E5E5E",
            surfaceDim: "#DADADA", surfaceBright: "#FFFFFF",
            surfaceContainerLowest: "#FFFFFF", surfaceContainerLow: "#F8F8F8",
            surfaceContainer: "#EFEFEF", surfaceContainerHigh: "#E8E8E8",
            surfaceContainerHighest: "#E0E0E0",
            outline: "#8A8A8A", outlineVariant: "#CFCFCF",
            inverseSurface: "#0A0A0A", inverseOnSurface: "#F2F2F2",
            inversePrimary: "#FFFFFF", surfaceTint: "#0A0A0A",
            shadow: "#000000", scrim: "#000000"
        }
    }
}
