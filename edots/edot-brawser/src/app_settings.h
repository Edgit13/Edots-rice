#pragma once
#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class AppSettings final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap values READ values NOTIFY changed)
    Q_PROPERTY(QVariantList engines READ engines CONSTANT)
public:
    explicit AppSettings(QObject* parent = nullptr);

    QVariantMap values() const { return m_values; }
    QVariantList engines() const;
    QVariant value(const QString& key) const { return m_values.value(key); }

    Q_INVOKABLE void set(const QString& key, const QVariant& value);

    QString homepage() const { return m_values.value("homepage").toString(); }
    QString searchUrl(const QString& query) const;

signals:
    void changed(const QString& key);

private:
    void load();
    void save() const;
    QString m_path;
    QVariantMap m_values;
};
