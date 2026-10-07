#include "i18n.h"

#include "app_settings.h"

#include <QCoreApplication>
#include <QLibraryInfo>
#include <QLocale>
#include <QTranslator>

I18n::I18n(AppSettings* settings, QObject* parent)
    : QObject(parent), m_settings(settings) {
    m_lang = resolve(m_settings->value(QStringLiteral("language")).toString());
    m_strings = dict(m_lang);
    apply();
}

void I18n::setLanguage(const QString& lang) {
    m_settings->set(QStringLiteral("language"), lang);
    const QString next = resolve(lang);
    if (next == m_lang) return;
    m_lang = next;
    m_strings = dict(m_lang);
    apply();
    emit changed();
}

void I18n::apply() {
    const QLocale locale(m_lang == QLatin1String("en") ? QStringLiteral("en_US")
                                                       : QStringLiteral("uk_UA"));
    QLocale::setDefault(locale);

    // Стандартні діалоги Qt (файли, кольори тощо)
    if (m_qtTranslator) {
        QCoreApplication::removeTranslator(m_qtTranslator);
        delete m_qtTranslator;
        m_qtTranslator = nullptr;
    }
    auto* t = new QTranslator(this);
    if (t->load(locale, QStringLiteral("qtbase"), QStringLiteral("_"),
                QLibraryInfo::path(QLibraryInfo::TranslationsPath)))
        m_qtTranslator = t;
    else
        delete t;
    if (m_qtTranslator) QCoreApplication::installTranslator(m_qtTranslator);
}

QString I18n::resolve(const QString& setting) {
    if (setting == QLatin1String("uk") || setting == QLatin1String("en")) return setting;
    const QStringList ui = QLocale::system().uiLanguages();
    if (!ui.isEmpty() && ui.first().startsWith(QLatin1String("uk"))) return QStringLiteral("uk");
    return QStringLiteral("uk"); // мова за замовчуванням
}

QVariantMap I18n::dict(const QString& lang) {
    const bool en = lang == QLatin1String("en");
    QVariantMap m;
    auto add = [&m, en](const char* k, const char* uk, const char* en_) {
        m.insert(QString::fromLatin1(k), QString::fromUtf8(en ? en_ : uk));
    };

    // ---- rail
    add("rail_browser",   "Браузер",      "Browser");
    add("rail_bookmarks", "Закладки",     "Bookmarks");
    add("rail_history",   "Історія",      "History");
    add("rail_settings",  "Параметри",    "Settings");
    // ---- chrome: підказки
    add("tip_new_tab",    "Нова вкладка (Ctrl+T)",  "New tab (Ctrl+T)");
    add("tip_back",       "Назад (Alt+←)",          "Back (Alt+←)");
    add("tip_forward",    "Вперед (Alt+→)",         "Forward (Alt+→)");
    add("tip_stop",       "Зупинити",               "Stop");
    add("tip_reload",     "Оновити (Ctrl+R)",       "Reload (Ctrl+R)");
    add("tip_home",       "Додому",                 "Home");
    add("addr_placeholder", "Пошук або адреса сайту", "Search or enter address");
    add("tip_unbookmark", "Видалити із закладок (Ctrl+D)", "Remove bookmark (Ctrl+D)");
    add("tip_bookmark",   "Додати в закладки (Ctrl+D)",    "Add bookmark (Ctrl+D)");
    add("tip_menu",       "Меню",                   "Menu");
    // ---- чіп дозволів
    add("perm_trusted",  "Довірений",    "Trusted");
    add("perm_blocked",  "Заблокований", "Blocked");
    add("perm_default",  "Типово",       "Default");
    add("tab_new",       "Нова вкладка", "New Tab");
    // ---- сторінка параметрів
    add("set_title",     "Параметри",    "Settings");
    add("sec_general",   "Загальні",     "General");
    add("sec_newtab",    "Нова вкладка", "New tab page");
    add("sec_look",      "Вигляд",       "Appearance");
    add("sec_privacy",   "Конфіденційність і безпека", "Privacy and security");
    add("set_homepage",      "Домашня сторінка", "Home page");
    add("set_homepage_desc", "Відкривається кнопкою «Додому»", "Opened by the Home button");
    add("set_engine",        "Пошукова система", "Search engine");
    add("set_engine_desc",   "Для запитів з адресного рядка", "For queries from the address bar");
    add("engine_other",      "Інша...", "Custom...");
    add("set_custom_engine",      "Власна пошукова система", "Custom search engine");
    add("set_custom_engine_desc", "Адреса, що закінчується запитом, або з %s", "URL ending with the query, or with %s");
    add("set_startup",        "Під час запуску", "On startup");
    add("startup_homepage",   "Домашня сторінка", "Home page");
    add("startup_restore",    "Продовжити з місця зупинки", "Continue where you left off");
    add("nt_mode",     "Поведінка нової вкладки", "New tab behavior");
    add("nt_speed",    "Сторінка швидкого доступу", "Speed dial page");
    add("nt_home",     "Домашня сторінка", "Home page");
    add("nt_blank",    "Порожня сторінка", "Blank page");
    add("set_language",      "Мова інтерфейсу", "Interface language");
    add("set_language_desc", "Вікна програми та сторінка нової вкладки", "Application windows and the new tab page");
    add("lang_system", "Системна", "System");
    add("lang_uk", "Українська", "Ukrainian");
    add("lang_en", "English", "English");
    // ---- секція нової вкладки
    add("nt_show_search",    "Показувати пошук", "Show search bar");
    add("nt_show_greeting",  "Показувати привітання", "Show greeting");
    add("nt_show_date",      "Показувати дату", "Show date");
    add("nt_show_weather",   "Показувати погоду", "Show weather");
    add("nt_show_tiles",     "Показувати сайти швидкого доступу", "Show speed dial sites");
    add("nt_tiles_count",    "Кількість сайтів", "Number of sites");
    add("nt_greeting_text",  "Власний текст привітання", "Custom greeting text");
    add("nt_greeting_hint",  "Порожньо = автоматично за часом доби", "Empty = automatic by time of day");
    add("nt_city",           "Місто для погоди", "Weather city");
    add("nt_city_hint",      "Порожньо = визначити автоматично (за IP)", "Empty = detect automatically (by IP)");
    add("nt_bg",             "Колір тла сторінки", "Page background color");
    add("nt_bg_hint",        "Порожньо = колір теми (напр. #10131a)", "Empty = theme color (e.g. #10131a)");
    // ---- конфіденційність
    add("save_history",      "Зберігати історію", "Save history");
    add("save_history_desc", "Відвідані сторінки з'являються в розділі «Історія»", "Visited pages appear in History");
    add("filters",           "Фільтри реклами та трекерів", "Ad and tracker filters");
    add("btn_update",        "Оновити", "Update");
    add("btn_updating",      "Оновлення...", "Updating...");
    add("btn_clear",         "Очистити", "Clear");
    add("btn_delete",        "Видалити", "Delete");
    add("clear_history",     "Історія переглядів", "Browsing history");
    add("clear_web",         "Куки та кеш", "Cookies and cache");
    add("clear_web_desc",    "Вихід із сайтів, очищення збережених файлів", "Signs you out, clears stored files");
    add("clear_bookmarks",   "Закладки", "Bookmarks");
    // ---- діалоги підтвердження
    add("dlg_history_t",   "Очистити історію?", "Clear history?");
    add("dlg_history_b",   "Усі відвідані сторінки буде видалено.", "All visited pages will be removed.");
    add("dlg_web_t",       "Очистити куки та кеш?", "Clear cookies and cache?");
    add("dlg_web_b",       "Ви вийдете з облікових записів на сайтах.", "You will be signed out of websites.");
    add("dlg_bookmarks_t", "Видалити всі закладки?", "Delete all bookmarks?");
    add("dlg_bookmarks_b", "Цю дію не можна скасувати.", "This action cannot be undone.");
    add("dlg_confirm",     "Підтвердити", "Confirm");
    // ---- сторінка нової вкладки
    add("np_search_ph",  "Пошук у інтернеті", "Search the web");
    add("np_tiles_hint", "Тут з'являться ваші закладки та найчастіші сайти.", "Your bookmarks and most visited sites will appear here.");
    add("np_weather_na", "Погода недоступна", "Weather unavailable");
    return m;
}
