#pragma once

#include <QMainWindow>
#include <QPointer>
#include <QStringList>
#include <QVariantList>
#include <QWebEngineProfile>
#include <QWebEngineView>

#include "request_interceptor.h"

class QQuickWidget;
class QStackedWidget;
class QTabWidget;
class AppSettings;
class DataStore;
class FilterUpdater;
class I18n;
class PopupWindow;
class RoundedFrame;
class Snackbar;
class Theme;
class QWebEngineDownloadRequest;

class BrowserWindow final : public QMainWindow {
    Q_OBJECT
    Q_PROPERTY(QString currentUrl READ currentUrl NOTIFY currentUrlChanged)
    Q_PROPERTY(QString currentHost READ currentHost NOTIFY currentHostChanged)
    Q_PROPERTY(QString currentTitle READ currentTitle NOTIFY currentTitleChanged)
    Q_PROPERTY(QString permission READ permission NOTIFY permissionChanged)
    Q_PROPERTY(int loadProgress READ loadProgress NOTIFY loadProgressChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QVariantList tabs READ tabs NOTIFY tabsChanged)
    Q_PROPERTY(QString section READ section NOTIFY sectionChanged)
    Q_PROPERTY(bool canGoBack READ canGoBack NOTIFY navStateChanged)
    Q_PROPERTY(bool canGoForward READ canGoForward NOTIFY navStateChanged)
    Q_PROPERTY(bool bookmarked READ bookmarked NOTIFY bookmarkedChanged)
    Q_PROPERTY(int zoomPercent READ zoomPercent NOTIFY zoomChanged)
    Q_PROPERTY(QStringList trustedSites READ trustedSites NOTIFY permissionsListChanged)
    Q_PROPERTY(QStringList blockedSites READ blockedSites NOTIFY permissionsListChanged)
    Q_PROPERTY(int filterLists READ filterLists NOTIFY filtersChanged)
    Q_PROPERTY(bool filtersBusy READ filtersBusy NOTIFY filtersChanged)
    Q_PROPERTY(QString versionInfo READ versionInfo CONSTANT)
    Q_PROPERTY(QString dataFolder READ dataFolder CONSTANT)
public:
    explicit BrowserWindow(QWidget* parent = nullptr);
    ~BrowserWindow() override;

    QString currentUrl() const;
    QString currentHost() const;
    QString currentTitle() const;
    QString permission() const;
    int loadProgress() const { return m_loadProgress; }
    bool loading() const { return m_loading; }
    QVariantList tabs() const;
    QString section() const { return m_section; }
    bool canGoBack() const;
    bool canGoForward() const;
    bool bookmarked() const;
    int zoomPercent() const;
    QStringList trustedSites() const { return m_interceptor->permissions().trusted(); }
    QStringList blockedSites() const { return m_interceptor->permissions().blocked(); }
    int filterLists() const { return m_interceptor->filters().loadedLists(); }
    bool filtersBusy() const;
    QString versionInfo() const;
    QString dataFolder() const;

    // --- навігація ---
    Q_INVOKABLE void navigate(const QString& text);
    Q_INVOKABLE void back();
    Q_INVOKABLE void forward();
    Q_INVOKABLE void reload();
    Q_INVOKABLE void hardReload();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void goHome();
    Q_INVOKABLE void focusWeb();
    Q_INVOKABLE void openUrl(const QString& url);
    // --- вкладки ---
    Q_INVOKABLE void newTab();
    Q_INVOKABLE void activateTab(int index);
    Q_INVOKABLE void closeTab(int index);
    // --- розділи, закладки ---
    Q_INVOKABLE void showSection(const QString& name);
    Q_INVOKABLE void showSettings() { showSection("settings"); }
    Q_INVOKABLE void toggleBookmark();
    // --- дозволи сайтів ---
    Q_INVOKABLE void setPermission(const QString& mode);
    Q_INVOKABLE void setSitePermission(const QString& host, const QString& mode);
    Q_INVOKABLE void removeSitePermission(const QString& host);
    // --- масштаб ---
    Q_INVOKABLE void zoomBy(int delta);
    // --- фільтри, дані ---
    Q_INVOKABLE void updateFilters();
    Q_INVOKABLE void clearData(const QString& kind);
    // --- допоміжне для QML ---
    Q_INVOKABLE void openPopup(const QString& kind, int x, int y);
    Q_INVOKABLE void closePopup();
    Q_INVOKABLE void showTip(const QString& area, const QString& text, int x, int y);
    Q_INVOKABLE void hideTip();
    Q_INVOKABLE void notify(const QString& text);

signals:
    void currentUrlChanged();
    void currentHostChanged();
    void currentTitleChanged();
    void permissionChanged();
    void loadProgressChanged();
    void loadingChanged();
    void tabsChanged();
    void sectionChanged();
    void navStateChanged();
    void bookmarkedChanged();
    void zoomChanged();
    void permissionsListChanged();
    void filtersChanged();
    void focusAddressRequested();

protected:
    void resizeEvent(QResizeEvent* e) override;
    void closeEvent(QCloseEvent* e) override;

private:
    void setupProfile();
    void setupUi();
    void setupShortcuts();
    void applyTheme();
    QQuickWidget* makeQuick(const QString& qml, const QString& area, int minWidth = 0);
    void addTab(const QUrl& url, bool activate = true);
    void openStartupTabs();
    void onDownload(QWebEngineDownloadRequest* req);
    QWebEngineView* currentView() const;
    QWebEngineView* viewAt(int i) const;
    QUrl resolveInput(const QString& text) const;
    void updateChromeState();
    void updateTabs() { emit tabsChanged(); }
    void updatePermission();
    void syncLoadingState();
    static QString tabKey(const QWebEngineView* v);

    QWebEngineProfile* m_profile = nullptr;
    RequestInterceptor* m_interceptor = nullptr;
    Theme* m_theme = nullptr;
    AppSettings* m_settings = nullptr;
    DataStore* m_store = nullptr;
    FilterUpdater* m_updater = nullptr;
    I18n* m_i18n = nullptr;

    QWidget* m_root = nullptr;
    QQuickWidget* m_rail = nullptr;
    QQuickWidget* m_chrome = nullptr;
    QQuickWidget* m_pages = nullptr;
    RoundedFrame* m_frame = nullptr;
    QStackedWidget* m_content = nullptr;
    QTabWidget* m_tabs = nullptr;
    Snackbar* m_snackbar = nullptr;
    QPointer<PopupWindow> m_popup;

    QString m_section = "browser";
    int m_loadProgress = 0;
    bool m_loading = false;
    bool m_manualFilterUpdate = false;
    QString m_lastUrl, m_lastHost, m_lastTitle, m_lastPermission;
    quint64 m_iconRevision = 0;
};
