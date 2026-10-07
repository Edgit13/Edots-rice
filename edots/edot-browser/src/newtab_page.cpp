#include "newtab_page.h"

#include "app_settings.h"
#include "data_store.h"
#include "i18n.h"
#include "theme.h"

#include <QBuffer>
#include <QDate>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QMap>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTime>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>
#include <QWebEngineUrlRequestJob>

NewTabPage::NewTabPage(Theme* theme, AppSettings* settings, DataStore* store, I18n* i18n,
                       QObject* parent)
    : QWebEngineUrlSchemeHandler(parent),
      m_theme(theme), m_settings(settings), m_store(store), m_i18n(i18n),
      m_nam(new QNetworkAccessManager(this)) {
    m_timer = new QTimer(this);
    m_timer->setInterval(30 * 60 * 1000); // оновлення погоди раз на 30 хв
    connect(m_timer, &QTimer::timeout, this, &NewTabPage::fetchWeather);

    // Перший запит невдовзі після старту, щоб не блокувати запуск
    QTimer::singleShot(1500, this, [this] { fetchWeather(); });
}

QString NewTabPage::escapeHtml(const QString& s) {
    QString out = s;
    out.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
       .replace("\"", "&quot;").replace("'", "&#39;");
    return out;
}

// wttr weatherCode -> emoji (купи WMO codes)
QString NewTabPage::weatherEmoji(int code) {
    if (code == 113) return QStringLiteral("☀️");   // Sunny
    if (code == 116) return QStringLiteral("⛅");   // Partly cloudy
    if (code == 119 || code == 122) return QStringLiteral("☁️");
    if (code == 143 || code == 248 || code == 260) return QStringLiteral("🌫️");
    if (code == 176 || code == 263 || code == 266 || code == 281 || code == 284)
        return QStringLiteral("🌦️");
    if (code == 179 || code == 227 || code == 230) return QStringLiteral("🌨️");
    if (code == 182 || code == 185 || code == 281 || code == 284 || code == 311 || code == 314 ||
        code == 317 || code == 350 || code == 362 || code == 365)
        return QStringLiteral("🌧️");
    if (code == 200) return QStringLiteral("🌩️");
    if (code == 296 || code == 299 || code == 302 || code == 305 || code == 308)
        return QStringLiteral("🌧️");
    if (code == 389 || code == 386 || code == 392) return QStringLiteral("⛈️");
    if (code == 395) return QStringLiteral("❄️");
    return QStringLiteral("🌡️");
}

// ---------------------------------------------------------- погода (wttr.in)
void NewTabPage::fetchWeather() {
    if (!m_settings->value(QStringLiteral("newtab_show_weather")).toBool()) return;
    QUrl url(QStringLiteral("https://wttr.in/"));
    // місто з налаштувань; порожнє = автоматично за IP
    const QString city = m_settings->value(QStringLiteral("newtab_city")).toString().trimmed();
    if (!city.isEmpty()) url.setPath(QLatin1Char('/') + city);
    QUrlQuery q;
    q.addQueryItem(QStringLiteral("format"), QStringLiteral("j1"));
    q.addQueryItem(QStringLiteral("lang"),
                   m_i18n->language() == QLatin1String("en") ? QStringLiteral("en")
                                                             : QStringLiteral("uk"));
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, QStringLiteral("curl/8.0")); // wttr віддає JSON
    auto* reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply] { onWeatherReply(reply); });
    if (!m_timer->isActive()) m_timer->start();
}

void NewTabPage::onWeatherReply(QNetworkReply* reply) {
    reply->deleteLater();
    if (reply->error() != QNetworkReply::NoError) return; // лишаємо старий кеш
    const QJsonObject root = QJsonDocument::fromJson(reply->readAll()).object();
    const QJsonArray cur = root.value(QStringLiteral("current_condition")).toArray();
    if (cur.isEmpty()) return;
    const QJsonObject c = cur.first().toObject();
    QVariantMap w;
    w[QStringLiteral("temp")] = c.value(QStringLiteral("temp_C")).toString() + QChar(0x00B0);
    const QJsonArray desc = c.value(QStringLiteral("weatherDesc")).toArray();
    w[QStringLiteral("desc")] = desc.isEmpty() ? QString()
                                               : desc.first().toObject().value(QStringLiteral("value")).toString();
    w[QStringLiteral("code")] = c.value(QStringLiteral("weatherCode")).toString().toInt();
    const QJsonArray area = root.value(QStringLiteral("nearest_area")).toArray();
    if (!area.isEmpty()) {
        const QJsonArray names = area.first().toObject().value(QStringLiteral("areaName")).toArray();
        if (!names.isEmpty()) w[QStringLiteral("city")] = names.first().toObject().value(QStringLiteral("value")).toString();
    }
    if (w.value(QStringLiteral("temp")).toString().isEmpty()) return;
    m_weather = w;
    emit weatherUpdated(); // BrowserWindow оновить відкриту сторінку newtab
}

// ---------------------------------------------------------- сторінка
void NewTabPage::requestStarted(QWebEngineUrlRequestJob* job) {
    const QByteArray html = buildHtml().toUtf8();
    auto* buf = new QBuffer;
    buf->open(QIODevice::ReadWrite);
    buf->write(html);
    buf->seek(0);
    job->reply("text/html; charset=utf-8", buf);
}

QString NewTabPage::buildHtml() const {
    const QVariantMap c = m_theme->colors();
    const bool dark = m_theme->dark();
    auto sv = [this](const char* k) { return m_settings->value(QString::fromLatin1(k)).toBool(); };
    const bool showSearch = sv("newtab_show_search"), showGreeting = sv("newtab_show_greeting"),
               showDate = sv("newtab_show_date"), showWeather = sv("newtab_show_weather"),
               showTiles = sv("newtab_show_tiles");

    // ---- CSS-змінні з ролей M3
    static const char* kRoles[] = {
        "primary", "on_primary", "primary_container", "on_primary_container",
        "secondary_container", "on_secondary_container",
        "tertiary_container", "on_tertiary_container",
        "surface", "surface_container_low", "surface_container",
        "surface_container_high", "surface_container_highest",
        "on_surface", "on_surface_variant", "outline",
    };
    QString cssVars;
    for (const char* role : kRoles)
        cssVars += QStringLiteral("  --%1: %2;\n")
                       .arg(QString(role).replace('_', '-'), c.value(QString(role)).toString());
    // власний колір тла
    const QString bg = m_settings->value(QStringLiteral("newtab_bg")).toString().trimmed();
    if (bg.startsWith(QLatin1Char('#')) && (bg.length() == 4 || bg.length() == 7))
        cssVars += QStringLiteral("  --page-bg: %1;\n").arg(bg);
    else
        cssVars += QStringLiteral("  --page-bg: %1;\n").arg(c.value(QStringLiteral("surface_container_low")).toString());

    // ---- привітання: власний текст або за часом доби
    QString greeting = m_settings->value(QStringLiteral("newtab_greeting")).toString().trimmed();
    if (greeting.isEmpty()) {
        const int hour = QTime::currentTime().hour();
        greeting = hour < 5  ? QStringLiteral("Доброї ночі")
                 : hour < 12 ? QStringLiteral("Доброго ранку")
                 : hour < 18 ? QStringLiteral("Доброго дня")
                             : QStringLiteral("Доброго вечора");
    }
    const QLocale uk(QLocale::Ukrainian, QLocale::Ukraine);
    const QString date = uk.toString(QDate::currentDate(), QLocale::LongFormat);

    // ---- тайли: закладки + топ-сайти з історії
    const int tileCount = qBound(2, m_settings->value(QStringLiteral("newtab_tiles_count")).toInt(), 12);
    struct Site { QString url, title, host; int visits; };
    QMap<QString, Site> byHost;
    const QVariantList hist = m_store->history();
    for (const QVariant& v : hist) {
        const QVariantMap m = v.toMap();
        const QUrl u(m.value(QStringLiteral("url")).toString());
        if (u.scheme() != QLatin1String("http") && u.scheme() != QLatin1String("https")) continue;
        const QString host = u.host();
        auto it = byHost.find(host);
        if (it == byHost.end())
            byHost.insert(host, {u.scheme() + QLatin1String("://") + host,
                                 m.value(QStringLiteral("title")).toString(), host, 1});
        else { ++it->visits; if (it->title.isEmpty()) it->title = m.value(QStringLiteral("title")).toString(); }
    }
    QList<Site> top = byHost.values();
    std::sort(top.begin(), top.end(), [](const Site& a, const Site& b) { return a.visits > b.visits; });

    QStringList seenHosts, tileHtml;
    auto addTile = [&](const QString& url, const QString& title, const QString& host) {
        if (tileHtml.size() >= tileCount || url.isEmpty()) return;
        const QString h = host.isEmpty() ? QUrl(url).host() : host;
        if (seenHosts.contains(h)) return;
        seenHosts << h;
        const QString label = h.startsWith(QLatin1String("www.")) ? h.mid(4) : h;
        tileHtml << QStringLiteral(
            "<a class=\"tile\" href=\"%1\" title=\"%2\">"
            "<span class=\"avatar t%3\">%4</span><span class=\"label\">%5</span></a>")
            .arg(escapeHtml(url), escapeHtml(title.isEmpty() ? label : title))
            .arg(tileHtml.size() % 3).arg(escapeHtml(label.left(1).toUpper()), escapeHtml(label));
    };
    const QVariantList bm = m_store->bookmarks();
    for (const QVariant& v : bm) {
        const QVariantMap m = v.toMap();
        addTile(m.value(QStringLiteral("url")).toString(), m.value(QStringLiteral("title")).toString(), QString());
    }
    for (const Site& s : top) addTile(s.url, s.title, s.host);
    const QString tiles = tileHtml.isEmpty()
        ? QStringLiteral("<p class=\"hint\">%1</p>").arg(m_i18n->tr(QStringLiteral("np_tiles_hint")))
        : QStringLiteral("<nav class=\"grid\">") + tileHtml.join(QLatin1Char('\n')) + QStringLiteral("</nav>");

    // ---- погода
    QString weatherHtml;
    if (showWeather) {
        if (m_weather.isEmpty()) {
            weatherHtml = QStringLiteral(
                "<a class=\"weather\" href=\"https://wttr.in\" title=\"wttr.in\">"
                "<span class=\"w-ico\">🌡️</span><span class=\"w-t\">%1</span></a>")
                .arg(m_i18n->tr(QStringLiteral("np_weather_na")));
        } else {
            weatherHtml = QStringLiteral(
                "<a class=\"weather\" href=\"https://wttr.in/%1\" title=\"wttr.in\">"
                "<span class=\"w-ico\">%2</span><span class=\"w-t\">%3</span>"
                "<span class=\"w-d\">%4</span>%5</a>")
                .arg(escapeHtml(m_settings->value(QStringLiteral("newtab_city")).toString().trimmed()),
                     weatherEmoji(m_weather.value(QStringLiteral("code")).toInt()),
                     escapeHtml(m_weather.value(QStringLiteral("temp")).toString()),
                     escapeHtml(m_weather.value(QStringLiteral("desc")).toString()),
                     m_weather.value(QStringLiteral("city")).toString().isEmpty()
                         ? QString() : QStringLiteral("<span class=\"w-c\">%1</span>")
                               .arg(escapeHtml(m_weather.value(QStringLiteral("city")).toString())));
        }
    }

    // ---- конфіг для JS
    QJsonObject cfg;
    cfg[QStringLiteral("engine")] = m_settings->value(QStringLiteral("search_engine")).toString();
    cfg[QStringLiteral("searchPh")] = m_i18n->tr(QStringLiteral("np_search_ph"));

    const QString header = (showGreeting || showDate || showWeather)
        ? QStringLiteral(
            "<header>%1%2%3</header>")
            .arg(showGreeting ? QStringLiteral("<h1>%1</h1>").arg(escapeHtml(greeting)) : QString(),
                 showDate ? QStringLiteral("<p class=\"date\">%1</p>").arg(date) : QString(),
                 weatherHtml)
        : QString();
    const QString search = showSearch
        ? QStringLiteral(
            "<form id=\"f\" autocomplete=\"off\">"
            "<svg width=\"22\" height=\"22\" viewBox=\"0 0 24 24\"><path d=\"M15.5 14h-.79l-.28-.27a6.5 6.5 0 1 0-.7.7l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0A4.5 4.5 0 1 1 14 9.5 4.5 4.5 0 0 1 9.5 14z\"/></svg>"
            "<input id=\"q\" placeholder=\"@SEARCH_PH@\" autofocus></form>")
        : QString();
    const QString tilesBlock = showTiles ? tiles : QString();

    QString page = QStringLiteral(R"(<!DOCTYPE html>
<html lang="uk"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="@SCHEME@"><title>@TITLE@</title><style>
:root {
@CSS_VARS@
  --radius-lg: 28px; --radius-md: 16px;
  --shadow-1: 0 1px 2px rgba(0,0,0,.3), 0 1px 3px 1px rgba(0,0,0,.15);
  --shadow-2: 0 1px 2px rgba(0,0,0,.3), 0 2px 6px 2px rgba(0,0,0,.15);
}
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; }
body {
  background: var(--page-bg); color: var(--on-surface);
  font-family: "Google Sans", Roboto, "Segoe UI", system-ui, sans-serif;
  display: flex; justify-content: center; -webkit-user-select: none;
}
main { width: min(680px, 92vw); padding: 12vh 0 48px; }
header { text-align: center; margin-bottom: 32px; }
h1 { font-size: 32px; font-weight: 500; }
.date { margin-top: 6px; color: var(--on-surface-variant); font-size: 14px; }

/* Віджет погоди */
.weather {
  display: inline-flex; align-items: center; gap: 8px; margin-top: 14px;
  padding: 8px 16px; text-decoration: none;
  background: var(--surface-container); color: var(--on-surface-variant);
  border-radius: 999px; box-shadow: var(--shadow-1); font-size: 14px;
}
.w-ico { font-size: 20px; }
.w-t { color: var(--on-surface); font-weight: 500; }
.w-d, .w-c { color: var(--on-surface-variant); }
.w-c::before { content: "· "; }

/* Пошукова капсула - центральний елемент, як на m3.material.io */
form {
  display: flex; align-items: center; gap: 12px; height: 56px; padding: 0 20px;
  background: var(--surface-container-highest); border: 1px solid transparent;
  border-radius: var(--radius-lg); box-shadow: var(--shadow-1);
  transition: box-shadow .15s ease, border-color .15s ease;
}
form:focus-within { border-color: var(--primary); box-shadow: var(--shadow-2); }
form svg { flex: none; fill: var(--on-surface-variant); }
input { flex: 1; height: 100%; border: 0; outline: 0; background: none;
  color: var(--on-surface); font-size: 16px; font-family: inherit; }
input::placeholder { color: var(--on-surface-variant); }

/* Тайли швидкого доступу */
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(108px, 1fr));
  gap: 8px; margin-top: 32px; }
.tile { display: flex; flex-direction: column; align-items: center; gap: 10px;
  padding: 14px 8px 12px; text-decoration: none; color: var(--on-surface-variant);
  border-radius: var(--radius-lg); transition: background .12s ease; }
.tile:hover { background: color-mix(in srgb, var(--on-surface) 8%, transparent); }
.avatar { width: 56px; height: 56px; border-radius: var(--radius-md);
  display: flex; align-items: center; justify-content: center;
  font-size: 22px; font-weight: 500; color: var(--on-primary-container);
  background: var(--primary-container); box-shadow: var(--shadow-1); }
.avatar.t1 { background: var(--secondary-container); color: var(--on-secondary-container); }
.avatar.t2 { background: var(--tertiary-container); color: var(--on-tertiary-container); }
.label { font-size: 12px; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.hint { margin-top: 32px; text-align: center; color: var(--on-surface-variant); font-size: 14px; }
</style></head><body><main>
@HEADER@
@SEARCH@
@TILES@
</main><script>
const CFG = @CFG@;
document.getElementById('q') && document.getElementById('f').addEventListener('submit', function (e) {
  e.preventDefault();
  const q = document.getElementById('q').value.trim();
  if (!q) return;
  const enc = encodeURIComponent(q);
  location.href = CFG.engine.includes('%s') ? CFG.engine.replace('%s', enc) : CFG.engine + enc;
});
</script></body></html>)");

    page.replace(QLatin1String("@SCHEME@"), dark ? QLatin1String("dark") : QLatin1String("light"));
    page.replace(QLatin1String("@CSS_VARS@"), cssVars);
    page.replace(QLatin1String("@TITLE@"), m_i18n->tr(QStringLiteral("tab_new")));
    page.replace(QLatin1String("@HEADER@"), header);
    page.replace(QLatin1String("@SEARCH@"), search);
    page.replace(QLatin1String("@SEARCH_PH@"), m_i18n->tr(QStringLiteral("np_search_ph")));
    page.replace(QLatin1String("@TILES@"), tilesBlock);
    page.replace(QLatin1String("@CFG@"),
                 QString::fromUtf8(QJsonDocument(cfg).toJson(QJsonDocument::Compact)));
    return page;
}
