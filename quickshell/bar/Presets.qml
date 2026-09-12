pragma Singleton
import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import Qt.labs.folderlistmodel

// ==========================================================================
// Presets.qml — шар пресетів поверх Config (Phase 2: storage layer).
//
// Модель:
//   "Default" — віртуальний; файлу немає; apply() = Config.resetAll().
//               Неможливо перезаписати/видалити (isReserved).
//   "Custom"  — поточний робочий стан (~/.config/quickshell/settings.json);
//               apply("Custom") просто позначає, що правки йдуть у live-стан.
//   <інші>    — файли ~/.config/quickshell/presets/<name>.json,
//               create / rename / delete / export / import.
//
// Ім'я активного пресета зберігається у ~/.config/quickshell/active-preset
// (той самий state-file патерн, що й GameModeState тощо).
//
// UI (список, кнопки, діалоги) — Phase 14. Тут лише API, яким UI скористається.
// ==========================================================================

Singleton {
    id: root

    readonly property string presetDir: Quickshell.env("HOME") + "/.config/quickshell/presets"
    readonly property string activePath: Quickshell.env("HOME") + "/.config/quickshell/active-preset"

    property string active: "Custom"

    // Список користувацьких пресетів (без "Default"/"Custom" — вони віртуальні).
    readonly property var names: {
        const out = []
        const c = folderModel.count
        for (let i = 0; i < c; i++) {
            const fn = String(folderModel.get(i, "fileName"))
            out.push(fn.replace(/\.json$/i, ""))
        }
        return out
    }

    FolderListModel {
        id: folderModel
        folder: "file://" + root.presetDir
        nameFilters: ["*.json"]
        showDirs: false
    }

    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.presetDir]
        running: true
    }

    Process {
        id: ioProc
    }

    FileView {
        id: activeView
        path: root.activePath
        watchChanges: true
        onTextChanged: {
            const v = text().trim()
            root.active = v.length > 0 ? v : "Custom"
        }
        Component.onCompleted: {
            const v = text().trim()
            root.active = v.length > 0 ? v : "Custom"
        }
    }

    FileView {
        id: reader
        watchChanges: false
        onTextChanged: {
            let parsed = null
            try {
                parsed = JSON.parse(text())
            } catch (e) {
                console.warn("Presets.apply: не вдалося розпарсити пресет", root.pendingName, ":", e)
                root.pendingName = ""
                return
            }
            Config.replaceAll(parsed)
            root.setActive(root.pendingName)
            root.pendingName = ""
        }
    }

    property string pendingName: ""

    // ------------------------------------------------------------ helpers

    function isReserved(name) {
        return name === "Default" || name === "Custom"
    }

    // Імена без PATH-сепараторів/прихованих файлів; пробіки всередині — ок.
    function validName(name) {
        return typeof name === "string"
            && name.trim().length > 0
            && name === name.trim()
            && !name.includes("/")
            && !name.includes("\\")
            && !name.startsWith(".")
    }

    function exists(name) {
        return root.names.includes(name)
    }

    function setActive(name) {
        activeView.setText(name)
    }

    // ------------------------------------------------------------ apply

    // "Default" — повернути ВСІ заводські значення (кнопка Default).
    function apply(name) {
        if (name === "Default") {
            Config.resetAll()
            root.setActive("Default")
            return true
        }
        if (name === "Custom") {
            root.setActive("Custom")
            return true
        }
        if (!root.exists(name)) {
            console.warn("Presets.apply: пресет не знайдено:", name)
            return false
        }
        root.pendingName = name
        reader.path = root.presetDir + "/" + name + ".json"
        reader.reload()
        return true
    }

    // ----------------------------------------------------- CRUD + transfer

    // Зберегти ПОТОЧНИЙ стан як новий пресет.
    function create(name) {
        if (!root.validName(name) || root.isReserved(name)) {
            console.warn("Presets.create: некоректне або зарезервоване ім'я:", name)
            return false
        }
        if (root.exists(name)) {
            console.warn("Presets.create: пресет вже існує:", name)
            return false
        }
        ioProc.command = ["cp", Config.configPath, root.presetDir + "/" + name + ".json"]
        ioProc.running = true
        root.setActive(name)
        return true
    }

    function rename(oldName, newName) {
        if (!root.exists(oldName)) {
            console.warn("Presets.rename: пресет не знайдено:", oldName)
            return false
        }
        if (!root.validName(newName) || root.isReserved(newName) || root.exists(newName)) {
            console.warn("Presets.rename: некоректне або зайняте ім'я:", newName)
            return false
        }
        ioProc.command = ["mv",
            root.presetDir + "/" + oldName + ".json",
            root.presetDir + "/" + newName + ".json"]
        ioProc.running = true
        if (root.active === oldName)
            root.setActive(newName)
        return true
    }

    function remove(name) {
        if (root.isReserved(name)) {
            console.warn("Presets.remove: вбудований пресет неможливо видалити:", name)
            return false
        }
        if (!root.exists(name)) {
            console.warn("Presets.remove: пресет не знайдено:", name)
            return false
        }
        ioProc.command = ["rm", root.presetDir + "/" + name + ".json"]
        ioProc.running = true
        if (root.active === name)
            root.setActive("Custom")
        return true
    }

    // destPath — повний шлях призначення (з ім'ям файла).
    function exportPreset(name, destPath) {
        if (!root.exists(name) || typeof destPath !== "string" || destPath.length === 0) {
            console.warn("Presets.exportPreset: пресет або шлях некоректні:", name, destPath)
            return false
        }
        ioProc.command = ["cp", root.presetDir + "/" + name + ".json", destPath]
        ioProc.running = true
        return true
    }

    // Повертає ім'я імпортованого пресета або "" при помилці.
    function importPreset(srcPath) {
        if (typeof srcPath !== "string" || srcPath.length === 0)
            return ""
        const base = srcPath.split("/").pop()
        const name = base.replace(/\.json$/i, "")
        if (!root.validName(name) || root.isReserved(name)) {
            console.warn("Presets.importPreset: некоректне або зарезервоване ім'я:", name)
            return ""
        }
        if (root.exists(name)) {
            console.warn("Presets.importPreset: пресет вже існує:", name)
            return ""
        }
        ioProc.command = ["cp", srcPath, root.presetDir + "/" + name + ".json"]
        ioProc.running = true
        return name
    }
}
