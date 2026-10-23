pragma Singleton
import "root:/settings"
import QtQuick
import Quickshell
import Quickshell.Io

// Colors — цього файлу НІКОЛИ не існувало (перевірено: локально відсутній, і в git його
// теж нема — .gitignore). Через це кожен `color: Colors.fg` по всіх старих *Surface.qml
// мовчки провалювався й Qt підставляв дефолт типу: Rectangle → білий, Text → чорний.
// Це і була причина "білої заливки й чорного шрифта" в Launcher/Mixer/Wifi/Media/Power/
// Clipboard/Wallpaper/Settings — усього, що досі сидить на старій темі (Md/Colors), а не
// на новій Theme-системі.
//
// Читає ~/.config/quickshell/colors.json (той самий файл, що вже live-оновлює нову тему
// в theme/ThemeColors.qml) — окремим FileView, а не через ThemeColors, щоб не тягнути
// залежність нової теми в старий код, який рано чи пізно піде під ніж разом з цими Surface.
Singleton {
    id: root

    // ---- режим дизайну (theme.design = nothing) — лише через Settings, без залежності від theme/ ----
    readonly property bool nothing: Settings.get("theme", "design") === "nothing"
    readonly property bool _dark: Settings.get("theme", "mode") !== "light"   // "system" трактуємо як dark

    // значення з colors.json (matugen) — ігноруються в режимі Nothing
    property var _f: ({})
    function _v(key, fallback) { return typeof _f[key] === "string" ? _f[key] : fallback }

    // палітра Nothing: [dark, light]
    function _n(d, l) { return _dark ? d : l }

    readonly property color bg0: nothing ? _n("#000000", "#F2F2F2") : _v("bg0", "#0d0d0d")
    readonly property color bg1: nothing ? _n("#0B0B0B", "#F8F8F8") : _v("bg1", "#141414")
    readonly property color bg2: nothing ? _n("#121212", "#EFEFEF") : _v("bg2", "#1c1c1c")
    readonly property color bg3: nothing ? _n("#1A1A1A", "#E8E8E8") : _v("bg3", "#262626")
    readonly property color bg4: nothing ? _n("#242424", "#E0E0E0") : _v("bg4", "#333333")
    readonly property color fg: nothing ? _n("#FFFFFF", "#0A0A0A") : _v("fg", "#e8e8e8")
    readonly property color accent: nothing ? _n("#FFFFFF", "#0A0A0A") : _v("accent", "#8ab4f8")
    readonly property color red: nothing ? "#D71921" : _v("red", "#f28b82")
    readonly property color orange: nothing ? "#F2B84B" : _v("orange", "#fbbc04")
    readonly property color yellow: nothing ? "#F2B84B" : _v("yellow", "#fdd663")
    readonly property color green: nothing ? "#8FD694" : _v("green", "#81c995")
    readonly property color aqua: nothing ? _n("#C4C4C4", "#4A4A4A") : _v("aqua", "#78d9ec")
    readonly property color blue: nothing ? _n("#C4C4C4", "#4A4A4A") : _v("blue", "#8ab4f8")
    readonly property color purple: nothing ? _n("#A3A3A3", "#5E5E5E") : _v("purple", "#c58af9")
    readonly property color grey0: nothing ? _n("#2B2B2B", "#CFCFCF") : _v("grey0", "#333333")
    readonly property color grey1: nothing ? _n("#5C5C5C", "#8A8A8A") : _v("grey1", "#5f6368")
    readonly property color grey2: nothing ? _n("#A3A3A3", "#5E5E5E") : _v("grey2", "#9aa0a6")

    // ---- шрифти для старих Surface (у Nothing — NType/Lettera, з тими ж fallback, що й ThemeNothing) ----
    function _pick(list) {
        try {
            const fams = Qt.fontFamilies()
            for (let i = 0; i < list.length; i++)
                if (fams.indexOf(list[i]) >= 0) return list[i]
        } catch (e) {}
        return list[list.length - 1]
    }
    readonly property string uiFont: nothing ? _pick(["NType 82", "NType82", "Inter", "SF Pro Display", "Roboto", "Noto Sans", "Cantarell"]) : "SF Pro Display"
    readonly property string monoFont: nothing ? _pick(["Lettera Mono", "Lettera Mono LL", "Space Mono", "JetBrainsMono Nerd Font", "JetBrains Mono", "monospace"]) : "SF Mono"

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try { root._f = JSON.parse(text()) }
            catch (e) { console.warn("[Colors] не вдалось розпарсити colors.json: " + e) }
        }
    }

    // ---- ті самі хелпери, що вже використовуються по старих Surface-файлах ----
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t) }
    function layer(base, on, opacity) { return Qt.tint(base, Qt.rgba(on.r, on.g, on.b, opacity)) }
    // Проста readable-on: якщо фон темний — fg, інакше bg0 (без повного WCAG-розрахунку,
    // як у новій Theme — цей файл тимчасовий, під видалення разом зі старими Surface)
    function readableOn(bgColor) {
        const lum = 0.2126 * bgColor.r + 0.7152 * bgColor.g + 0.0722 * bgColor.b
        return lum > 0.5 ? bg0 : fg
    }
    readonly property color shadow: "#000000"
}
