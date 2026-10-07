#include <QApplication>
#include <QWebEngineUrlScheme>
#include <QCoreApplication>
#include <QtGlobal>
#include "browser_window.h"

int main(int argc, char** argv) {
    // Потрібно, щоб QQuickWidget і QWebEngineView ділили один GL-контекст
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    // Власні M3-компоненти малюються самі - беремо найлегший стиль Controls
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))
        qputenv("QT_QUICK_CONTROLS_STYLE", "Basic");

    QWebEngineUrlScheme scheme("edot");
    scheme.setFlags(QWebEngineUrlScheme::SecureScheme | QWebEngineUrlScheme::LocalScheme
                    | QWebEngineUrlScheme::LocalAccessAllowed);
    QWebEngineUrlScheme::registerScheme(scheme);

    QApplication app(argc, argv);
    app.setApplicationName("edot-browser");
    app.setOrganizationName("edot");
    app.setStyle("Fusion");

    BrowserWindow window;
    window.show();
    return app.exec();
}
