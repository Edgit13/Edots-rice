pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    property string query: ""
    readonly property bool active: query.trim().length > 0

    function matches(label) {
        if (!root.active) return true
        return String(label).toLowerCase().includes(root.query.trim().toLowerCase())
    }
    function clear() { query = "" }
}
