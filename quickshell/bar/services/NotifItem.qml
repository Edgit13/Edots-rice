import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// NotifItem — обгортка над Notification: знімок даних для історії + таймер спливаючого вікна.
Scope {
    id: item

    property var raw: null              // Notification | null (після закриття застосунком)
    property int nid: 0
    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property string desktopEntry: ""
    property string summary: ""
    property string body: ""
    property int urgency: 1             // 0 low · 1 normal · 2 critical
    property var actions: []            // [{id, text}]
    property real expireSec: 0
    property bool transient_: false
    property date time: new Date()

    // спливаюче вікно
    property bool popup: false
    property bool paused: false
    property real totalMs: 0            // 0 = липке (критичні)
    property real remainingMs: 0

    signal closedByApp()
    signal popupEnded()
    signal touched()

    function sync() {
        if (!raw) return
        nid = raw.id
        appName = raw.appName || ""
        appIcon = raw.appIcon || ""
        image = raw.image || ""
        desktopEntry = raw.desktopEntry || ""
        summary = raw.summary || ""
        body = raw.body || ""
        urgency = raw.urgency === NotificationUrgency.Critical ? 2
                : (raw.urgency === NotificationUrgency.Low ? 0 : 1)
        expireSec = raw.expireTimeout
        transient_ = !!raw.transient
        const a = []
        for (let i = 0; i < raw.actions.length; i++)
            a.push({ id: raw.actions[i].identifier, text: raw.actions[i].text })
        actions = a
    }

    function arm(ms) { totalMs = ms; remainingMs = ms; paused = false; popup = true }
    function touch() { time = new Date(); touched() }

    function hasDefault() {
        for (let i = 0; i < actions.length; i++) if (actions[i].id === "default") return true
        return false
    }
    function invoke(id) {
        if (!raw) return
        for (let i = 0; i < raw.actions.length; i++)
            if (raw.actions[i].identifier === id) { raw.actions[i].invoke(); return }
    }
    function close() { if (raw) raw.dismiss() }      // повідомити застосунок

    readonly property Timer _tick: Timer {
        interval: 40
        repeat: true
        running: item.popup && !item.paused && item.totalMs > 0
        onTriggered: {
            item.remainingMs -= 40
            if (item.remainingMs <= 0) { item.popup = false; item.popupEnded() }
        }
    }

    readonly property Connections _conn: Connections {
        target: item.raw
        ignoreUnknownSignals: true
        function onSummaryChanged() { item.sync(); item.touch() }
        function onBodyChanged()    { item.sync(); item.touch() }
        function onAppIconChanged() { item.sync() }
        function onImageChanged()   { item.sync() }
        function onActionsChanged() { item.sync() }
        function onClosed(reason)   { item.raw = null; item.popup = false; item.closedByApp() }
    }
}
