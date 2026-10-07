#pragma once
#include <QEvent>
#include <QHBoxLayout>
#include <QPainter>
#include <QPainterPath>
#include <QRegion>
#include <QResizeEvent>
#include <QWidget>

#include "theme.h"

// Закруглена рамка навколо вмісту (веб-сторінка / внутрішні сторінки).
// Дочірній віджет обрізається маскою по тому ж радіусу.
class RoundedFrame : public QWidget {
public:
    RoundedFrame(Theme* theme, QWidget* parent = nullptr) : QWidget(parent), m_theme(theme) {
        setAttribute(Qt::WA_StyledBackground, false);
        QObject::connect(theme, &Theme::changed, this, [this] { update(); });
    }

    void setClipChild(QWidget* child) {
        m_child = child;
        child->installEventFilter(this);
        applyMask();
    }

    static constexpr int kRadius = 16;

protected:
    void paintEvent(QPaintEvent*) override {
        QPainter p(this);
        p.setRenderHint(QPainter::Antialiasing);
        const QRectF r = QRectF(rect()).adjusted(0.5, 0.5, -0.5, -0.5);
        p.setBrush(m_theme->color("surface_container_low"));
        p.setPen(QPen(m_theme->color("outline_variant"), 1));
        p.drawRoundedRect(r, kRadius, kRadius);
    }

    bool eventFilter(QObject* obj, QEvent* e) override {
        if (obj == m_child && e->type() == QEvent::Resize) applyMask();
        return QWidget::eventFilter(obj, e);
    }

private:
    void applyMask() {
        if (!m_child) return;
        QPainterPath path;
        path.addRoundedRect(QRectF(m_child->rect()), kRadius - 1, kRadius - 1);
        m_child->setMask(QRegion(path.toFillPolygon().toPolygon()));
    }

    Theme* m_theme;
    QWidget* m_child = nullptr;
};
