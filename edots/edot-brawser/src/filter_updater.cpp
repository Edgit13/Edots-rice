#include "filter_updater.h"

#include "filter_engine.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>

FilterUpdater::FilterUpdater(FilterEngine* engine, QObject* parent) : QObject(parent), m_engine(engine) {
    connect(&m_watcher, &QFutureWatcher<void>::finished, this, [this] {
        m_busy = false;
        emit finished(m_downloaded, m_total);
    });
}

void FilterUpdater::update(bool force) {
    if (m_busy) return;
    QFile src(":/filters/sources.json");
    if (!src.open(QIODevice::ReadOnly)) return;
    const QJsonArray sources = QJsonDocument::fromJson(src.readAll()).array();
    const QString dir = filtersCacheDir();
    QDir().mkpath(dir);

    constexpr qint64 kMaxAge = 5LL * 24 * 3600;
    m_downloaded = 0;
    m_total = sources.size();
    m_pending = 0;
    m_busy = true;

    for (const QJsonValue& v : sources) {
        const QJsonObject s = v.toObject();
        const QString id = s.value("id").toString().replace('/', '_');
        const QString path = dir + "/" + id + ".txt";
        const QFileInfo fi(path);
        const bool stale = !fi.exists() || fi.lastModified().secsTo(QDateTime::currentDateTime()) > kMaxAge;
        if (!force && !stale) continue;

        ++m_pending;
        QNetworkRequest req{QUrl(s.value("url").toString())};
        req.setRawHeader("User-Agent", "edot-browser/2.0 filter-updater");
        req.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);
        QNetworkReply* reply = m_nam.get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, path] {
            const QByteArray data = reply->readAll();
            // не кешуємо HTML-сторінку помилки замість списку
            if (reply->error() == QNetworkReply::NoError && data.size() > 100 &&
                !data.left(512).toLower().contains("<html")) {
                QFile f(path);
                if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) { f.write(data); ++m_downloaded; }
            } else {
                qWarning() << "edot filters:" << path << "update failed:" << reply->errorString();
            }
            reply->deleteLater();
            finishOne();
        });
    }
    if (m_pending == 0) m_pending = 1, finishOne();
}

void FilterUpdater::finishOne() {
    if (--m_pending > 0) return;
    if (m_downloaded == 0 && m_busy) {
        // нічого нового - рушій уже актуальний
        m_busy = false;
        emit finished(0, m_total);
        return;
    }
    m_watcher.setFuture(m_engine->loadAsync(filtersCacheDir()));
}
