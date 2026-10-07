#pragma once
#include <QPixmap>
#include <QQuickImageProvider>

class QQmlEngine;

// image://icon/<name>/<aarrggbb>   - Material-іконка потрібного кольору
// image://tab/<key>                - фавіконка вкладки
class IconProvider final : public QQuickImageProvider {
public:
    IconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}
    QPixmap requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) override;
};

class TabIconProvider final : public QQuickImageProvider {
public:
    TabIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}
    QPixmap requestPixmap(const QString& id, QSize* size, const QSize& requestedSize) override;
    static void setIcon(const QString& key, const QPixmap& pm);
    static void clear(const QString& key);
};

void installImageProviders(QQmlEngine* engine);
