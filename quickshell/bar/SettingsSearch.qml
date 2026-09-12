pragma Singleton
import "root:/"
import Quickshell
import QtQuick

// ==========================================================================
// SettingsSearch.qml — пошук по контролах Settings UI.
// Контроли самі фільтруються через SettingsSearch.matches(label); коли
// запит активний, SettingsApp показує ВСІ сторінки (flatten-режим).
// ==========================================================================

Singleton {
    id: searchRoot

    property string query: ""
    readonly property bool active: query.trim().length > 0

    function matches(text) {
        if (!active)
            return true
        return String(text).toLowerCase().includes(query.trim().toLowerCase())
    }

    function clear() {
        query = ""
    }
}
