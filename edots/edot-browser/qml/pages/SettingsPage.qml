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
        m.push({ value: "__custom__", label: i18n.s.engine_other })
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

            Text { text: i18n.s.set_title; color: c.on_surface; font.pixelSize: 28; Layout.bottomMargin: 4 }

            // ================= Загальні
            SectionTitle { text: i18n.s.sec_general }
            Card {
                SettingRow {
                    title: i18n.s.set_homepage
                    desc: i18n.s.set_homepage_desc
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
                    title: i18n.s.set_engine
                    desc: i18n.s.set_engine_desc
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
                    title: i18n.s.set_custom_engine
                    desc: i18n.s.set_custom_engine_desc
                    M3Field {
                        width: 280
                        placeholder: "https://example.com/search?q="
                        text: page.engineIsPreset ? "" : v.search_engine
                        onEditingFinished: { if (text.trim().length) settings.set("search_engine", text.trim()) }
                    }
                }
                SettingRow {
                    title: i18n.s.set_startup
                    M3Select {
                        model: [{ value: "homepage", label: i18n.s.startup_homepage },
                                { value: "restore", label: i18n.s.startup_restore }]
                        currentValue: v.startup
                        onActivated: function(value) { settings.set("startup", value) }
                    }
                }
                SettingRow {
                    title: i18n.s.nt_mode
                    divider: false
                    M3Select {
                        model: [{ value: "newtab", label: i18n.s.nt_speed },
                                { value: "homepage", label: i18n.s.nt_home },
                                { value: "blank", label: i18n.s.nt_blank }]
                        currentValue: v.new_tab
                        onActivated: function(value) { settings.set("new_tab", value) }
                    }
                }
                SettingRow {
                    title: i18n.s.set_language
                    desc: i18n.s.set_language_desc
                    M3Select {
                        model: [{ value: "system", label: i18n.s.lang_system },
                                { value: "uk", label: i18n.s.lang_uk },
                                { value: "en", label: i18n.s.lang_en }]
                        currentValue: v.language
                        onActivated: function(value) { i18n.setLanguage(value) }
                    }
                }
            }


            // ================= Нова вкладка
            SectionTitle { text: i18n.s.sec_newtab }
            Card {
                SettingRow {
                    title: i18n.s.nt_show_search
                    M3Switch { checked: v.newtab_show_search; onToggled: function(value) { settings.set("newtab_show_search", value) } }
                }
                SettingRow {
                    title: i18n.s.nt_show_greeting
                    M3Switch { checked: v.newtab_show_greeting; onToggled: function(value) { settings.set("newtab_show_greeting", value) } }
                }
                SettingRow {
                    title: i18n.s.nt_show_date
                    M3Switch { checked: v.newtab_show_date; onToggled: function(value) { settings.set("newtab_show_date", value) } }
                }
                SettingRow {
                    title: i18n.s.nt_show_weather
                    M3Switch { checked: v.newtab_show_weather; onToggled: function(value) { settings.set("newtab_show_weather", value) } }
                }
                SettingRow {
                    title: i18n.s.nt_city
                    desc: i18n.s.nt_city_hint
                    M3Field {
                        width: 200
                        placeholder: "Kyiv"
                        text: v.newtab_city
                        onEditingFinished: settings.set("newtab_city", text.trim())
                    }
                }
                SettingRow {
                    title: i18n.s.nt_show_tiles
                    M3Switch { checked: v.newtab_show_tiles; onToggled: function(value) { settings.set("newtab_show_tiles", value) } }
                }
                SettingRow {
                    title: i18n.s.nt_tiles_count
                    M3Select {
                        implicitWidth: 100
                        model: [4, 6, 8, 10, 12].map(function(n) { return { value: n, label: String(n) } })
                        currentValue: v.newtab_tiles_count
                        onActivated: function(value) { settings.set("newtab_tiles_count", value) }
                    }
                }
                SettingRow {
                    title: i18n.s.nt_greeting_text
                    desc: i18n.s.nt_greeting_hint
                    M3Field {
                        width: 280
                        text: v.newtab_greeting
                        onEditingFinished: settings.set("newtab_greeting", text.trim())
                    }
                }
                SettingRow {
                    title: i18n.s.nt_bg
                    desc: i18n.s.nt_bg_hint
                    divider: false
                    M3Field {
                        width: 140
                        placeholder: "#10131a"
                        text: v.newtab_bg
                        onEditingFinished: settings.set("newtab_bg", text.trim())
                    }
                }
            }

            // ================= Вигляд
            SectionTitle { text: i18n.s.sec_look }
            Card {
                SettingRow {
                    title: i18n.s.set_theme
                    desc: i18n.s.set_theme_desc + (theme.dotfilesFound ? "" : " (файл не знайдено - стандартна палітра)")
                    Segmented {
                        model: [{ key: "dotfiles", label: "Dotfiles" }, { key: "dark", label: i18n.s.seg_dark }, { key: "light", label: i18n.s.seg_light }]
                        current: v.theme_mode
                        onPicked: function(key) { settings.set("theme_mode", key) }
                    }
                }
                SettingRow {
                    title: i18n.s.set_accent
                    desc: v.theme_mode === "dotfiles" ? i18n.s.accent_desc_dotfiles : i18n.s.accent_desc
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
                    title: i18n.s.set_anim
                    desc: i18n.s.set_anim_desc
                    M3Switch { checked: v.enable_animations; onToggled: function(value) { settings.set("enable_animations", value) } }
                }
                SettingRow {
                    title: i18n.s.set_zoom
                    desc: i18n.s.set_zoom_desc
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
            SectionTitle { text: i18n.s.sec_privacy }
            Card {
                SettingRow {
                    title: i18n.s.save_history
                    desc: i18n.s.save_history_desc
                    M3Switch { checked: v.save_history; onToggled: function(value) { settings.set("save_history", value) } }
                }
                SettingRow {
                    title: i18n.s.filters
                    desc: "Завантажено списків: " + browser.filterLists + (browser.filtersBusy ? " · оновлення..." : "")
                    M3Button {
                        text: browser.filtersBusy ? i18n.s.btn_updating : i18n.s.btn_update
                        kind: "tonal"
                        icon: "refresh"
                        enabled: !browser.filtersBusy
                        onClicked: browser.updateFilters()
                    }
                }
                SettingRow {
                    title: i18n.s.clear_history
                    M3Button { text: i18n.s.btn_clear; kind: "tonal"; onClicked: confirm.openFor("history") }
                }
                SettingRow {
                    title: i18n.s.clear_web
                    desc: i18n.s.clear_web_desc
                    M3Button { text: i18n.s.btn_clear; kind: "tonal"; onClicked: confirm.openFor("web") }
                }
                SettingRow {
                    title: "Закладки"
                    divider: false
                    M3Button { text: i18n.s.btn_delete; kind: "danger"; onClicked: confirm.openFor("bookmarks") }
                }
            }

            // ================= Дозволи сайтів
            SectionTitle { text: i18n.s.sec_sites }
            Card {
                SettingRow {
                    title: i18n.s.sites_title
                    desc: i18n.s.sites_desc
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
            SectionTitle { text: i18n.s.sec_about }
            Card {
                SettingRow { title: "edot Browser"; desc: browser.versionInfo }
                SettingRow { title: i18n.s.about_data; desc: browser.dataFolder; divider: false }
            }
        }
    }

    // ---- діалоги
    M3Dialog {
        id: confirm
        property string kind: ""
        readonly property var texts: ({
            history:   [i18n.s.dlg_history_t, i18n.s.dlg_history_b],
            web:       [i18n.s.dlg_web_t, i18n.s.dlg_web_b],
            bookmarks: [i18n.s.dlg_bookmarks_t, i18n.s.dlg_bookmarks_b]
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
