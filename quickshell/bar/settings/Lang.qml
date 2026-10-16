pragma Singleton
import Quickshell
import QtQuick

// Lang.qml — i18n: мова з Settings → Загальні → Мова (general.language).
//   Lang.t("ui.notif.title")             — звичайний рядок (поточна мова → en → ключ)
//   Lang.tn("ui.time.min", 5)            — з підстановкою {n}
//   Lang.label(cat, key, field)          — назва опції Schema (uk-переклад, інакше англ. з Schema)
//   Lang.desc(cat, key, field)           — опис опції
//   Lang.opt(cat, key, value)            — підпис значення enum
//   Lang.unit(" s")                      — одиниця (" s" → " с")
// Нова мова = новий блок у strings; чого немає — береться з en / з Schema.
Singleton {
    id: root

    readonly property string current: {
        try { return Settings.get("general", "language") || "uk" }
        catch (e) { return "uk" }
    }

    readonly property var strings: ({
        uk: {
            // ───────── сторінки / секції ─────────
            "page.general":    "Загальні",
            "page.appearance": "Вигляд",
            "page.colors":     "Кольори",
            "page.bar":        "Бар",
            "page.osd":        "OSD",
            "page.notif":      "Сповіщення",
            "page.layout":     "Вікна",
            "page.lockscreen": "Локскрін",
            "page.clock":      "Годинник",
            "page.about":      "Про програму",

            "section.general":    "Загальне",
            "section.appearance": "Вигляд",
            "section.colors":     "Кольори",
            "section.bar":        "Бар",
            "section.modules":    "Модулі",
            "section.osd":        "Індикатор гучності та яскравості",
            "section.notif":      "Сповіщення",
            "section.layout":     "Розкладка вікон",
            "section.lockscreen": "Локскрін",
            "section.clock":      "Годинник",

            "settings.title":     "Налаштування",
            "search.placeholder": "Пошук налаштувань…",
            "about.title":        "Edots",
            "about.body":         "MangoWM + Quickshell. Один процес: бар, дашборд, док, налаштування, локскрін.",

            // ───────── інтерфейс ─────────
            "ui.surface.launcher":  "Застосунки",
            "ui.surface.wallpaper": "Шпалери",
            "ui.surface.clipboard": "Буфер обміну",
            "ui.surface.mixer":     "Мікшер гучності",
            "ui.surface.wifi":      "Wi-Fi мережі",
            "ui.surface.media":     "Медіа",
            "ui.surface.power":     "Живлення",

            "ui.layout.tile": "Плитка",
            "ui.layout.scroller": "Скролер",
            "ui.layout.monocle": "Монокль",
            "ui.layout.grid": "Сітка",
            "ui.layout.deck": "Колода",
            "ui.layout.center_tile": "Центр",
            "ui.layout.vertical_tile": "Верт. плитка",
            "ui.layout.right_tile": "Плитка праворуч",
            "ui.layout.vertical_scroller": "Верт. скролер",
            "ui.layout.vertical_grid": "Верт. сітка",
            "ui.layout.vertical_deck": "Верт. колода",
            "ui.layout.dwindle": "Двіндл",
            "ui.layout.fair": "Рівна",
            "ui.layout.vertical_fair": "Верт. рівна",
            "ui.pickColor":        "Обрати колір",
            "ui.time.now":         "щойно",
            "ui.time.min":         "{n} хв",
            "ui.time.hour":        "{n} год",
            "ui.time.day":         "{n} дн",

            "ui.notif.title":      "Сповіщення",
            "ui.notif.clear":      "Очистити",
            "ui.notif.dnd":        "Не турбувати",
            "ui.notif.dnd.desc":   "Без спливаючих вікон (крім критичних)",
            "ui.notif.empty":      "Немає сповіщень",
            "ui.notif.open":       "Відкрити",

            "ui.osd.mute":         "Без звуку",

            "ui.media.title":      "Медіа",
            "ui.media.none":       "Нічого не грає",
            "ui.media.unknown":    "Без назви",
            "ui.media.player":     "Плеєр",

            "ui.ws.active":        "Активне вікно",
            "ui.ws.floating":      "Плаваюче",
            "ui.ws.close":         "Закрити",
            "ui.ws.tag":           "Тег {n}",
            "ui.ws.occupied":      "Зайнято: {n}",
            "ui.ws.windows":       "Вікон: {n}",

            // ───────── опції Schema: f.<cat>.<key>.label / .desc ─────────
            "f.general.language.label":        "Мова",
            "f.general.userName.label":        "Ім'я",
            "f.general.userName.desc":         "Порожньо = користувач системи",
            "f.general.autoStart.label":       "Відкривати дашборд при вході",
            "f.general.notifEnabled.label":    "Сповіщення на робочому столі",
            "f.general.weatherCity.label":     "Місто для погоди",
            "f.general.weatherCity.desc":      "Порожньо = визначити за IP",
            "f.general.terminalCommand.label": "Термінал",
            "f.general.fileManager.label":     "Файловий менеджер",
            "f.general.browser.label":         "Браузер",

            "f.theme.mode.label":              "Режим кольорів",
            "f.theme.mode.desc":               "Як у системі або примусово темний / світлий.",
            "f.theme.dynamicColor.label":      "Динамічні кольори зі шпалер",
            "f.theme.accent.label":            "Власний акцент",
            "f.theme.cornerStyle.label":       "Стиль кутів",
            "f.theme.uiScale.label":           "Масштаб інтерфейсу",
            "f.theme.animations.label":        "Анімації",
            "f.theme.expressiveMotion.label":  "Виразний рух",
            "f.theme.reduceMotion.label":      "Зменшити рух",
            "f.theme.animationSpeed.label":    "Швидкість анімацій",

            "f.bar.position.label":            "Позиція",
            "f.bar.mode.label":                "Режим",
            "f.bar.elevation.label":           "Підвищення (тінь)",
            "f.bar.mainMonitor.label":         "Головний монітор",
            "f.bar.mainMonitor.desc":          "Порожньо = перший екран",

            "f.modules.workspaces.label":      "Робочі простори",
            "f.modules.clock.label":           "Годинник",
            "f.modules.launcher.label":        "Лаунчер",
            "f.modules.window.label":          "Заголовок вікна",
            "f.modules.media.label":           "Медіа",
            "f.modules.resources.label":       "Ресурси (CPU / RAM)",
            "f.modules.mixer.label":           "Гучність",
            "f.modules.wifi.label":            "Wi-Fi",
            "f.modules.notifications.label":   "Сповіщення",
            "f.modules.battery.label":         "Батарея",
            "f.modules.power.label":           "Живлення",

            "f.osd.enabled.label":             "Показувати OSD",
            "f.osd.enabled.desc":              "Пігулка при зміні гучності чи яскравості.",
            "f.osd.volume.label":              "Гучність",
            "f.osd.brightness.label":          "Яскравість",
            "f.osd.position.label":            "Позиція",
            "f.osd.position.desc":             "Де на екрані з'являється OSD.",
            "f.osd.margin.label":              "Відступ від краю",
            "f.osd.size.label":                "Розмір",
            "f.osd.duration.label":            "Тривалість",

            "f.layout.active.label":           "Розкладка вікон",
            "f.layout.active.desc":            "Для всіх тегів. У config.conf потрібен рядок source=~/.config/mango/layout.conf.",
            "f.layout.cycle.label":            "Цикл розкладок",
            "f.layout.cycle.desc":             "Через кому, для switch_layout (SUPER+Tab).",

            "f.notif.dnd.label":               "Не турбувати",
            "f.notif.dnd.desc":                "Без спливаючих вікон (критичні все одно показуються).",
            "f.notif.toasts.label":            "Спливаючі вікна",
            "f.notif.toasts.desc":             "Картки, що виїжджають від краю екрана.",
            "f.notif.bar.label":               "Показувати в барі",
            "f.notif.bar.desc":                "Дзвіночок розгортається в останнє сповіщення.",
            "f.notif.position.label":          "Позиція вікон",
            "f.notif.position.desc":           "Де з'являються вікна; центр відкривається з того ж боку.",
            "f.notif.margin.label":            "Відступ від краю",
            "f.notif.width.label":             "Ширина",
            "f.notif.timeout.label":           "Таймаут (звичайні)",
            "f.notif.timeoutLow.label":        "Таймаут (низькі)",
            "f.notif.maxVisible.label":        "Макс. вікон",

            "f.clock.hour12.label":            "12-годинний формат",
            "f.clock.showSeconds.label":       "Показувати секунди",
            "f.clock.dateFormat.label":        "Формат дати",
            "f.clock.fullDateFormat.label":    "Повний формат дати",

            "f.lockscreen.enabled.label":        "Використовувати локскрін Edots",
            "f.lockscreen.blurStrength.label":   "Сила розмиття",
            "f.lockscreen.blurRadius.label":     "Радіус розмиття",
            "f.lockscreen.scrimOpacity.label":   "Затемнення",
            "f.lockscreen.kenBurns.label":       "Ефект Кена Бернса",
            "f.lockscreen.parallax.label":       "Паралакс від миші",
            "f.lockscreen.floatingShapes.label": "Плаваючі фігури",
            "f.lockscreen.clockSize.label":      "Розмір годинника",
            "f.lockscreen.greeting.label":       "Привітання",
            "f.lockscreen.passwordStyle.label":  "Стиль пароля",
            "f.lockscreen.powerButtons.label":   "Кнопки живлення",
            "f.lockscreen.successFlash.label":   "Спалах успіху",

            "f.colors.bg0.label":    "Фон — найглибший",
            "f.colors.bg1.label":    "Поверхня",
            "f.colors.bg2.label":    "Контейнер",
            "f.colors.bg3.label":    "Контейнер (високий)",
            "f.colors.bg4.label":    "Контейнер (найвищий)",
            "f.colors.fg.label":     "Текст",
            "f.colors.grey1.label":  "Контур",
            "f.colors.grey2.label":  "Варіант",
            "f.colors.accent.label": "Акцент",
            "f.colors.red.label":    "Помилка",
            "f.colors.blue.label":   "Вторинний",
            "f.colors.purple.label": "Третинний",

            // ───────── значення enum: o.<cat>.<key>.<value> ─────────
            "o.theme.mode.system":          "Системна",
            "o.theme.mode.light":           "Світла",
            "o.theme.mode.dark":            "Темна",
            "o.theme.cornerStyle.rounded":  "Заокруглені",
            "o.bar.position.top":           "Зверху",
            "o.bar.position.bottom":        "Знизу",
            "o.bar.position.left":          "Ліворуч",
            "o.bar.position.right":         "Праворуч",
            "o.bar.mode.compact":           "Компактний",
            "o.bar.mode.expanded":          "Розширений",
            "o.bar.mode.morphing":          "Морфінг",
            "o.lockscreen.passwordStyle.dots":   "Крапки",
            "o.lockscreen.passwordStyle.shapes": "Фігури",
            "o.lockscreen.passwordStyle.text":   "Текст"
        },

        en: {
            "page.general":    "General",
            "page.appearance": "Appearance",
            "page.colors":     "Colors",
            "page.bar":        "Bar",
            "page.osd":        "OSD",
            "page.notif":      "Notifications",
            "page.layout":     "Windows",
            "page.lockscreen": "Lock screen",
            "page.clock":      "Clock",
            "page.about":      "About",

            "section.general":    "General",
            "section.appearance": "Appearance",
            "section.colors":     "Colors",
            "section.bar":        "Bar",
            "section.modules":    "Modules",
            "section.osd":        "Volume & brightness indicator",
            "section.notif":      "Notifications",
            "section.layout":     "Window layout",
            "section.lockscreen": "Lock screen",
            "section.clock":      "Clock",

            "settings.title":     "Settings",
            "search.placeholder": "Search settings…",
            "about.title":        "Edots",
            "about.body":         "MangoWM + Quickshell. Single shell process: bar, dashboard, dock, settings, lock.",

            "ui.surface.launcher":  "Applications",
            "ui.surface.wallpaper": "Wallpapers",
            "ui.surface.clipboard": "Clipboard history",
            "ui.surface.mixer":     "Volume mixer",
            "ui.surface.wifi":      "Wi-Fi networks",
            "ui.surface.media":     "Media",
            "ui.surface.power":     "Power",

            "ui.layout.tile": "Tile",
            "ui.layout.scroller": "Scroller",
            "ui.layout.monocle": "Monocle",
            "ui.layout.grid": "Grid",
            "ui.layout.deck": "Deck",
            "ui.layout.center_tile": "Center tile",
            "ui.layout.vertical_tile": "Vertical tile",
            "ui.layout.right_tile": "Right tile",
            "ui.layout.vertical_scroller": "Vertical scroller",
            "ui.layout.vertical_grid": "Vertical grid",
            "ui.layout.vertical_deck": "Vertical deck",
            "ui.layout.dwindle": "Dwindle",
            "ui.layout.fair": "Fair",
            "ui.layout.vertical_fair": "Vertical fair",
            "ui.pickColor":        "Pick color",
            "ui.time.now":         "just now",
            "ui.time.min":         "{n} min",
            "ui.time.hour":        "{n} h",
            "ui.time.day":         "{n} d",

            "ui.notif.title":      "Notifications",
            "ui.notif.clear":      "Clear all",
            "ui.notif.dnd":        "Do not disturb",
            "ui.notif.dnd.desc":   "No popups (critical ones still show)",
            "ui.notif.empty":      "No notifications",
            "ui.notif.open":       "Open",

            "ui.osd.mute":         "Muted",

            "ui.media.title":      "Media",
            "ui.media.none":       "Nothing playing",
            "ui.media.unknown":    "Unknown track",
            "ui.media.player":     "Player",

            "ui.ws.active":        "Active window",
            "ui.ws.floating":      "Floating",
            "ui.ws.close":         "Close",
            "ui.ws.tag":           "Tag {n}",
            "ui.ws.occupied":      "Occupied: {n}",
            "ui.ws.windows":       "Windows: {n}",

            // назви мов — рідними мовами в обох словниках
            "o.general.language.uk": "Українська",
            "o.general.language.en": "English"
        }
    })

    function t(key) {
        const c = strings[current]
        if (c && c[key] !== undefined) return c[key]
        const e = strings.en[key]
        return e !== undefined ? e : key
    }
    function tn(key, n) { return t(key).replace("{n}", n) }

    function _lookup(k) {
        const c = strings[current]
        if (c && c[k] !== undefined) return c[k]
        const e = strings.en[k]
        return e !== undefined ? e : undefined
    }
    function label(cat, key, field) {
        const v = _lookup("f." + cat + "." + key + ".label")
        return v !== undefined ? v : ((field && field.label) || key)
    }
    function desc(cat, key, field) {
        const v = _lookup("f." + cat + "." + key + ".desc")
        return v !== undefined ? v : ((field && field.desc) || "")
    }
    function opt(cat, key, value) {
        const v = _lookup("o." + cat + "." + key + "." + value)
        if (v !== undefined) return v
        const s = String(value)
        return s.charAt(0).toUpperCase() + s.slice(1)
    }
    function unit(s) { return (current === "uk" && s === " s") ? " с" : s }

    // пошук працює і за перекладом, і за англійською назвою
    function searchText(cat, key, field) {
        return label(cat, key, field) + " " + ((field && field.label) || key)
    }
}
