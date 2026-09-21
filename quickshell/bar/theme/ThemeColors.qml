pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell
import Quickshell.Io

// ThemeColors — усі M3 color roles. Одне джерело правди для кольору в shell.
//  • Dynamic + Dark  : ролі matugen з colors.json (точні), пробіли добудовуються генератором
//  • Dynamic + Light : генератор із seed = primary зі шпалер
//  • Custom accent   : генератор із seed = ThemeSettings.accent
Singleton {
    id: root

    readonly property bool dark: ThemeSettings.resolvedDark
    property var wall: ({})       // вміст colors.json
    readonly property bool hasWall: typeof wall.primary === "string"
    readonly property bool useWall: ThemeSettings.dynamicColor && hasWall

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root.wall = JSON.parse(text()) } catch (e) { root.wall = ({}) }
        }
    }

    readonly property string source: useWall ? (dark && wall.md3 === true ? "matugen" : "wallpaper-seed") : "accent"
    readonly property string seed: useWall ? wall.primary : ThemeSettings.accent

    readonly property var scheme: _build()

    function _build() {
        const gen = ThemeTonal.makeScheme(seed, dark)
        if (useWall && dark && wall.md3 === true) {
            for (const k in wall) {
                const role = ThemeTonal.snakeToCamel(k)
                const v = wall[k]
                if (gen[role] !== undefined && typeof v === "string" && v.charAt(0) === "#")
                    gen[role] = v
            }
        }
        return gen
    }
    function pick(k) { return scheme[k] }

    // ---- primary / secondary / tertiary ----
    readonly property color primary: pick("primary")
    readonly property color fgPrimary: pick("onPrimary")
    readonly property color primaryContainer: pick("primaryContainer")
    readonly property color fgPrimaryContainer: pick("onPrimaryContainer")
    readonly property color secondary: pick("secondary")
    readonly property color fgSecondary: pick("onSecondary")
    readonly property color secondaryContainer: pick("secondaryContainer")
    readonly property color fgSecondaryContainer: pick("onSecondaryContainer")
    readonly property color tertiary: pick("tertiary")
    readonly property color fgTertiary: pick("onTertiary")
    readonly property color tertiaryContainer: pick("tertiaryContainer")
    readonly property color fgTertiaryContainer: pick("onTertiaryContainer")

    // ---- error + custom semantic ----
    readonly property color error: pick("error")
    readonly property color fgError: pick("onError")
    readonly property color errorContainer: pick("errorContainer")
    readonly property color fgErrorContainer: pick("onErrorContainer")
    readonly property color success: pick("success")
    readonly property color fgSuccess: pick("onSuccess")
    readonly property color successContainer: pick("successContainer")
    readonly property color fgSuccessContainer: pick("onSuccessContainer")
    readonly property color warning: pick("warning")
    readonly property color fgWarning: pick("onWarning")
    readonly property color warningContainer: pick("warningContainer")
    readonly property color fgWarningContainer: pick("onWarningContainer")

    // ---- surfaces ----
    readonly property color background: pick("background")
    readonly property color fgBackground: pick("onBackground")
    readonly property color surface: pick("surface")
    readonly property color fgSurface: pick("onSurface")
    readonly property color surfaceVariant: pick("surfaceVariant")
    readonly property color fgSurfaceVariant: pick("onSurfaceVariant")
    readonly property color surfaceDim: pick("surfaceDim")
    readonly property color surfaceBright: pick("surfaceBright")
    readonly property color surfaceContainerLowest: pick("surfaceContainerLowest")
    readonly property color surfaceContainerLow: pick("surfaceContainerLow")
    readonly property color surfaceContainer: pick("surfaceContainer")
    readonly property color surfaceContainerHigh: pick("surfaceContainerHigh")
    readonly property color surfaceContainerHighest: pick("surfaceContainerHighest")

    // ---- outline / inverse / misc ----
    readonly property color outline: pick("outline")
    readonly property color outlineVariant: pick("outlineVariant")
    readonly property color inverseSurface: pick("inverseSurface")
    readonly property color inverseOnSurface: pick("inverseOnSurface")
    readonly property color inversePrimary: pick("inversePrimary")
    readonly property color surfaceTint: pick("surfaceTint")
    readonly property color shadow: pick("shadow")
    readonly property color scrim: pick("scrim")
    readonly property real scrimOpacity: 0.32

    // ---- helpers ----
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t) }
    // M3 state layer: on-колір поверх контейнера з opacity стану
    function layer(base, on, opacity) { return Qt.tint(base, Qt.rgba(on.r, on.g, on.b, opacity)) }
    // Читабельний текст на довільному фоні (WCAG ≥ 4.5 де можливо)
    // NB: імена, що починаються з "on"+Велика (onSurface…), QML трактує як signal handler → M3 "on*" ролі названі fg*
    function readableOn(bg) {
        return ThemeTonal.contrast(fgSurface, bg) >= ThemeTonal.contrast(inverseOnSurface, bg) ? fgSurface : inverseOnSurface
    }
    function contrast(a, b) { return ThemeTonal.contrast(a, b) }
}
