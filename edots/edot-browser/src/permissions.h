#pragma once
#include <QString>
#include <QJsonObject>
#include <QMutex>
#include <QSet>
#include <QStringList>
#include <QUrl>

class Permissions {
public:
    enum class Decision { Default, Trusted, Blocked };
    Permissions();
    Decision decision(const QUrl& url) const;
    void setSite(const QString& host, Decision decision);
    void remove(const QString& host);
    QString currentFile() const { return m_path; }
    QStringList trusted() const;
    QStringList blocked() const;
private:
    QString normalize(QString host) const;
    bool matches(const QString& rule, const QString& host) const;
    void load();
    void save() const;
    // interceptRequest() може викликатись з іншого потоку, ніж UI
    mutable QMutex m_mutex;
    QString m_path;
    QSet<QString> m_trusted;
    QSet<QString> m_blocked;
    QJsonObject m_sites;
};
