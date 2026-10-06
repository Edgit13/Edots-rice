import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: page
    readonly property var c: theme.c
    readonly property var v: settings.values

    readonly property var accentPresets: ["#6750a4", "#0b57d0", "#006874", "#386a20", "#b26a00", "#b3261e", "#984061"]
    readonly property bool accentIsPreset: accentPresets.indexOf(String(v.accent).toLowerCase()) >= 0

    // ---- пошукова система: пресети + власна
    property bool customPicked: false
    readonly property var engineModel: {
        var m = []
        var e = settings.engines
        for (var i = 0; i < e.length; ++i) m.push({ value: e[i].url, label: e[i].name })
        m.push({ value: "__custom__", label: "Інша..." })
        return m
    }
    readonly property bool engineIsPreset: {
        var e = settings.engines
        for (var i = 0; i < e.length; ++i) if (e[i].url === v.search_engine) return true
        return false
    }
    readonly property bool customEngine: customPicked || !engineIsPreset

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight + 72
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
            id: col
            width: Math.min(780, flick.width - 48)
            x: (flick.width - width) / 2
            y: 32
            spacing: 8

            Text { text: "Параметри"; color: c.on_surface; font.pixelSize: 28; Layout.bottomMargin: 4 }

            // ================= Загальні
            SectionTitle { text: "Загальні" }
            Card {
                SettingRow {
                    title: "Домашня сторінка"
                    desc: "Відкривається кнопкою «Додому»"
                    M3Field {
                        width: 280
                        text: v.homepage
                        onEditingFinished: {
                            var t = text.trim()
                            settings.set("homepage", t.length ? t : "https://www.google.com/")
                        }
                    }
                }
                SettingRow {
                    title: "Пошукова система"
                    desc: "Для запитів з адресного рядка"
                    M3Select {
                        model: page.engineModel
                        currentValue: page.customEngine ? "__custom__" : v.search_engine
                        onActivated: function(value) {
                            if (value === "__custom__") page.customPicked = true
                            else { page.customPicked = false; settings.set("search_engine", value) }
                        }
                    }
                }
                SettingRow {
                    visible: page.customEngine
                    title: "Власна пошукова система"
                    desc: "Адреса, що закінчується запитом, або з %s"
                    M3Field {
                        width: 280
                        placeholder: "https://example.com/search?q="
                        text: page.engineIsPreset ? "" : v.search_engine
                        onEditingFinished: { if (text.trim().length) settings.set("search_engine", text.trim()) }
                    }
                }
                SettingRow {
                    title: "Під час запуску"
                    M3Select {
                        model: [{ value: "homepage", label: "Домашня сторінка" },
                                { value: "restore", label: "Продовжити з місця зупинки" }]
                        currentValue: v.startup
                        onActivated: function(value) { settings.set("startup", value) }
                    }
                }
                SettingRow {
                    title: "Нова вкладка"
                    divider: false
                    M3Select {
                        model: [{ value: "homepage", label: "Домашня сторінка" },
                                { value: "blank", label: "Порожня сторінка" }]
                        currentValue: v.new_tab
                        onActivated: function(value) { settings.set("new_tab", value) }
                    }
                }
            }

            // ================= Вигляд
            SectionTitle { text: "Вигляд" }
            Card {
                SettingRow {
                    title: "Тема"
                    desc: "Dotfiles бере кольори з colors.json" + (theme.dotfilesFound ? "" : " (файл не знайдено - стандартна палітра)")
                          + "; темна та світла генеруються з акценту"
                    Segmented {
                        model: [{ key: "dotfiles", label: "Dotfiles" }, { key: "dark", label: "Темна" }, { key: "light", label: "Світла" }]
                        current: v.theme_mode
                        onPicked: function(key) { settings.set("theme_mode", key) }
                    }
                }
                SettingRow {
                    title: "Акцентний колір"
                    desc: v.theme_mode === "dotfiles" ? "Недоступно, поки тема береться з Dotfiles" : "Схема Material 3 будується від обраного кольору"
                    Row {
                        spacing: 2
                        enabled: v.theme_mode !== "dotfiles"
                        opacity: enabled ? 1 : 0.38
                        Repeater {
                            model: page.accentPresets
                            delegate: Swatch {
                                required property string modelData
                                seed: modelData
                                selected: String(v.accent).toLowerCase() === modelData
                                onClicked: settings.set("accent", modelData)
                            }
                        }
                        Swatch {
                            custom: true
                            seed: page.accentIsPreset ? "#808080" : String(v.accent)
                            selected: !page.accentIsPreset
                            onClicked: { hexField.text = String(v.accent); accentDialog.open(); hexField.focusField() }
                        }
                    }
                }
                SettingRow {
                    title: "Анімації"
                    desc: "Плавні переходи та рух елементів"
                    M3Switch { checked: v.enable_animations; onToggled: function(value) { settings.set("enable_animations", value) } }
                }
                SettingRow {
                    title: "Масштаб сторінок"
                    desc: "Типовий для нових вкладок"
                    divider: false
                    M3Select {
                        implicitWidth: 140
                        model: [75, 90, 100, 110, 125, 150, 175, 200].map(function(z) { return { value: z, label: z + "%" } })
                        currentValue: v.zoom
                        onActivated: function(value) { settings.set("zoom", value) }
                    }
                }
            }

            // ================= Конфіденційність
            SectionTitle { text: "Конфіденційність і безпека" }
            Card {
                SettingRow {
                    title: "Зберігати історію"
                    desc: "Відвідані сторінки з'являються в розділі «Історія»"
                    M3Switch { checked: v.save_history; onToggled: function(value) { settings.set("save_history", value) } }
                }
                SettingRow {
                    title: "Фільтри реклами та трекерів"
                    desc: "Завантажено списків: " + browser.filterLists + (browser.filtersBusy ? " · оновлення..." : "")
                    M3Button {
                        text: browser.filtersBusy ? "Оновлення..." : "Оновити"
                        kind: "tonal"
                        icon: "refresh"
                        enabled: !browser.filtersBusy
                        onClicked: browser.updateFilters()
                    }
                }
                SettingRow {
                    title: "Історія переглядів"
                    M3Button { text: "Очистити"; kind: "tonal"; onClicked: confirm.openFor("history") }
                }
                SettingRow {
                    title: "Куки та кеш"
                    desc: "Вихід із сайтів, очищення збережених файлів"
                    M3Button { text: "Очистити"; kind: "tonal"; onClicked: confirm.openFor("web") }
                }
                SettingRow {
                    title: "Закладки"
                    divider: false
                    M3Button { text: "Видалити"; kind: "danger"; onClicked: confirm.openFor("bookmarks") }
                }
            }

            // ================= Дозволи сайтів
            SectionTitle { text: "Дозволи сайтів" }
            Card {
                SettingRow {
                    title: "Довірені та заблоковані сайти"
                    desc: "Довірені обходять фільтри. Заблоковані не завантажуються взагалі. Правило діє і на піддомени."
                }
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 12
                    Layout.bottomMargin: 16
                    spacing: 20
                    SiteList {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        mode: "trusted"
                        title: "Довірені"
                        sites: browser.trustedSites
                    }
                    SiteList {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        mode: "blocked"
                        title: "Заблоковані"
                        sites: browser.blockedSites
                    }
                }
            }

            // ================= Про програму
            SectionTitle { text: "Про програму" }
            Card {
                SettingRow { title: "edot Browser"; desc: browser.versionInfo }
                SettingRow { title: "Папка даних"; desc: browser.dataFolder; divider: false }
            }
        }
    }

    // ---- діалоги
    M3Dialog {
        id: confirm
        property string kind: ""
        readonly property var texts: ({
            history:   ["Очистити історію?", "Усі відвідані сторінки буде видалено."],
            web:       ["Очистити куки та кеш?", "Ви вийдете з облікових записів на сайтах."],
            bookmarks: ["Видалити всі закладки?", "Цю дію не можна скасувати."]
        })
        function openFor(k) {
            kind = k
            title = texts[k][0]
            body = texts[k][1]
            confirmText = k === "web" ? "Очистити" : "Видалити"
            danger = true
            open()
        }
        onConfirmed: browser.clearData(kind)
    }

    M3Dialog {
        id: accentDialog
        title: "Свій акцентний колір"
        body: "Введіть колір у форматі #rrggbb"
        confirmText: "Застосувати"
        confirmEnabled: /^#[0-9a-fA-F]{6}$/.test(hexField.text.trim())
        M3Field { id: hexField; Layout.fillWidth: true; placeholder: "#6750a4"; onAccepted: if (accentDialog.confirmEnabled) { accentDialog.close(); accentDialog.confirmed() } }
        onConfirmed: settings.set("accent", hexField.text.trim().toLowerCase())
    }
}
