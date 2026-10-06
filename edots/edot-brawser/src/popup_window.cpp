#include "popup_window.h"

#include "image_providers.h"

#include <QGuiApplication>
#include <QKeyEvent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickItem>
#include <QScreen>
#include <QSurfaceFormat>

PopupWindow::PopupWindow(const QVariantMap& context, QWindow* transientParent) {
    setTransientParent(transientParent);
    setFlags(Qt::Popup | Qt::FramelessWindowHint);
    setColor(Qt::transparent);
    QSurfaceFormat fmt = format();
    fmt.setAlphaBufferSize(8);
    setFormat(fmt);
    setResizeMode(QQuickView::SizeViewToRootObject);
    installImageProviders(engine());
    for (auto it = context.begin(); it != context.end(); ++it)
        rootContext()->setContextProperty(it.key(), it.value().value<QObject*>());
    rootContext()->setContextProperty("uiArea", QStringLiteral("popup"));
}

bool PopupWindow::present(const QString& qmlSource, const QPoint& anchor) {
    setSource(QUrl(qmlSource));
    if (status() != QQuickView::Ready || !rootObject()) {
        for (const auto& e : errors()) qWarning() << e.toString();
        return false;
    }
    const QSize s(int(rootObject()->width()), int(rootObject()->height()));
    QPoint pos(anchor.x() - s.width(), anchor.y());
    if (auto* scr = screen()) {
        const QRect avail = scr->availableGeometry();
        pos.setX(qBound(avail.left() + 4, pos.x(), avail.right() - s.width() - 4));
        pos.setY(qMin(pos.y(), avail.bottom() - s.height() - 4));
    }
    setPosition(pos);
    show();
    requestActivate();
    return true;
}

void PopupWindow::keyPressEvent(QKeyEvent* e) {
    if (e->key() == Qt::Key_Escape) {
        hide();
        return;
    }
    QQuickView::keyPressEvent(e);
}
