#include "permissions.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>
#include <QStandardPaths>
#include <QUrl>
#include <QMutexLocker>

Permissions::Permissions() {
    m_path = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/edot-browser/permissions.json";
    load();
}
QString Permissions::normalize(QString host) const {
    host = host.trimmed().toLower();
    if (host.contains("://")) host = QUrl(host).host();
    host = host.section('/', 0, 0).section(':', 0, 0);
    if (host.startsWith("www.")) host.remove(0, 4);
    while (host.endsWith('.')) host.chop(1);
    return host;
}
bool Permissions::matches(const QString& rule, const QString& host) const {
    return !rule.isEmpty() && (host == rule || host.endsWith("." + rule));
}
Permissions::Decision Permissions::decision(const QUrl& url) const {
    QMutexLocker lock(&m_mutex);
    const QString host = normalize(url.host());
    if (host.isEmpty()) return Decision::Default;
    const auto keys = m_sites.keys();
    QString best; QString bestDecision;
    for (const QString& key : keys) if (matches(key, host) && key.size() > best.size()) { best = key; bestDecision = m_sites.value(key).toString(); }
    if (!best.isEmpty()) {
        if (bestDecision == "trusted") return Decision::Trusted;
        if (bestDecision == "blocked") return Decision::Blocked;
    }
    for (const auto& x : m_trusted) if (matches(x, host)) return Decision::Trusted;
    for (const auto& x : m_blocked) if (matches(x, host)) return Decision::Blocked;
    return Decision::Default;
}
void Permissions::setSite(const QString& rawHost, Decision d) {
    QMutexLocker lock(&m_mutex);
    const QString host = normalize(rawHost); if (host.isEmpty()) return;
    m_trusted.remove(host); m_blocked.remove(host); m_sites.remove(host);
    if (d == Decision::Trusted) m_trusted.insert(host);
    else if (d == Decision::Blocked) m_blocked.insert(host);
    save();
}
void Permissions::remove(const QString& rawHost) {
    QMutexLocker lock(&m_mutex);
    const QString host = normalize(rawHost); m_trusted.remove(host); m_blocked.remove(host); m_sites.remove(host); save();
}
void Permissions::load() {
    QFile f(m_path); if (!f.open(QIODevice::ReadOnly)) return;
    const auto doc = QJsonDocument::fromJson(f.readAll()); if (!doc.isObject()) return;
    const auto o = doc.object();
    for (const auto& v : o.value("trusted").toArray()) m_trusted.insert(normalize(v.toString()));
    for (const auto& v : o.value("blocked").toArray()) m_blocked.insert(normalize(v.toString()));
    m_sites = o.value("sites").toObject();
}
void Permissions::save() const {
    QDir().mkpath(QFileInfo(m_path).absolutePath());
    QJsonObject o; QJsonArray t, b; for (const auto& x : m_trusted) t.append(x); for (const auto& x : m_blocked) b.append(x);
    o["trusted"] = t; o["blocked"] = b; o["sites"] = m_sites;
    QFile f(m_path); if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) f.write(QJsonDocument(o).toJson(QJsonDocument::Indented));
}

QStringList Permissions::trusted() const {
    QMutexLocker lock(&m_mutex);
    QStringList out(m_trusted.begin(), m_trusted.end());
    out.sort();
    return out;
}
QStringList Permissions::blocked() const {
    QMutexLocker lock(&m_mutex);
    QStringList out(m_blocked.begin(), m_blocked.end());
    out.sort();
    return out;
}
