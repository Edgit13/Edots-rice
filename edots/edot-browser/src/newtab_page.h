#pragma once
#include <QObject>
#include <QVariantMap>
#include <QWebEngineUrlSchemeHandler>

class QNetworkAccessManager;
class QNetworkReply;
class QTimer;
class Theme;
class AppSettings;
class DataStore;
class I18n;
class QWebEngineUrlRequestJob;

// Вбудована сторінка "Нова вкладка" (edot://newtab) у стилі Material 3.
// - HTML генерується з ролей M3 теми (dotfiles/акцент, dark/light)
// - пошук віддає в налаштовану пошукову систему
// - тайли: закладки + топ-сайти з історії
// - віджет погоди: wttr.in (JSON), кеш + фонове оновлення
// - усе перемикається в Параметри -> Нова вкладка
class NewTabPage final : public QWebEngineUrlSchemeHandler {
    Q_OBJECT
public:
    NewTabPage(Theme* theme, AppSettings* settings, DataStore* store, I18n* i18n,
               QObject* parent = nullptr);

    void requestStarted(QWebEngineUrlRequestJob* job) override;

signals:
    void weatherUpdated();

private slots:
    void fetchWeather();
    void onWeatherReply(QNetworkReply* reply);

private:
    QString buildHtml() const;
    static QString escapeHtml(const QString& s);
    static QString weatherEmoji(int code);

    Theme* m_theme;
    AppSettings* m_settings;
    DataStore* m_store;
    I18n* m_i18n;
    QNetworkAccessManager* m_nam;
    QTimer* m_timer;
    QVariantMap m_weather;   // temp, desc, code, city; порожньо = ще немає даних
};
