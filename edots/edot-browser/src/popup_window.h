#pragma once
#include <QPoint>
#include <QQuickView>

class QObject;

// Спливаюче вікно (меню, дозволи сайту): окреме вікно Qt::Popup, тому не обрізається
// маленьким віджетом панелі.
class PopupWindow final : public QQuickView {
    Q_OBJECT
public:
    PopupWindow(const QVariantMap& context, QWindow* transientParent);
    // anchor - глобальна точка правого верхнього кута, під яким з'являється попап
    bool present(const QString& qmlSource, const QPoint& anchor);

protected:
    void keyPressEvent(QKeyEvent* e) override;
};
