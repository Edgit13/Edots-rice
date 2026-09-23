pragma Singleton
import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick

// ==========================================================================
// TasksStore.qml — таси календаря (Dashboard). Персистентність:
// ~/.config/quickshell/tasks.json  {"YYYY-MM-DD": [{time, title, done}]}
// ==========================================================================

Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.config/quickshell/tasks.json"
    property var data: ({})
    property bool loaded: false

    FileView {
        id: store
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.merge(text())
        Component.onCompleted: root.merge(text())
    }

    function merge(text) {
        try {
            root.data = (text && text.trim().length > 0) ? JSON.parse(text) : {}
        } catch (e) {
            console.warn("TasksStore: parse error:", e)
            root.data = {}
        }
        root.loaded = true
    }

    function save() {
        store.setText(JSON.stringify(root.data, null, 2))
    }

    function tasksFor(dateStr) {
        return root.data[dateStr] || []
    }

    function add(dateStr, time, title) {
        const next = Object.assign({}, root.data)
        const arr = (next[dateStr] || []).slice()
        arr.push({ time: time, title: title, done: false })
        arr.sort((a, b) => String(a.time).localeCompare(String(b.time)))
        next[dateStr] = arr
        root.data = next
        root.save()
    }

    function toggleDone(dateStr, idx) {
        const next = Object.assign({}, root.data)
        const arr = (next[dateStr] || []).slice()
        if (idx < 0 || idx >= arr.length) return
        arr[idx] = Object.assign({}, arr[idx], { done: !arr[idx].done })
        next[dateStr] = arr
        root.data = next
        root.save()
    }

    function remove(dateStr, idx) {
        const next = Object.assign({}, root.data)
        const arr = (next[dateStr] || []).slice()
        if (idx < 0 || idx >= arr.length) return
        arr.splice(idx, 1)
        if (arr.length === 0) delete next[dateStr]
        else next[dateStr] = arr
        root.data = next
        root.save()
    }
}
