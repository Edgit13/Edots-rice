#pragma once
#include <QFutureWatcher>
#include <QNetworkAccessManager>
#include <QObject>

class FilterEngine;

// Завантажує списки з filters/sources.json у кеш і перезбирає рушій у фоні.
class FilterUpdater final : public QObject {
    Q_OBJECT
public:
    FilterUpdater(FilterEngine* engine, QObject* parent = nullptr);
    // force=false: оновлює лише відсутні або старші за 5 діб
    void update(bool force);
    bool busy() const { return m_busy; }

signals:
    void finished(int downloaded, int total);

private:
    void finishOne();
    FilterEngine* m_engine;
    QNetworkAccessManager m_nam;
    QFutureWatcher<void> m_watcher;
    int m_pending = 0, m_downloaded = 0, m_total = 0;
    bool m_busy = false;
};
