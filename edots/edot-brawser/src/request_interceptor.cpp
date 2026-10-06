#include "request_interceptor.h"
#include <QWebEngineUrlRequestInfo>
#include <QUrl>
#include <QStandardPaths>
RequestInterceptor::RequestInterceptor(QObject* p) : QWebEngineUrlRequestInterceptor(p) {
    m_filters.loadAsync(filtersCacheDir());
}
static QString typeName(QWebEngineUrlRequestInfo::ResourceType t) {
    using T = QWebEngineUrlRequestInfo::ResourceType;
    switch(t) {
        case T::ResourceTypeMainFrame: return "document"; case T::ResourceTypeSubFrame: return "subdocument";
        case T::ResourceTypeStylesheet: return "stylesheet"; case T::ResourceTypeScript: return "script";
        case T::ResourceTypeImage: return "image"; case T::ResourceTypeFontResource: return "font";
        case T::ResourceTypeSubResource: return "other"; case T::ResourceTypeObject: return "object";
        case T::ResourceTypeMedia: return "media"; case T::ResourceTypeWorker: return "script";
        case T::ResourceTypeSharedWorker: return "script"; case T::ResourceTypePrefetch: return "other";
        case T::ResourceTypeFavicon: return "image"; case T::ResourceTypeXhr: return "xmlhttprequest";
        case T::ResourceTypePing: return "ping"; case T::ResourceTypeServiceWorker: return "script";
        default: return "other";
    }
}
void RequestInterceptor::interceptRequest(QWebEngineUrlRequestInfo& info) {
    const QUrl url = info.requestUrl(); if (!url.isValid() || (url.scheme() != "http" && url.scheme() != "https")) return;
    const auto d = m_permissions.decision(url);
    if (d == Permissions::Decision::Trusted) return;
    if (d == Permissions::Decision::Blocked) { info.block(true); return; }
    QUrl source = info.firstPartyUrl(); if (!source.isValid()) source = url;
    if (m_filters.shouldBlock(url, source, typeName(info.resourceType()))) info.block(true);
}
