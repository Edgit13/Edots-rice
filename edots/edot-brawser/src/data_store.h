#pragma once
#include <QObject>
#include <QSqlDatabase>
#include <QVariantList>

// Закладки та історія. Той самий data.db і схема, що й у Python-версії.
class DataStore final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList bookmarks READ bookmarks NOTIFY bookmarksChanged)
    Q_PROPERTY(QVariantList history READ history NOTIFY historyChanged)
public:
    explicit DataStore(QObject* parent = nullptr);
    ~DataStore() override;

    QVariantList bookmarks() const;
    QVariantList history() const;

    Q_INVOKABLE bool isBookmarked(const QString& url) const;
    Q_INVOKABLE void addBookmark(const QString& url, const QString& title);
    Q_INVOKABLE void removeBookmarkByUrl(const QString& url);
    Q_INVOKABLE void removeBookmark(int id);
    Q_INVOKABLE void clearBookmarks();
    Q_INVOKABLE void removeHistory(int id);
    Q_INVOKABLE void clearHistory();

    void addHistory(const QString& url, const QString& title);

signals:
    void bookmarksChanged();
    void historyChanged();

private:
    bool exec(const QString& sql, const QVariantList& args = {}) const;
    static QString letterFor(const QString& title, const QString& host);
    QSqlDatabase db() const { return QSqlDatabase::database(m_conn); }
    QString m_conn;
    bool m_ok = false;
};
