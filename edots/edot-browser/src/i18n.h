#pragma once
#include <QObject>
#include <QVariantMap>

class AppSettings;
class QTranslator;

// Мова інтерфейсу: system | uk | en.
// Рядки доступні у QML як i18n.s.<ключ> (варіантна мапа з NOTIFY -
// при зміні мови всі прив'язки оновлюються автоматично).
class I18n final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap s READ strings NOTIFY changed)
    Q_PROPERTY(QString language READ language NOTIFY changed)
public:
    explicit I18n(AppSettings* settings, QObject* parent = nullptr);

    void apply();                    // QLocale + переклади стандартних діалогів Qt
    QVariantMap strings() const { return m_strings; }
    QString language() const { return m_lang; }
    QString tr(const QString& key) const { return m_strings.value(key).toString(); }

    Q_INVOKABLE void setLanguage(const QString& lang);

signals:
    void changed();

private:
    static QVariantMap dict(const QString& lang);
    static QString resolve(const QString& setting);

    AppSettings* m_settings;
    QString m_lang;
    QVariantMap m_strings;
    QTranslator* m_qtTranslator = nullptr;
};
