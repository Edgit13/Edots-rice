pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// TodoService — список справ у ~/.local/state/edots/todos.json (переживає перезапуск shell).
// {id, text, done, due: "YYYY-MM-DD" | "", time: "HH:MM" | "", timerId, created, doneAt}
// Якщо задано і дату, і час — створюється таймер utimer (TimerService), який нагадає у цей момент.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.local/state/edots"
    readonly property string file: dir + "/todos.json"

    property var todos: []
    readonly property int activeCount: todos.filter(t => !t.done).length
    readonly property int overdueCount: todos.filter(t => !t.done && t.due && t.due < today()).length

    // дата → кількість активних справ (для крапок у календарі)
    readonly property var dueMap: {
        const m = {}
        for (let i = 0; i < todos.length; i++) {
            const t = todos[i]
            if (!t.done && t.due) m[t.due] = (m[t.due] || 0) + 1
        }
        return m
    }

    // id таймерів, що належать справам (щоб не дублювати їх у списку нагадувань)
    readonly property var timerIds: {
        const m = {}
        for (let i = 0; i < todos.length; i++) if (todos[i].timerId) m[todos[i].timerId] = true
        return m
    }

    function _pad(n) { return (n < 10 ? "0" : "") + n }
    function ymd(d) { return d.getFullYear() + "-" + _pad(d.getMonth() + 1) + "-" + _pad(d.getDate()) }
    function today() { return ymd(new Date()) }
    function tomorrow() { const d = new Date(); d.setDate(d.getDate() + 1); return ymd(d) }

    // повертає id справи; time "HH:MM" разом із due створює нагадування
    function add(text, due, time) {
        const t = String(text).trim()
        if (t.length === 0) return ""
        const id = Date.now().toString(36) + Math.floor(Math.random() * 1296).toString(36)
        const tm = (due && /^\d{1,2}:\d{2}$/.test(time || "")) ? time : ""
        todos = [{ id: id, text: t, done: false, due: due || "", time: tm, timerId: "",
                   created: Date.now(), doneAt: 0 }].concat(todos)
        _save()
        if (tm) _arm(id, due, tm, t)
        return id
    }
    function _arm(id, due, time, text) {
        TimerService.scheduleAt(due, time, text, tid => { if (tid) setTimer(id, tid) })
    }
    function setTimer(id, tid) { _update(id, t => { t.timerId = tid; return t }) }
    function _find(id) { for (let i = 0; i < todos.length; i++) if (todos[i].id === id) return todos[i]; return null }
    function _update(id, fn) {
        todos = todos.map(t => t.id === id ? fn(Object.assign({}, t)) : t)
        _save()
    }
    function toggle(id) {
        _update(id, t => {
            t.done = !t.done
            t.doneAt = t.done ? Date.now() : 0
            if (t.done && t.timerId) { TimerService.cancel(t.timerId); t.timerId = "" }     // виконано — нагадування не потрібне
            return t
        })
    }
    function edit(id, text)   { const s = String(text).trim(); if (s.length > 0) _update(id, t => { t.text = s; return t }) }
    function setDue(id, due) {
        const old = _find(id)
        if (old && old.timerId) TimerService.cancel(old.timerId)
        _update(id, t => { t.due = due; t.timerId = ""; return t })
        // дату змінили — переносимо нагадування на нову
        if (old && old.time && due && !old.done) _arm(id, due, old.time, old.text)
    }
    function remove(id) {
        const old = _find(id)
        if (old && old.timerId) TimerService.cancel(old.timerId)
        todos = todos.filter(t => t.id !== id)
        _save()
    }
    function clearDone()      { todos = todos.filter(t => !t.done); _save() }

    // filter: all | active | done; day: "" або "YYYY-MM-DD"
    function list(filter, day) {
        const out = todos.filter(t => (filter === "all" || (filter === "done") === t.done) && (!day || t.due === day))
        out.sort((a, b) => {
            if (a.done !== b.done) return a.done ? 1 : -1
            if (a.done) return b.doneAt - a.doneAt
            if (!!a.due !== !!b.due) return a.due ? -1 : 1               // з датою — вище
            if (a.due !== b.due) return a.due < b.due ? -1 : 1
            return b.created - a.created
        })
        return out
    }

    // ---- файл ----
    property string _lastWritten: ""
    Process { id: mkdir; command: ["mkdir", "-p", root.dir]; running: true }

    FileView {
        path: root.file
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onTextChanged: root._load(text())
    }
    FileView { id: writer; path: root.file; atomicWrites: true; printErrors: false }

    function _load(t) {
        if (t === _lastWritten || t.trim().length === 0) return
        try {
            const a = JSON.parse(t)
            if (Array.isArray(a)) todos = a
        } catch (e) { console.warn("TodoService: не вдалося прочитати todos.json:", e) }
    }
    function _save() { saveTimer.restart() }
    Timer {
        id: saveTimer
        interval: 250
        onTriggered: {
            const s = JSON.stringify(root.todos, null, 1)
            root._lastWritten = s
            writer.setText(s)
        }
    }
}
