pragma Singleton
import Quickshell
import QtQuick

// Lang.qml — мінімальна i18n: ключ → рядок, мова з Settings.general.language.
// Використання:  text: Lang.t("page.general")
Singleton {
    id: root

    readonly property string current: {
        try { return Settings.get("general", "language") || "uk" }
        catch (e) { return "uk" }
    }

    readonly property var strings: ({
        uk: {
            "page.general":    "Загальні",
            "page.appearance": "Вигляд",
            "page.colors":     "Кольори",
            "page.bar":        "Бар",
            "page.lockscreen": "Локскрін",
            "page.clock":      "Годинник",
            "page.about":      "Про програму",

            "section.general":    "Загальне",
            "section.appearance": "Вигляд",
            "section.colors":     "Кольори",
            "section.bar":        "Бар",
            "section.modules":    "Модулі",
            "section.lockscreen": "Локскрін",
            "section.clock":      "Годинник",

            "settings.title":     "Налаштування",
            "search.placeholder": "Пошук налаштувань…",
            "about.title":        "Edots",
            "about.body":         "MangoWM + Quickshell. Один процес: бар, дашборд, док, налаштування, локскрін."
        },
        en: {
            "page.general":    "General",
            "page.appearance": "Appearance",
            "page.colors":     "Colors",
            "page.bar":        "Bar",
            "page.lockscreen": "Lock screen",
            "page.clock":      "Clock",
            "page.about":      "About",

            "section.general":    "General",
            "section.appearance": "Appearance",
            "section.colors":     "Colors",
            "section.bar":        "Bar",
            "section.modules":    "Modules",
            "section.lockscreen": "Lock screen",
            "section.clock":      "Clock",

            "settings.title":     "Settings",
            "search.placeholder": "Search settings…",
            "about.title":        "Edots",
            "about.body":         "MangoWM + Quickshell. Single shell process: bar, dashboard, dock, settings, lock."
        }
    })

    function t(key) {
        var dict = strings[current] || strings.uk
        return dict[key] !== undefined ? dict[key] : key
    }
}
