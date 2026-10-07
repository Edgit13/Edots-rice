#pragma once
#include <QWebEngineUrlRequestInterceptor>
#include "permissions.h"
#include "filter_engine.h"

class RequestInterceptor final : public QWebEngineUrlRequestInterceptor {
public:
    explicit RequestInterceptor(QObject* parent = nullptr);
    void interceptRequest(QWebEngineUrlRequestInfo& info) override;
    Permissions& permissions() { return m_permissions; }
    FilterEngine& filters() { return m_filters; }
private:
    Permissions m_permissions;
    FilterEngine m_filters;
};
