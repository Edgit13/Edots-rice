pragma Singleton
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

    property color bg0: "#0d0d0d"
    property color bg1: "#141414"
    property color bg2: "#1c1c1c"
    property color bg3: "#262626"
    property color bg4: "#333333"
    property color fg: "#e8e8e8"
    property color accent: "#8ab4f8"
    property color red: "#f28b82"
    property color orange: "#fbbc04"
    property color yellow: "#fdd663"
    property color green: "#81c995"
    property color aqua: "#78d9ec"
    property color blue: "#8ab4f8"
    property color purple: "#c58af9"
    property color grey0: "#333333"
    property color grey1: "#5f6368"
    property color grey2: "#9aa0a6"

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/colors.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const d = JSON.parse(text())
                for (const key of ["bg0", "bg1", "bg2", "bg3", "bg4", "fg", "accent",
                                    "red", "orange", "yellow", "green", "aqua", "blue", "purple",
                                    "grey0", "grey1", "grey2"]) {
                    if (typeof d[key] === "string") root[key] = d[key]
                }
            } catch (e) { console.warn("[Colors] не вдалось розпарсити colors.json: " + e) }
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
