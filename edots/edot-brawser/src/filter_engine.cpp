#include "filter_engine.h"
#include "../rust-adblock/include.h"
#include <QDir>
#include <QFile>
#include <QMutexLocker>
#include <QStandardPaths>
#include <QtConcurrent>

QString filtersCacheDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericCacheLocation) + "/edot-browser/filters";
}

FilterEngine::FilterEngine() = default;
FilterEngine::~FilterEngine() {
    m_future.waitForFinished();
    QMutexLocker l(&m_mutex);
    edot_adblock_free(m_engine);
}
void FilterEngine::loadFromDirectory(const QString& dir) {
    QString all;
    int lists = 0;
    QDir d(dir);
    const auto files = d.entryList({"*.txt"}, QDir::Files, QDir::Name);
    for (const auto& name : files) {
        QFile f(d.filePath(name));
        if (f.open(QIODevice::ReadOnly)) { all += QString::fromUtf8(f.readAll()); all += '\n'; ++lists; }
    }
    void* next = nullptr;
    if (!all.isEmpty()) {
        const QByteArray bytes = all.toUtf8();
        next = edot_adblock_create_from_text(bytes.constData());
    } else next = edot_adblock_create();
    QMutexLocker l(&m_mutex);
    edot_adblock_free(m_engine);
    m_engine = next;
    m_lists = lists;
    m_ready = m_engine != nullptr;
}
QFuture<void> FilterEngine::loadAsync(const QString& dir) {
    m_future = QtConcurrent::run([this, dir] { loadFromDirectory(dir); });
    return m_future;
}
bool FilterEngine::shouldBlock(const QUrl& url, const QUrl& source, const QString& type) const {
    QMutexLocker l(&m_mutex); if (!m_engine) return false;
    const QByteArray u = url.toString().toUtf8(); const QByteArray s = source.toString().toUtf8(); const QByteArray t = type.toUtf8();
    return edot_adblock_check(m_engine, u.constData(), s.constData(), t.constData());
}
