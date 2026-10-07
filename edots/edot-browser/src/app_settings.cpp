#include "app_settings.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QUrl>

namespace {
struct Engine { const char* name; const char* url; };
const Engine kEngines[] = {
    {"Google", "https://www.google.com/search?q="},
    {"DuckDuckGo", "https://duckduckgo.com/?q="},
    {"Bing", "https://www.bing.com/search?q="},
    {"Brave Search", "https://search.brave.com/search?q="},
    {"Startpage", "https://www.startpage.com/do/search?q="},
    {"Ecosia", "https://www.ecosia.org/search?q="},
};
} // namespace

AppSettings::AppSettings(QObject* parent) : QObject(parent) {
    m_path = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/edot-browser/settings.json";
    m_values = {
        {"homepage", "https://www.google.com/"},
        {"search_engine", kEngines[0].url},
        {"startup", "homepage"},     // homepage | restore
        {"new_tab", "newtab"},       // newtab | homepage | blank
        {"zoom", 100},
        {"theme_mode", "dotfiles"},  // dotfiles | dark | light
        {"accent", "#9ccbfb"},
        {"enable_animations", true},
        {"save_history", true},
        {"language", "system"},      // system | uk | en
        {"newtab_show_search", true},
        {"newtab_show_greeting", true},
        {"newtab_show_date", true},
        {"newtab_show_weather", true},
        {"newtab_show_tiles", true},
        {"newtab_tiles_count", 8},
        {"newtab_greeting", ""},
        {"newtab_city", ""},
        {"newtab_bg", ""},
    };
    load();
}

QVariantList AppSettings::engines() const {
    QVariantList list;
    for (const auto& e : kEngines) list.append(QVariantMap{{"name", e.name}, {"url", e.url}});
    return list;
}

void AppSettings::set(const QString& key, const QVariant& value) {
    if (m_values.value(key) == value) return;
    m_values[key] = value;
    save();
    emit changed(key);
}

QString AppSettings::searchUrl(const QString& query) const {
    const QString engine = m_values.value("search_engine").toString();
    const QString q = QString::fromLatin1(QUrl::toPercentEncoding(query));
    return engine.contains("%s") ? QString(engine).replace("%s", q) : engine + q;
}

void AppSettings::load() {
    QFile f(m_path);
    if (!f.open(QIODevice::ReadOnly)) return;
    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject()) return;
    const QVariantMap stored = doc.object().toVariantMap();
    for (auto it = stored.begin(); it != stored.end(); ++it) m_values[it.key()] = it.value();
}

void AppSettings::save() const {
    QDir().mkpath(QFileInfo(m_path).absolutePath());
    QFile f(m_path);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        f.write(QJsonDocument(QJsonObject::fromVariantMap(m_values)).toJson(QJsonDocument::Indented));
}
