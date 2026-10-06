#pragma once
#include <QFuture>
#include <QMutex>
#include <QString>
#include <QUrl>
#include <atomic>

// Каталог кешу списків - той самий, куди пише scripts/update_filters.sh
QString filtersCacheDir();

class FilterEngine {
public:
    FilterEngine();
    ~FilterEngine();
    void loadFromDirectory(const QString& dir);
    // Те саме, але у фоновому потоці (запуск не блокується парсингом списків)
    QFuture<void> loadAsync(const QString& dir);
    bool shouldBlock(const QUrl& url, const QUrl& source, const QString& type) const;
    bool ready() const { return m_ready.load(); }
    int loadedLists() const { return m_lists.load(); }
private:
    void* m_engine = nullptr;
    std::atomic<int> m_lists{0};
    std::atomic<bool> m_ready{false};
    mutable QMutex m_mutex;
    QFuture<void> m_future;
};
