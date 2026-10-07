#include "theme.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <algorithm>
#include <cmath>

namespace {

constexpr double kPi = 3.14159265358979323846;

double toLin(double c) { return c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4); }
double toSrgb(double c) {
    c = std::clamp(c, 0.0, 1.0);
    return c <= 0.0031308 ? 12.92 * c : 1.055 * std::pow(c, 1.0 / 2.4) - 0.055;
}

struct Lch { double L, C, h; };

Lch toOklch(const QColor& col) {
    const double r = toLin(col.redF()), g = toLin(col.greenF()), b = toLin(col.blueF());
    const double l = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const double m = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const double s = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    const double L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    const double a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    const double bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    double h = std::atan2(bb, a) * 180.0 / kPi;
    if (h < 0) h += 360.0;
    return {L, std::hypot(a, bb), h};
}

void oklchToLin(double L, double C, double h, double out[3]) {
    const double a = C * std::cos(h * kPi / 180.0), b = C * std::sin(h * kPi / 180.0);
    const double l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    const double m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    const double s_ = L - 0.0894841775 * a - 1.2914855480 * b;
    const double l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    out[0] = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
    out[1] = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
    out[2] = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;
}

// Зменшує chroma, поки колір не вміщається в sRGB
QString oklchHex(double L, double C, double h) {
    double lin[3];
    for (int i = 0; i < 80; ++i) {
        oklchToLin(L, C, h, lin);
        const bool ok = std::all_of(lin, lin + 3, [](double v) { return v >= -1e-4 && v <= 1.0 + 1e-4; });
        if (ok || C <= 0) break;
        C = std::max(0.0, C - 0.004);
    }
    oklchToLin(L, C, h, lin);
    return QColor::fromRgbF(toSrgb(lin[0]), toSrgb(lin[1]), toSrgb(lin[2])).name();
}

// M3 tone (CIE L*) -> OKLab L
double toneToL(double t) {
    const double y = t <= 8 ? t / 903.3 : std::pow((t + 16) / 116.0, 3);
    return std::cbrt(y);
}

QString tone(double hue, double chroma, double t) { return oklchHex(toneToL(t), chroma, hue); }

bool validHex(const QString& s) {
    static const QRegularExpression re("^#[0-9a-fA-F]{6}$");
    return re.match(s).hasMatch();
}

QJsonObject loadDotfiles(bool* found) {
    const QString home = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    const QStringList candidates = {
        QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + "/mango/colors.json",
        home + "/Dotfiles/mango/colors.json",
    };
    for (const QString& path : candidates) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly)) continue;
        const auto doc = QJsonDocument::fromJson(f.readAll());
        if (doc.isObject()) {
            *found = true;
            return doc.object();
        }
    }
    *found = false;
    return {};
}

} // namespace

Theme::Theme(QObject* parent) : QObject(parent) { load({}); }

QVariantMap Theme::generate(const QString& seed, bool dark) {
    const Lch lch = toOklch(QColor(seed));
    const double h = lch.h;
    const double chroma = lch.C > 0.02 ? std::clamp(lch.C, 0.10, 0.16) : 0.0;
    auto P = [&](double t) { return tone(h, chroma, t); };
    auto S = [&](double t) { return tone(h, chroma * 0.33, t); };
    auto T = [&](double t) { return tone(std::fmod(h + 60, 360.0), chroma * 0.6, t); };
    auto N = [&](double t) { return tone(h, chroma * 0.06, t); };
    auto NV = [&](double t) { return tone(h, chroma * 0.12, t); };

    QVariantMap s;
    if (dark) {
        s = {
            {"primary", P(80)}, {"on_primary", P(20)}, {"primary_container", P(30)}, {"on_primary_container", P(90)},
            {"secondary", S(80)}, {"on_secondary", S(20)}, {"secondary_container", S(30)}, {"on_secondary_container", S(90)},
            {"tertiary", T(80)}, {"on_tertiary", T(20)}, {"tertiary_container", T(30)}, {"on_tertiary_container", T(90)},
            {"error", "#ffb4ab"}, {"on_error", "#690005"}, {"error_container", "#93000a"}, {"on_error_container", "#ffdad6"},
            {"surface", N(6)}, {"surface_dim", N(6)}, {"surface_bright", N(24)},
            {"surface_container_lowest", N(4)}, {"surface_container_low", N(10)}, {"surface_container", N(12)},
            {"surface_container_high", N(17)}, {"surface_container_highest", N(22)},
            {"on_surface", N(90)}, {"on_surface_variant", NV(80)}, {"outline", NV(60)}, {"outline_variant", NV(30)},
            {"inverse_surface", N(90)}, {"inverse_on_surface", N(20)}, {"inverse_primary", P(40)},
        };
    } else {
        s = {
            {"primary", P(40)}, {"on_primary", P(100)}, {"primary_container", P(90)}, {"on_primary_container", P(10)},
            {"secondary", S(40)}, {"on_secondary", S(100)}, {"secondary_container", S(90)}, {"on_secondary_container", S(10)},
            {"tertiary", T(40)}, {"on_tertiary", T(100)}, {"tertiary_container", T(90)}, {"on_tertiary_container", T(10)},
            {"error", "#ba1a1a"}, {"on_error", "#ffffff"}, {"error_container", "#ffdad6"}, {"on_error_container", "#410002"},
            {"surface", N(98)}, {"surface_dim", N(87)}, {"surface_bright", N(98)},
            {"surface_container_lowest", N(100)}, {"surface_container_low", N(96)}, {"surface_container", N(94)},
            {"surface_container_high", N(92)}, {"surface_container_highest", N(90)},
            {"on_surface", N(10)}, {"on_surface_variant", NV(30)}, {"outline", NV(50)}, {"outline_variant", NV(80)},
            {"inverse_surface", N(20)}, {"inverse_on_surface", N(95)}, {"inverse_primary", P(80)},
        };
    }
    return s;
}

void Theme::load(const QVariantMap& settings) {
    const QString mode = settings.value("theme_mode", "dotfiles").toString();
    QString accent = settings.value("accent", "#9ccbfb").toString();
    if (!validHex(accent)) accent = "#9ccbfb";
    m_animations = settings.value("enable_animations", true).toBool();

    bool found = false;
    const QJsonObject file = loadDotfiles(&found);
    m_dotfiles = found;

    if (mode == "dotfiles" && found) {
        m_dark = file.value("mode").toString("dark").toLower() != "light";
        const QString primary = file.value("primary").toString();
        m_colors = generate(validHex(primary) ? primary : accent, m_dark);
        // Старий формат: bg0 / bg1 / fg
        static const QHash<QString, QString> aliases = {
            {"bg0", "surface"}, {"bg1", "surface_container_low"}, {"fg", "on_surface"}};
        for (auto it = file.begin(); it != file.end(); ++it) {
            const QString key = aliases.value(it.key(), it.key());
            const QString val = it.value().toString();
            if (m_colors.contains(key) && validHex(val)) m_colors[key] = val.toLower();
        }
    } else {
        m_dark = mode != "light";
        m_colors = generate(accent, m_dark);
    }
    emit changed();
}

QColor Theme::alpha(const QColor& c, qreal a) const {
    QColor out = c;
    out.setAlphaF(std::clamp(a, 0.0, 1.0));
    return out;
}

QColor Theme::mix(const QColor& a, const QColor& b, qreal t) const {
    return QColor::fromRgbF(a.redF() + (b.redF() - a.redF()) * t,
                            a.greenF() + (b.greenF() - a.greenF()) * t,
                            a.blueF() + (b.blueF() - a.blueF()) * t);
}

QString Theme::accentPreview(const QString& seed) const {
    return generate(validHex(seed) ? seed : "#9ccbfb", m_dark).value("primary").toString();
}
