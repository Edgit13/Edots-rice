pragma Singleton
import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick

// ==========================================================================
// Config.qml — центральна система налаштувань Edots (Phase 2, розширена).
//
// Шари:
//   Defaults.values  — НЕЗМІННІ заводські значення (Defaults.qml);
//   Config.current   — жива персистентна копія (~/.config/quickshell/settings.json);
//   Presets          — поверх цього (Presets.qml, Phase 14 UI).
//
// API:
//   get(cat, key)            — поточне значення (з fallback на default)
//   set(cat, key, val)       — валідація (тип + limits) + клемп + save;
//                              повертає false, якщо ключ невідомий/тип невірний
//   contains(cat, key)       — чи існує ключ у defaults
//   isDirty(cat, key)        — чи відрізняється поточне значення від default
//   resetKey(cat, key)       — скинути один ключ
//   resetCategory(cat)       — скинути категорію
//   resetAll()               — скинути ВСЕ (це і є кнопка "Default")
//   replaceAll(values)       — валідаційний bulk-apply (Presets.apply/import)
//
// Деталі:
//   - save() дебаунситься (150 мс), щоб слайдери не писали файл на кожен кадр;
//   - mergeLoaded() має guard на рядкову рівність, тому власний запис
//     у файл не перезапускає merge і не створює пінг-понгу;
//   - ключі, яких немає в defaults (наприклад, з новішої версії),
//     зберігаються як є й повертаються у файл — жодних втрат даних
//     при downgrade/round-trip.
// ==========================================================================

Singleton {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/settings.json"

    // Структурна гарантія: defaults живуть у Defaults.qml (readonly).
    readonly property var defaults: Defaults.values

    property var current: root.cloneDefaults()
    property bool loaded: false

    // ---------------------------------------------------------------- utils

    function cloneDefaults() {
        return JSON.parse(JSON.stringify(root.defaults))
    }

    function contains(category, key) {
        return root.defaults[category] !== undefined
            && root.defaults[category][key] !== undefined
    }

    function get(category, key) {
        if (root.current[category] && root.current[category][key] !== undefined)
            return root.current[category][key]
        if (root.contains(category, key))
            return root.defaults[category][key]
        return undefined
    }

    function isDirty(category, key) {
        return root.contains(category, key)
            && root.current[category]
            && root.current[category][key] !== undefined
            && root.current[category][key] !== root.defaults[category][key]
    }

    // ----------------------------------------------------------- validation

    // Перевірка типу значення проти default. true = сумісно.
    function typeMatches(def, value) {
        if (Array.isArray(def))
            return Array.isArray(value)
        // typeof покриває number/string/boolean; null/об'єкти сюди не
        // потрапляють, бо в defaults лише примітиви й масиви.
        return typeof def === typeof value
    }

    // Клемп числа за limits + enum-перевірка. Приймає лише ВАЛІДНІ значення;
    // def — fallback для невалідних enum.
    function clampByLimits(category, key, value, def) {
        const lim = Defaults.limits[category + "." + key]
        if (!lim)
            return value
        if (lim.options)
            return lim.options.includes(value) ? value : def
        if (typeof value === "number") {
            let v = value
            if (lim.min !== undefined) v = Math.max(lim.min, v)
            if (lim.max !== undefined) v = Math.min(lim.max, v)
            return v
        }
        return value
    }

    // Сувора версія для set(): невідомий ключ або невідповідний тип -> undefined.
    function coerceValid(category, key, value) {
        const def = root.contains(category, key) ? root.defaults[category][key] : undefined
        if (def === undefined) {
            console.warn("Config.set: невідомий ключ", category + "." + key, "— відхилено")
            return undefined
        }
        if (!root.typeMatches(def, value)) {
            console.warn("Config.set: невідповідний тип для", category + "." + key,
                         "(очікується", typeof def + ")", "— відхилено")
            return undefined
        }
        let v = root.clampByLimits(category, key, value, def)

        // Міжполева узгодженість glow: min не може перевищувати max.
        if (category === "pill") {
            const cur = root.current.pill || {}
            if (key === "glowMinOpacity" && cur.glowMaxOpacity !== undefined)
                v = Math.min(v, cur.glowMaxOpacity)
            if (key === "glowMaxOpacity" && cur.glowMinOpacity !== undefined)
                v = Math.max(v, cur.glowMinOpacity)
        }
        return v
    }

    // М'яка версія для merge/replace: невідомі ключі проходять як є
    // (збереження сумісності з майбутніми версіями), невалідні за типом
    // відновлюються на default.
    function sanitize(category, key, value) {
        if (!root.contains(category, key))
            return value
        const def = root.defaults[category][key]
        if (!root.typeMatches(def, value))
            return def
        return root.clampByLimits(category, key, value, def)
    }

    // ------------------------------------------------------------------ set

    function set(category, key, value) {
        const v = root.coerceValid(category, key, value)
        if (v === undefined)
            return false
        // НОВИЙ об'єкт на кожному рівні: Qt 6 пропускає change-notify, якщо
        // var-властивості присвоїти ТОЙ САМИЙ об'єкт (root.current =
        // root.current мовчки не сповіщав — live-бінди оновлювались лише
        // після перезапуску).
        const catObj = Object.assign({}, root.current[category], { [key]: v })
        root.current = Object.assign({}, root.current, { [category]: catObj })
        root.save()
        return true
    }

    // --------------------------------------------------------------- reset

    function resetKey(category, key) {
        if (!root.contains(category, key)) {
            console.warn("Config.resetKey: невідомий ключ", category + "." + key)
            return false
        }
        const catObj = Object.assign({}, root.current[category],
            { [key]: root.defaults[category][key] })
        root.current = Object.assign({}, root.current, { [category]: catObj })
        root.save()
        return true
    }

    function resetCategory(category) {
        if (!root.defaults[category]) {
            console.warn("Config.resetCategory: невідома категорія", category)
            return false
        }
        root.current = Object.assign({}, root.current,
            { [category]: JSON.parse(JSON.stringify(root.defaults[category])) })
        root.save()
        return true
    }

    // Кнопка "Default" у Settings UI викликає саме це.
    function resetAll() {
        root.current = root.cloneDefaults()
        root.save()
        return true
    }

    // ------------------------------------------------------- bulk (presets)

    // Валідаційний bulk-apply: unknown keys проходять, invalid -> defaults.
    // Використовується Presets.apply() та імпортом пресетів.
    function replaceAll(values) {
        const merged = root.cloneDefaults()
        if (values && typeof values === "object") {
            for (const category in values) {
                const src = values[category]
                if (!src || typeof src !== "object" || Array.isArray(src))
                    continue
                if (!merged[category])
                    merged[category] = {}
                for (const key in src)
                    merged[category][key] = root.sanitize(category, key, src[key])
            }
        }
        root.current = merged
        root.save()
    }

    // ----------------------------------------------------------------- save

    function save() {
        saveTimer.restart()
    }

    function flushSave() {
        configFile.setText(JSON.stringify(root.current, null, 2))
    }

    Timer {
        id: saveTimer
        interval: 150
        onTriggered: root.flushSave()
    }

    // ----------------------------------------------------------------- load

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.mergeLoaded(text())
    }

    function mergeLoaded(text) {
        // Guard: власний щойно записаний файл не має перевантажувати state
        // (інакше кожен save() -> onTextChanged -> merge -> churn біндів).
        if (root.loaded && text === JSON.stringify(root.current, null, 2))
            return

        const merged = root.cloneDefaults()
        if (text && text.trim().length > 0) {
            try {
                const savedData = JSON.parse(text)
                for (const category in savedData) {
                    const src = savedData[category]
                    if (!src || typeof src !== "object" || Array.isArray(src))
                        continue
                    if (!merged[category])
                        merged[category] = {}
                    for (const key in src)
                        merged[category][key] = root.sanitize(category, key, src[key])
                }
            } catch (e) {
                console.warn("Config: не вдалося розпарсити settings.json, використовую defaults:", e)
            }
        }
        root.current = merged
        root.loaded = true
        if (!text || text.trim().length === 0) {
            // Перший запуск — файлу ще нема, створюємо його з defaults.
            root.save()
        }
    }
}
