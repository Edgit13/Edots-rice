#pragma once
#include <QColor>
#include <QObject>
#include <QVariantMap>

// Повна схема ролей Material 3 (dark/light), згенерована в OKLCH з акценту,
// або з colors.json (matugen / dotfiles) з добудовою відсутніх ролей.
class Theme final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap c READ colors NOTIFY changed)
    Q_PROPERTY(bool dark READ dark NOTIFY changed)
    Q_PROPERTY(bool animations READ animations NOTIFY changed)
    Q_PROPERTY(bool dotfilesFound READ dotfilesFound NOTIFY changed)
public:
    explicit Theme(QObject* parent = nullptr);

    void load(const QVariantMap& settings);

    QVariantMap colors() const { return m_colors; }
    QColor color(const QString& role) const { return QColor(m_colors.value(role).toString()); }
    bool dark() const { return m_dark; }
    bool animations() const { return m_animations; }
    bool dotfilesFound() const { return m_dotfiles; }

    Q_INVOKABLE QColor alpha(const QColor& c, qreal a) const;
    Q_INVOKABLE QColor mix(const QColor& a, const QColor& b, qreal t) const;
    // Колір primary, який дасть акцент у поточному режимі (для свотчів)
    Q_INVOKABLE QString accentPreview(const QString& seed) const;

    static QVariantMap generate(const QString& seed, bool dark);

signals:
    void changed();

private:
    QVariantMap m_colors;
    bool m_dark = true;
    bool m_animations = true;
    bool m_dotfiles = false;
};
