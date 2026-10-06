#include "browser_window.h"

#include "app_settings.h"
#include "data_store.h"
#include "filter_updater.h"
#include "image_providers.h"
#include "popup_window.h"
#include "rounded_frame.h"
#include "snackbar.h"
#include "theme.h"

#include <QApplication>
#include <QCloseEvent>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QJsonDocument>
#include <QKeySequence>
#include <QPalette>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickWidget>
#include <QRegularExpression>
#include <QShortcut>
#include <QStackedWidget>
#include <QStandardPaths>
#include <QTabBar>
#include <QTabWidget>
#include <QTimer>
#include <QToolTip>
#include <QVBoxLayout>
#include <QWebEngineCookieStore>
#include <QWebEngineDownloadRequest>
#include <QWebEngineHistory>
#include <QWebEnginePage>
#include <QWebEngineSettings>
#include <QtWebEngineCore/qtwebenginecoreglobal.h>
#include <functional>

namespace {

// Сторінка, що відкриває target=_blank / window.open у новій вкладці
class EdotPage final : public QWebEnginePage {
public:
    EdotPage(QWebEngineProfile* profile, std::function<QWebEnginePage*()> factory, QObject* parent)
        : QWebEnginePage(profile, parent), m_factory(std::move(factory)) {}

protected:
    QWebEnginePage* createWindow(WebWindowType) override { return m_factory ? m_factory() : nullptr; }

private:
    std::function<QWebEnginePage*()> m_factory;
};

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/edot-browser";
}
QString sessionFile() { return configDir() + "/session.json"; }

constexpr int kChromeHeight = 104;

} // namespace

// ============================================================ construction

BrowserWindow::BrowserWindow(QWidget* p) : QMainWindow(p) {
    resize(1440, 920);
    setMinimumSize(900, 600);
    setWindowTitle("edot Browser");

    m_theme = new Theme(this);
    m_settings = new AppSettings(this);
    m_store = new DataStore(this);
    m_theme->load(m_settings->values());

    connect(m_settings, &AppSettings::changed, this, [this](const QString& key) {
        if (key == "theme_mode" || key == "accent" || key == "enable_animations") {
            m_theme->load(m_settings->values());
            applyTheme();
        } else if (key == "zoom") {
            const double z = m_settings->value("zoom").toInt() / 100.0;
            for (int i = 0; i < m_tabs->count(); ++i)
                if (auto* v = viewAt(i)) v->setZoomFactor(z);
            emit zoomChanged();
        }
    });
    connect(m_store, &DataStore::bookmarksChanged, this, [this] { emit bookmarkedChanged(); });

    setupProfile();
    setupUi();
    setupShortcuts();
    applyTheme();
    openStartupTabs();

    // Списки фільтрів: підтягуємо відсутні/застарілі у фоні, без блокування запуску
    m_updater = new FilterUpdater(&m_interceptor->filters(), this);
    connect(m_updater, &FilterUpdater::finished, this, [this](int downloaded, int) {
        emit filtersChanged();
        if (m_manualFilterUpdate) {
            m_snackbar->showMessage(downloaded > 0 ? QString("Оновлено списків: %1").arg(downloaded)
                                                    : QString("Списки вже актуальні або сервер недоступний"));
            m_manualFilterUpdate = false;
        }
    });
    QTimer::singleShot(1500, this, [this] { m_updater->update(false); });
}

BrowserWindow::~BrowserWindow() {
    if (m_popup) delete m_popup;
    // Сторінки мають бути знищені раніше за профіль
    while (m_tabs && m_tabs->count() > 0) {
        QWidget* w = m_tabs->widget(0);
        m_tabs->removeTab(0);
        delete w;
    }
}

void BrowserWindow::setupProfile() {
    const QString root = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation) + "/webdata";
    const QString cache = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/webcache";
    QDir().mkpath(root);
    QDir().mkpath(cache);

    m_profile = new QWebEngineProfile("edot", this);
    m_profile->setPersistentStoragePath(root);
    m_profile->setCachePath(cache);
    m_profile->setPersistentCookiesPolicy(QWebEngineProfile::AllowPersistentCookies);
    m_profile->setHttpCacheType(QWebEngineProfile::DiskHttpCache);
    m_profile->settings()->setAttribute(QWebEngineSettings::FullScreenSupportEnabled, true);
    m_profile->settings()->setAttribute(QWebEngineSettings::PlaybackRequiresUserGesture, false);

    m_interceptor = new RequestInterceptor(m_profile);
    m_profile->setUrlRequestInterceptor(m_interceptor);
    connect(m_profile, &QWebEngineProfile::downloadRequested, this, &BrowserWindow::onDownload);
}

QQuickWidget* BrowserWindow::makeQuick(const QString& qml, const QString& area, int) {
    auto* w = new QQuickWidget(this);
    w->setResizeMode(QQuickWidget::SizeRootObjectToView);
    installImageProviders(w->engine());
    QQmlContext* ctx = w->rootContext();
    ctx->setContextProperty("browser", this);
    ctx->setContextProperty("theme", m_theme);
    ctx->setContextProperty("settings", m_settings);
    ctx->setContextProperty("store", m_store);
    ctx->setContextProperty("uiArea", area);
    w->setSource(QUrl(qml));
    if (w->status() == QQuickWidget::Error)
        for (const auto& e : w->errors()) qWarning().noquote() << e.toString();
    return w;
}

void BrowserWindow::setupUi() {
    // Вкладки створюємо до QML, щоб browser.tabs був безпечним
    m_tabs = new QTabWidget;
    m_tabs->setDocumentMode(true);
    m_tabs->setTabsClosable(false);
    m_tabs->tabBar()->hide();
    m_tabs->setObjectName("webTabs");
    m_tabs->setStyleSheet("QTabWidget::pane { border: 0; }");

    m_root = new QWidget(this);
    m_root->setObjectName("browserRoot");
    m_root->setAutoFillBackground(true);
    auto* h = new QHBoxLayout(m_root);
    h->setContentsMargins(0, 0, 0, 0);
    h->setSpacing(0);

    m_rail = makeQuick("qrc:/qml/Rail.qml", "rail");
    m_rail->setFixedWidth(80);
    h->addWidget(m_rail);

    auto* right = new QWidget;
    auto* v = new QVBoxLayout(right);
    v->setContentsMargins(0, 0, 0, 0);
    v->setSpacing(0);

    m_chrome = makeQuick("qrc:/qml/Chrome.qml", "chrome");
    m_chrome->setFixedHeight(kChromeHeight);
    v->addWidget(m_chrome);

    auto* host = new QWidget;
    auto* hl = new QHBoxLayout(host);
    hl->setContentsMargins(0, 0, 8, 8);
    m_frame = new RoundedFrame(m_theme);
    auto* fl = new QVBoxLayout(m_frame);
    fl->setContentsMargins(1, 1, 1, 1);
    fl->setSpacing(0);
    m_content = new QStackedWidget;
    m_pages = makeQuick("qrc:/qml/Pages.qml", "pages");
    m_content->addWidget(m_tabs);
    m_content->addWidget(m_pages);
    fl->addWidget(m_content);
    m_frame->setClipChild(m_content);
    hl->addWidget(m_frame);
    v->addWidget(host, 1);
    h->addWidget(right, 1);

    setCentralWidget(m_root);
    m_snackbar = new Snackbar(m_root);

    connect(m_tabs, &QTabWidget::currentChanged, this, [this](int) {
        syncLoadingState();
        updateChromeState();
        updateTabs();
    });
}

void BrowserWindow::setupShortcuts() {
    auto bind = [this](const QStringList& keys, std::function<void()> fn) {
        for (const QString& k : keys) {
            auto* sc = new QShortcut(QKeySequence(k), this);
            connect(sc, &QShortcut::activated, this, fn);
        }
    };
    bind({"Ctrl+L"}, [this] {
        showSection("browser");
        m_chrome->setFocus();
        emit focusAddressRequested();
    });
    bind({"Ctrl+T"}, [this] { newTab(); });
    bind({"Ctrl+W"}, [this] { closeTab(m_tabs->currentIndex()); });
    bind({"Ctrl+R", "F5"}, [this] { reload(); });
    bind({"Ctrl+Shift+R"}, [this] { hardReload(); });
    bind({"Ctrl+D"}, [this] { toggleBookmark(); });
    bind({"Alt+Left"}, [this] { back(); });
    bind({"Alt+Right"}, [this] { forward(); });
    bind({"Ctrl+Tab"}, [this] { activateTab((m_tabs->currentIndex() + 1) % m_tabs->count()); });
    bind({"Ctrl+Shift+Tab"}, [this] { activateTab((m_tabs->currentIndex() + m_tabs->count() - 1) % m_tabs->count()); });
    bind({"Ctrl+H"}, [this] { showSection("history"); });
    bind({"Ctrl+Shift+O"}, [this] { showSection("bookmarks"); });
    bind({"Ctrl+,"}, [this] { showSection("settings"); });
    bind({"Ctrl+=", "Ctrl++"}, [this] { zoomBy(10); });
    bind({"Ctrl+-"}, [this] { zoomBy(-10); });
    bind({"Ctrl+0"}, [this] { zoomBy(0); });
}

void BrowserWindow::applyTheme() {
    const QColor surface = m_theme->color("surface");
    const QColor low = m_theme->color("surface_container_low");

    QPalette pal = QApplication::palette();
    pal.setColor(QPalette::Window, surface);
    pal.setColor(QPalette::WindowText, m_theme->color("on_surface"));
    pal.setColor(QPalette::Base, m_theme->color("surface_container"));
    pal.setColor(QPalette::Text, m_theme->color("on_surface"));
    pal.setColor(QPalette::Button, m_theme->color("surface_container_high"));
    pal.setColor(QPalette::ButtonText, m_theme->color("on_surface"));
    pal.setColor(QPalette::Highlight, m_theme->color("primary"));
    pal.setColor(QPalette::HighlightedText, m_theme->color("on_primary"));
    pal.setColor(QPalette::ToolTipBase, m_theme->color("inverse_surface"));
    pal.setColor(QPalette::ToolTipText, m_theme->color("inverse_on_surface"));
    QApplication::setPalette(pal);

    if (m_root) {
        QPalette rp = m_root->palette();
        rp.setColor(QPalette::Window, surface);
        m_root->setPalette(rp);
    }
    for (QQuickWidget* w : {m_rail, m_chrome}) if (w) w->setClearColor(surface);
    if (m_pages) m_pages->setClearColor(low);
    if (m_snackbar) m_snackbar->applyTheme(m_theme);
    for (int i = 0; m_tabs && i < m_tabs->count(); ++i)
        if (auto* v = viewAt(i)) v->page()->setBackgroundColor(low);
    update();
}

// ============================================================ tabs

QWebEngineView* BrowserWindow::currentView() const {
    return m_tabs ? qobject_cast<QWebEngineView*>(m_tabs->currentWidget()) : nullptr;
}
QWebEngineView* BrowserWindow::viewAt(int i) const {
    return m_tabs ? qobject_cast<QWebEngineView*>(m_tabs->widget(i)) : nullptr;
}
QString BrowserWindow::tabKey(const QWebEngineView* v) {
    return QString::number(reinterpret_cast<quintptr>(v), 16);
}

void BrowserWindow::openStartupTabs() {
    QStringList urls;
    if (m_settings->value("startup").toString() == "restore") {
        QFile f(sessionFile());
        if (f.open(QIODevice::ReadOnly))
            for (const QJsonValue& v : QJsonDocument::fromJson(f.readAll()).array())
                if (v.isString() && !v.toString().isEmpty()) urls << v.toString();
    }
    if (urls.isEmpty()) urls << m_settings->homepage();
    for (const QString& u : urls) addTab(QUrl::fromUserInput(u));
}

void BrowserWindow::addTab(const QUrl& url, bool activate) {
    auto* view = new QWebEngineView;
    auto* page = new EdotPage(m_profile, [this]() -> QWebEnginePage* {
        addTab(QUrl("about:blank"), true);
        auto* v = currentView();
        return v ? v->page() : nullptr;
    }, view);
    page->setBackgroundColor(m_theme->color("surface_container_low"));
    view->setPage(page);
    view->setContextMenuPolicy(Qt::DefaultContextMenu);
    view->setZoomFactor(m_settings->value("zoom").toInt() / 100.0);
    view->setProperty("edotProgress", 0);
    view->setProperty("edotLoading", false);

    const int index = m_tabs->addTab(view, "Нова вкладка");
    if (activate) m_tabs->setCurrentIndex(index);

    connect(view, &QWebEngineView::titleChanged, this, [this, view](const QString&) {
        updateTabs();
        if (view == currentView()) updateChromeState();
    });
    connect(view, &QWebEngineView::urlChanged, this, [this, view](const QUrl&) {
        updateTabs();
        if (view == currentView()) updateChromeState();
    });
    connect(view, &QWebEngineView::loadStarted, this, [this, view] {
        view->setProperty("edotLoading", true);
        view->setProperty("edotProgress", 0);
        if (view == currentView()) { syncLoadingState(); emit navStateChanged(); }
        updateTabs();
    });
    connect(view, &QWebEngineView::loadProgress, this, [this, view](int pr) {
        view->setProperty("edotProgress", pr);
        if (view == currentView()) { m_loadProgress = pr; emit loadProgressChanged(); }
    });
    connect(view, &QWebEngineView::loadFinished, this, [this, view](bool ok) {
        view->setProperty("edotLoading", false);
        view->setProperty("edotProgress", 100);
        const QUrl u = view->url();
        if (ok && m_settings->value("save_history").toBool() && (u.scheme() == "http" || u.scheme() == "https"))
            m_store->addHistory(u.toString(), view->title());
        if (view == currentView()) { syncLoadingState(); updateChromeState(); }
        updateTabs();
    });
    connect(view, &QWebEngineView::iconChanged, this, [this, view](const QIcon& icon) {
        const QString key = tabKey(view);
        if (icon.isNull()) {
            TabIconProvider::clear(key);
            view->setProperty("edotHasIcon", false);
        } else {
            TabIconProvider::setIcon(key, icon.pixmap(32, 32));
            view->setProperty("edotHasIcon", true);
            view->setProperty("edotIconRev", quint64(++m_iconRevision));
        }
        updateTabs();
    });

    view->load(url);
    if (activate) showSection("browser");
    updateTabs();
    updateChromeState();
}

void BrowserWindow::newTab() {
    const bool blank = m_settings->value("new_tab").toString() == "blank";
    addTab(blank ? QUrl("about:blank") : QUrl::fromUserInput(m_settings->homepage()));
    if (blank) emit focusAddressRequested();
}

void BrowserWindow::closeTab(int index) {
    if (!m_tabs || index < 0 || index >= m_tabs->count()) return;
    if (m_tabs->count() == 1) {
        close();
        return;
    }
    QWidget* w = m_tabs->widget(index);
    TabIconProvider::clear(tabKey(qobject_cast<QWebEngineView*>(w)));
    m_tabs->removeTab(index);
    w->deleteLater();
    syncLoadingState();
    updateTabs();
    updateChromeState();
}

void BrowserWindow::activateTab(int index) {
    if (m_tabs && index >= 0 && index < m_tabs->count()) {
        m_tabs->setCurrentIndex(index);
        showSection("browser");
    }
}

QVariantList BrowserWindow::tabs() const {
    QVariantList result;
    if (!m_tabs) return result;
    for (int i = 0; i < m_tabs->count(); ++i) {
        auto* v = viewAt(i);
        if (!v) continue;
        QString title = v->title();
        if (title.isEmpty() || title.startsWith("about:")) title = v->url().host();
        if (title.isEmpty()) title = "Нова вкладка";
        const bool hasIcon = v->property("edotHasIcon").toBool();
        result.append(QVariantMap{
            {"index", i},
            {"title", title},
            {"active", i == m_tabs->currentIndex()},
            {"host", v->url().host()},
            {"loading", v->property("edotLoading").toBool()},
            {"icon", hasIcon ? QString("image://tab/%1?%2").arg(tabKey(v)).arg(v->property("edotIconRev").toULongLong())
                             : QString()},
        });
    }
    return result;
}

// ============================================================ navigation

QUrl BrowserWindow::resolveInput(const QString& text) const {
    static const QStringList schemes = {"http://", "https://", "about:", "file:", "chrome://", "view-source:"};
    for (const QString& s : schemes)
        if (text.startsWith(s)) return QUrl(text);

    const QString host = text.section('/', 0, 0);
    static const QRegularExpression hostPort("^[\\w.-]+:\\d+$");
    const bool portOnly = hostPort.match(host).hasMatch();
    if (!text.contains(' ') && (host.contains('.') || host.startsWith("localhost") || portOnly)) {
        const bool local = host.startsWith("localhost") || host.startsWith("127.") || host.startsWith("192.168.");
        return QUrl((local ? "http://" : "https://") + text);
    }
    return QUrl(m_settings->searchUrl(text));
}

void BrowserWindow::navigate(const QString& text) {
    auto* v = currentView();
    const QString s = text.trimmed();
    if (!v || s.isEmpty()) return;
    v->load(resolveInput(s));
    v->setFocus();
}

void BrowserWindow::openUrl(const QString& url) { addTab(QUrl::fromUserInput(url)); }
void BrowserWindow::back()      { if (auto* v = currentView()) v->back(); }
void BrowserWindow::forward()   { if (auto* v = currentView()) v->forward(); }
void BrowserWindow::reload()    { if (auto* v = currentView()) v->reload(); }
void BrowserWindow::stop()      { if (auto* v = currentView()) v->stop(); }
void BrowserWindow::hardReload() { if (auto* v = currentView()) v->triggerPageAction(QWebEnginePage::ReloadAndBypassCache); }
void BrowserWindow::goHome()    { if (auto* v = currentView()) v->load(QUrl::fromUserInput(m_settings->homepage())); }
void BrowserWindow::focusWeb()  { if (auto* v = currentView()) v->setFocus(); }

bool BrowserWindow::canGoBack() const    { auto* v = currentView(); return v && v->history()->canGoBack(); }
bool BrowserWindow::canGoForward() const { auto* v = currentView(); return v && v->history()->canGoForward(); }

QString BrowserWindow::currentUrl() const   { auto* v = currentView(); return v ? v->url().toString() : QString(); }
QString BrowserWindow::currentHost() const  { auto* v = currentView(); return v ? v->url().host() : QString(); }
QString BrowserWindow::currentTitle() const { auto* v = currentView(); return v ? v->title() : QString(); }
bool BrowserWindow::bookmarked() const      { return m_store->isBookmarked(currentUrl()); }

void BrowserWindow::showSection(const QString& name) {
    const QString s = (name == "bookmarks" || name == "history" || name == "settings") ? name : QString("browser");
    if (s == m_section) {
        if (s == "browser") focusWeb();
        return;
    }
    m_section = s;
    m_content->setCurrentWidget(s == "browser" ? static_cast<QWidget*>(m_tabs) : static_cast<QWidget*>(m_pages));
    emit sectionChanged();
    if (s == "browser") focusWeb();
}

void BrowserWindow::toggleBookmark() {
    const QString url = currentUrl();
    if (url.isEmpty() || url.startsWith("about:")) return;
    if (m_store->isBookmarked(url)) {
        m_store->removeBookmarkByUrl(url);
        m_snackbar->showMessage("Видалено із закладок");
    } else {
        m_store->addBookmark(url, currentTitle());
        m_snackbar->showMessage("Додано в закладки");
    }
}

// ============================================================ zoom

int BrowserWindow::zoomPercent() const {
    auto* v = currentView();
    return v ? qRound(v->zoomFactor() * 100) : 100;
}

void BrowserWindow::zoomBy(int delta) {
    auto* v = currentView();
    if (!v) return;
    const int pct = delta == 0 ? m_settings->value("zoom").toInt() : qBound(25, zoomPercent() + delta, 500);
    v->setZoomFactor(pct / 100.0);
    emit zoomChanged();
    m_snackbar->showMessage(QString("Масштаб: %1%").arg(pct), 1200);
}

// ============================================================ permissions

QString BrowserWindow::permission() const { return m_lastPermission.isEmpty() ? "default" : m_lastPermission; }

void BrowserWindow::updatePermission() {
    const QString host = currentHost();
    QString mode = "default";
    if (!host.isEmpty()) {
        switch (m_interceptor->permissions().decision(QUrl("https://" + host))) {
            case Permissions::Decision::Trusted: mode = "trusted"; break;
            case Permissions::Decision::Blocked: mode = "blocked"; break;
            case Permissions::Decision::Default: mode = "default"; break;
        }
    }
    if (mode != m_lastPermission) {
        m_lastPermission = mode;
        emit permissionChanged();
    }
}

void BrowserWindow::setSitePermission(const QString& host, const QString& mode) {
    if (host.trimmed().isEmpty()) return;
    auto& perms = m_interceptor->permissions();
    if (mode == "trusted")      perms.setSite(host, Permissions::Decision::Trusted);
    else if (mode == "blocked") perms.setSite(host, Permissions::Decision::Blocked);
    else                        perms.remove(host);
    updatePermission();
    emit permissionsListChanged();
}

void BrowserWindow::removeSitePermission(const QString& host) { setSitePermission(host, "default"); }

void BrowserWindow::setPermission(const QString& mode) {
    const QString host = currentHost();
    if (host.isEmpty()) return;
    setSitePermission(host, mode);
    reload();  // правило діє на нові запити - перезавантажуємо сторінку
}

// ============================================================ filters, data

bool BrowserWindow::filtersBusy() const { return m_updater && m_updater->busy(); }

void BrowserWindow::updateFilters() {
    if (filtersBusy()) return;
    m_manualFilterUpdate = true;
    m_snackbar->showMessage("Оновлення списків фільтрів...", 2500);
    m_updater->update(true);
    emit filtersChanged();
}

void BrowserWindow::clearData(const QString& kind) {
    if (kind == "history")        m_store->clearHistory();
    else if (kind == "bookmarks") m_store->clearBookmarks();
    else if (kind == "web") {
        m_profile->clearHttpCache();
        m_profile->cookieStore()->deleteAllCookies();
    } else return;
    m_snackbar->showMessage("Готово");
}

QString BrowserWindow::versionInfo() const {
    return QString("Qt %1, Chromium %2").arg(qVersion(), qWebEngineChromiumVersion());
}
QString BrowserWindow::dataFolder() const { return configDir(); }

void BrowserWindow::notify(const QString& text) { m_snackbar->showMessage(text); }

void BrowserWindow::onDownload(QWebEngineDownloadRequest* req) {
    const QString folder = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    const QString dir = folder.isEmpty() ? QDir::homePath() : folder;
    const QString name = req->downloadFileName().isEmpty() ? QString("download") : req->downloadFileName();
    const QFileInfo info(name);
    QString finalName = name;
    for (int n = 1; QFileInfo::exists(dir + "/" + finalName); ++n)
        finalName = QString("%1 (%2)%3").arg(info.completeBaseName()).arg(n)
                        .arg(info.suffix().isEmpty() ? QString() : "." + info.suffix());
    req->setDownloadDirectory(dir);
    req->setDownloadFileName(finalName);
    connect(req, &QWebEngineDownloadRequest::isFinishedChanged, this, [this, req, finalName, dir] {
        if (req->state() == QWebEngineDownloadRequest::DownloadCompleted)
            m_snackbar->showMessage(QString("Завантажено: %1").arg(finalName), 6000, "Відкрити папку",
                                    [dir] { QDesktopServices::openUrl(QUrl::fromLocalFile(dir)); });
        else
            m_snackbar->showMessage(QString("Не вдалося завантажити: %1").arg(finalName));
    });
    req->accept();
    m_snackbar->showMessage(QString("Завантаження: %1").arg(finalName));
}

// ============================================================ chrome state

void BrowserWindow::syncLoadingState() {
    auto* v = currentView();
    const bool loading = v && v->property("edotLoading").toBool();
    const int progress = v ? v->property("edotProgress").toInt() : 0;
    if (loading != m_loading) { m_loading = loading; emit loadingChanged(); }
    if (progress != m_loadProgress) { m_loadProgress = progress; emit loadProgressChanged(); }
}

void BrowserWindow::updateChromeState() {
    const QString u = currentUrl(), h = currentHost(), t = currentTitle();
    if (u != m_lastUrl)   { m_lastUrl = u;   emit currentUrlChanged(); }
    if (h != m_lastHost)  { m_lastHost = h;  emit currentHostChanged(); }
    if (t != m_lastTitle) { m_lastTitle = t; emit currentTitleChanged(); }
    setWindowTitle(t.isEmpty() ? QString("edot Browser") : t + " — edot");
    updatePermission();
    emit navStateChanged();
    emit bookmarkedChanged();
    emit zoomChanged();
}

// ============================================================ popups, tooltips

void BrowserWindow::openPopup(const QString& kind, int x, int y) {
    closePopup();
    QVariantMap ctx;
    ctx["browser"] = QVariant::fromValue<QObject*>(this);
    ctx["theme"] = QVariant::fromValue<QObject*>(m_theme);
    ctx["settings"] = QVariant::fromValue<QObject*>(m_settings);
    ctx["store"] = QVariant::fromValue<QObject*>(m_store);

    auto* popup = new PopupWindow(ctx, windowHandle());
    connect(popup, &QWindow::visibleChanged, popup, [popup](bool visible) {
        if (!visible) popup->deleteLater();
    });
    m_popup = popup;
    const QString src = kind == "menu" ? "qrc:/qml/popups/MenuPopup.qml" : "qrc:/qml/popups/PermissionPopup.qml";
    if (!popup->present(src, m_chrome->mapToGlobal(QPoint(x, y)))) {
        popup->deleteLater();
        m_popup = nullptr;
    }
}

void BrowserWindow::closePopup() {
    if (m_popup) m_popup->hide();
}

void BrowserWindow::showTip(const QString& area, const QString& text, int x, int y) {
    QWidget* w = area == "rail" ? static_cast<QWidget*>(m_rail)
               : area == "pages" ? static_cast<QWidget*>(m_pages)
               : area == "chrome" ? static_cast<QWidget*>(m_chrome) : nullptr;
    if (!w || text.isEmpty()) return;
    QToolTip::showText(w->mapToGlobal(QPoint(x, y)), text, w);
}
void BrowserWindow::hideTip() { QToolTip::hideText(); }

// ============================================================ events

void BrowserWindow::resizeEvent(QResizeEvent* e) {
    QMainWindow::resizeEvent(e);
    if (m_snackbar) m_snackbar->reposition();
}

void BrowserWindow::closeEvent(QCloseEvent* e) {
    QJsonArray urls;
    for (int i = 0; m_tabs && i < m_tabs->count(); ++i)
        if (auto* v = viewAt(i)) {
            const QString u = v->url().toString();
            if (!u.isEmpty() && !u.startsWith("about:")) urls.append(u);
        }
    QDir().mkpath(configDir());
    QFile f(sessionFile());
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) f.write(QJsonDocument(urls).toJson(QJsonDocument::Compact));
    closePopup();
    QMainWindow::closeEvent(e);
}
