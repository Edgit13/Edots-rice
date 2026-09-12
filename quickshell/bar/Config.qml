pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// ==========================================================================
// Config.qml — центральна система налаштувань Edots (Phase 2).
//
// - defaults: незмінна (readonly) копія РЕАЛЬНИХ поточних значень дизайну
//   Edots — не вигадані числа, витягнуті напряму з PillShell.qml/усталеної
//   практики шрифтів по всьому проєкту. Це і є "Default preset".
// - current: жива, персистентна копія — читається/пишеться в
//   ~/.config/quickshell/settings.json через FileView.setText()
//   (задокументований офіційний API, atomicWrites: true за замовчуванням).
// - get()/set() — безпечні: якщо в збереженому файлі бракує якогось
//   ключа (наприклад, додався новий пізніше), тихо падає назад на default,
//   а не падає з помилкою.
// - resetCategory()/resetAll() — повертають defaults, той самий механізм,
//   яким буде працювати кнопка "Default" у Settings UI (Phase 3+).
//
// Phase 2 навмисно НЕ підключає ці значення до жодного Surface — самі
// PillShell/інші файли й далі використовують свої захардкоджені числа,
// це станеться в Phase 4+ ("Changes should update live where possible").
// Це виключно інфраструктура зберігання, як і просив запит.
// ==========================================================================

Singleton {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/settings.json"

    readonly property var defaults: ({
        appearance: {
            uiFont: "SF Pro Display",
            monoFont: "SF Mono",
            iconFont: "Material Symbols Rounded",
            baseTextSize: 12
        },
        pill: {
            idleHeight: 36,
            idleHorizontalPadding: 20,
            expandedWidth: 480,
            expandedHeight: 300,
            expandedRadius: 28,
            borderWidthDefault: 1,
            borderWidthHover: 2,
            backgroundOpacity: 0.97,
            hoverScale: 1.03,
            morphDuration: 320,
            morphOvershoot: 1.05,
            radiusTransitionDuration: 220,
            glowBreathDuration: 1600,
            glowMinOpacity: 0.18,
            glowMaxOpacity: 0.42
        }
    })

    property var current: root.cloneDefaults()
    property bool loaded: false

    function cloneDefaults() {
        return JSON.parse(JSON.stringify(root.defaults))
    }

    function get(category, key) {
        if (root.current[category] && root.current[category][key] !== undefined)
            return root.current[category][key]
        if (root.defaults[category] && root.defaults[category][key] !== undefined)
            return root.defaults[category][key]
        return undefined
    }

    function set(category, key, value) {
        if (!root.current[category]) root.current[category] = {}
        root.current[category][key] = value
        // var-властивості QML не сповіщають про зміни у вкладених об'єктах
        // самі по собі — перезаписуємо посилання, щоб бінди коректно оновились.
        root.current = root.current
        root.save()
    }

    function resetCategory(category) {
        if (!root.defaults[category]) {
            console.warn("Config.qml: невідома категорія для reset:", category)
            return
        }
        const next = root.current
        next[category] = JSON.parse(JSON.stringify(root.defaults[category]))
        root.current = next
        root.save()
    }

    function resetAll() {
        root.current = root.cloneDefaults()
        root.save()
    }

    function save() {
        configFile.setText(JSON.stringify(root.current, null, 2))
    }

    function mergeLoaded(text) {
        const merged = root.cloneDefaults()
        if (text && text.trim().length > 0) {
            try {
                const savedData = JSON.parse(text)
                for (const category in savedData) {
                    if (!merged[category]) merged[category] = {}
                    for (const key in savedData[category]) {
                        merged[category][key] = savedData[category][key]
                    }
                }
            } catch (e) {
                console.warn("Config.qml: не вдалося розпарсити settings.json, використовую defaults:", e)
            }
        }
        root.current = merged
        root.loaded = true
        if (!text || text.trim().length === 0) {
            // Перший запуск — файлу ще нема, створюємо його з defaults.
            root.save()
        }
    }

    FileView {
        id: configFile
        path: root.configPath
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.mergeLoaded(text())
    }
}
