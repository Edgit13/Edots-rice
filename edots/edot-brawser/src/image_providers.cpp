#include "image_providers.h"

#include "icon_paths.h"

#include <QColor>
#include <QHash>
#include <QMutex>
#include <QMutexLocker>
#include <QPainter>
#include <QQmlEngine>
#include <QSvgRenderer>

namespace {
QMutex g_tabMutex;
QHash<QString, QPixmap> g_tabIcons;
}

QPixmap IconProvider::requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) {
    const QStringList parts = id.section('?', 0, 0).split('/');
    const QString name = parts.value(0);
    const QString colorHex = parts.value(1);
    const int px = requestedSize.width() > 0 ? requestedSize.width() : 48;

    QPixmap pm(px, px);
    pm.fill(Qt::transparent);
    const QString path = iconPaths().value(name);
    if (!path.isEmpty()) {
        const QColor col("#" + colorHex);
        const QString svg = QString("<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 24\">"
                                    "<path fill=\"%1\" fill-opacity=\"%2\" d=\"%3\"/></svg>")
                                .arg(col.isValid() ? col.name() : "#ffffff")
                                .arg(col.isValid() ? col.alphaF() : 1.0)
                                .arg(path);
        QSvgRenderer renderer(svg.toUtf8());
        QPainter p(&pm);
        p.setRenderHint(QPainter::Antialiasing);
        renderer.render(&p);
    }
    if (size) *size = pm.size();
    return pm;
}

QPixmap TabIconProvider::requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) {
    const QString key = id.section('?', 0, 0);
    QPixmap pm;
    {
        QMutexLocker l(&g_tabMutex);
        pm = g_tabIcons.value(key);
    }
    if (pm.isNull()) {
        pm = QPixmap(1, 1);
        pm.fill(Qt::transparent);
    } else if (requestedSize.isValid() && requestedSize.width() > 0) {
        pm = pm.scaled(requestedSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }
    if (size) *size = pm.size();
    return pm;
}

void TabIconProvider::setIcon(const QString& key, const QPixmap& pm) {
    QMutexLocker l(&g_tabMutex);
    g_tabIcons.insert(key, pm);
}

void TabIconProvider::clear(const QString& key) {
    QMutexLocker l(&g_tabMutex);
    g_tabIcons.remove(key);
}

void installImageProviders(QQmlEngine* engine) {
    engine->addImageProvider("icon", new IconProvider);
    engine->addImageProvider("tab", new TabIconProvider);
}
