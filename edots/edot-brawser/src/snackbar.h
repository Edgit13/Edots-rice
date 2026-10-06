#pragma once
#include <QFrame>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QTimer>
#include <functional>

#include "theme.h"

// M3 snackbar - звичайний віджет поверх веб-в'ю
class Snackbar : public QFrame {
public:
    explicit Snackbar(QWidget* parent) : QFrame(parent) {
        setObjectName("snackbar");
        auto* lay = new QHBoxLayout(this);
        lay->setContentsMargins(16, 6, 8, 6);
        lay->setSpacing(8);
        m_label = new QLabel;
        m_action = new QPushButton;
        m_action->setObjectName("snackAction");
        m_action->setCursor(Qt::PointingHandCursor);
        m_action->setFlat(true);
        lay->addWidget(m_label);
        lay->addWidget(m_action);
        m_timer.setSingleShot(true);
        QObject::connect(&m_timer, &QTimer::timeout, this, [this] { hide(); });
        QObject::connect(m_action, &QPushButton::clicked, this, [this] {
            hide();
            if (m_callback) m_callback();
        });
        hide();
    }

    void applyTheme(const Theme* t) {
        setStyleSheet(QString(
            "QFrame#snackbar { background: %1; border-radius: 8px; }"
            "QFrame#snackbar QLabel { color: %2; font-size: 14px; background: transparent; }"
            "QPushButton#snackAction { color: %3; background: transparent; border: none; padding: 6px 10px;"
            " font-size: 14px; font-weight: 600; }")
            .arg(t->color("inverse_surface").name(), t->color("inverse_on_surface").name(),
                 t->color("inverse_primary").name()));
    }

    void showMessage(const QString& text, int ms = 3500, const QString& action = {},
                     std::function<void()> cb = {}) {
        m_label->setText(text);
        m_callback = std::move(cb);
        m_action->setVisible(!action.isEmpty());
        m_action->setText(action);
        adjustSize();
        reposition();
        show();
        raise();
        m_timer.start(ms);
    }

    void reposition() {
        if (auto* p = parentWidget()) move((p->width() - width()) / 2, p->height() - height() - 28);
    }

private:
    QLabel* m_label;
    QPushButton* m_action;
    QTimer m_timer;
    std::function<void()> m_callback;
};
