#include "data_store.h"

#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QSqlError>
#include <QSqlQuery>
#include <QStandardPaths>
#include <QUrl>

DataStore::DataStore(QObject* parent) : QObject(parent), m_conn("edot-data") {
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/edot-browser";
    QDir().mkpath(dir);
    QSqlDatabase d = QSqlDatabase::addDatabase("QSQLITE", m_conn);
    d.setDatabaseName(dir + "/data.db");
    m_ok = d.open();
    if (!m_ok) {
        qWarning() << "edot: cannot open data.db (is the Qt SQLite driver installed?):" << d.lastError().text();
        return;
    }
    exec("CREATE TABLE IF NOT EXISTS history (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT NOT NULL, "
         "title TEXT, visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
    exec("CREATE TABLE IF NOT EXISTS bookmarks (id INTEGER PRIMARY KEY AUTOINCREMENT, url TEXT NOT NULL UNIQUE, "
         "title TEXT, folder TEXT DEFAULT 'Main')");
}

DataStore::~DataStore() {
    if (m_ok) db().close();
    m_ok = false;
    QSqlDatabase::removeDatabase(m_conn);
}

bool DataStore::exec(const QString& sql, const QVariantList& args) const {
    if (!m_ok) return false;
    QSqlQuery q(db());
    q.prepare(sql);
    for (const QVariant& a : args) q.addBindValue(a);
    if (!q.exec()) {
        qWarning() << "edot sql:" << q.lastError().text();
        return false;
    }
    return true;
}

QString DataStore::letterFor(const QString& title, const QString& host) {
    for (const QString& s : {title, host})
        for (const QChar ch : s)
            if (ch.isLetterOrNumber()) return QString(ch.toUpper());
    return "?";
}

QVariantList DataStore::bookmarks() const {
    QVariantList out;
    if (!m_ok) return out;
    QSqlQuery q(db());
    q.exec("SELECT id, url, title FROM bookmarks ORDER BY id DESC");
    while (q.next()) {
        const QString url = q.value(1).toString(), title = q.value(2).toString();
        out.append(QVariantMap{{"id", q.value(0)}, {"url", url}, {"title", title.isEmpty() ? url : title},
                               {"subtitle", url}, {"letter", letterFor(title, QUrl(url).host())}, {"time", ""}});
    }
    return out;
}

QVariantList DataStore::history() const {
    QVariantList out;
    if (!m_ok) return out;
    QSqlQuery q(db());
    q.exec("SELECT id, url, title, visit_time FROM history ORDER BY visit_time DESC LIMIT 300");
    const QDate today = QDate::currentDate();
    while (q.next()) {
        const QString url = q.value(1).toString(), title = q.value(2).toString();
        // Python записував мікросекунди - беремо лише "yyyy-MM-dd HH:mm:ss"
        const QDateTime dt = QDateTime::fromString(q.value(3).toString().left(19), "yyyy-MM-dd HH:mm:ss");
        const QString when = !dt.isValid() ? QString()
                           : dt.date() == today ? dt.toString("HH:mm") : dt.toString("dd.MM.yyyy");
        out.append(QVariantMap{{"id", q.value(0)}, {"url", url}, {"title", title.isEmpty() ? url : title},
                               {"subtitle", url}, {"letter", letterFor(title, QUrl(url).host())}, {"time", when}});
    }
    return out;
}

bool DataStore::isBookmarked(const QString& url) const {
    if (!m_ok || url.isEmpty()) return false;
    QSqlQuery q(db());
    q.prepare("SELECT 1 FROM bookmarks WHERE url = ?");
    q.addBindValue(url);
    return q.exec() && q.next();
}

void DataStore::addBookmark(const QString& url, const QString& title) {
    if (exec("INSERT OR IGNORE INTO bookmarks (url, title) VALUES (?, ?)", {url, title})) emit bookmarksChanged();
}
void DataStore::removeBookmarkByUrl(const QString& url) {
    if (exec("DELETE FROM bookmarks WHERE url = ?", {url})) emit bookmarksChanged();
}
void DataStore::removeBookmark(int id) {
    if (exec("DELETE FROM bookmarks WHERE id = ?", {id})) emit bookmarksChanged();
}
void DataStore::clearBookmarks() {
    if (exec("DELETE FROM bookmarks")) emit bookmarksChanged();
}
void DataStore::removeHistory(int id) {
    if (exec("DELETE FROM history WHERE id = ?", {id})) emit historyChanged();
}
void DataStore::clearHistory() {
    if (exec("DELETE FROM history")) emit historyChanged();
}

void DataStore::addHistory(const QString& url, const QString& title) {
    if (!m_ok) return;
    const QString now = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
    QSqlQuery q(db());
    q.exec("SELECT id, url FROM history ORDER BY id DESC LIMIT 1");
    if (q.next() && q.value(1).toString() == url)  // перезавантаження тієї ж сторінки - не дублюємо
        exec("UPDATE history SET title = ?, visit_time = ? WHERE id = ?", {title, now, q.value(0)});
    else
        exec("INSERT INTO history (url, title, visit_time) VALUES (?, ?, ?)", {url, title, now});
    emit historyChanged();
}
