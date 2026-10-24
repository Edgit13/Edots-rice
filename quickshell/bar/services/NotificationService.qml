pragma Singleton
import "root:/settings"
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// NotificationService — власний демон сповіщень (замість swaync), як у end-4:
// NotificationServer → історія → спливаючі вікна + центр сповіщень. Не запускай swaync паралельно.
Singleton {
    id: root

    // ---- налаштування ----
    readonly property bool masterPopups: !!Settings.get("general", "notifEnabled")
    readonly property bool dnd: !!Settings.get("notif", "dnd")
    readonly property bool toasts: Settings.get("notif", "toasts") !== false      // спливаючі вікна
    readonly property bool barLive: Settings.get("notif", "bar") !== false        // сповіщення прямо в барі
    readonly property string position: String(Settings.get("notif", "position") || "top-right")
    readonly property real margin: Number(Settings.get("notif", "margin") ?? 16)
    readonly property real cardWidth: Number(Settings.get("notif", "width") ?? 380)
    readonly property real timeoutNormal: Number(Settings.get("notif", "timeout") ?? 6)
    readonly property real timeoutLow: Number(Settings.get("notif", "timeoutLow") ?? 4)
    readonly property int maxVisible: Math.round(Number(Settings.get("notif", "maxVisible") ?? 4))
    function setDnd(v) { Settings.set("notif", "dnd", v) }

    // ---- дані ----
    property var items: []                           // новіші першими
    readonly property int count: items.length
    readonly property var popups: items.filter(i => i.popup).slice(0, maxVisible)
    readonly property var latest: popups.length > 0 ? popups[0] : null
    readonly property var groups: {
        const map = {}, out = []
        for (let i = 0; i < items.length; i++) {
            const k = items[i].appName || items[i].desktopEntry || "—"
            if (!map[k]) { map[k] = { key: k }; out.push(map[k]) }
        }
        return out
    }
    function itemsFor(key) {
        return items.filter(i => (i.appName || i.desktopEntry || "—") === key)
    }

    // ---- відносний час ----
    property real now: Date.now()
    Timer { interval: 30000; repeat: true; running: root.items.length > 0; onTriggered: root.now = Date.now() }
    function rel(date) {
        const s = Math.max(0, Math.floor((now - date.getTime()) / 1000))
        if (s < 45) return Lang.t("ui.time.now")
        const m = Math.round(s / 60)
        if (m < 60) return Lang.tn("ui.time.min", m)
        const h = Math.round(m / 60)
        if (h < 24) return Lang.tn("ui.time.hour", h)
        return Lang.tn("ui.time.day", Math.round(h / 24))
    }

    // ---- монітор: де сфокусоване вікно ----
    property string popupMonitor: ""
    property string centerMonitor: ""
    function _focusedMonitor() {
        return MangoService.focusedMonitor
    }
    function isPopupTarget(scr) { return scr.name === (popupMonitor || _focusedMonitor()) }
    function isCenterTarget(scr) { return scr.name === (centerMonitor || _focusedMonitor()) }

    // ---- центр сповіщень ----
    property bool centerOpen: false
    function openCenter() {
        centerMonitor = _focusedMonitor()
        for (let i = 0; i < items.length; i++) items[i].popup = false
        centerOpen = true
    }
    function closeCenter() { centerOpen = false }
    function toggleCenter() { centerOpen ? closeCenter() : openCenter() }

    // ---- сервер ----
    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        actionIconsSupported: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: false
        imageSupported: true
        persistenceSupported: true
        onNotification: n => root._add(n)
    }

    Component { id: itemComp; NotifItem {} }

    function _timeoutFor(it) {
        if (it.expireSec > 0) return it.expireSec * 1000
        if (it.urgency === 2) return 0
        return (it.urgency === 0 ? timeoutLow : timeoutNormal) * 1000
    }

    function _wrap(n) {
        const it = itemComp.createObject(root, { raw: n })
        it.sync()
        it.closedByApp.connect(() => root._remove(it, false))
        it.popupEnded.connect(() => { if (it.transient_) root._remove(it, true) })
        return it
    }

    function _add(n) {
        n.tracked = true
        const it = _wrap(n)
        const allowed = masterPopups && !centerOpen && (!dnd || it.urgency === 2)
        if (allowed) { popupMonitor = _focusedMonitor(); it.arm(_timeoutFor(it)) }
        else if (it.transient_) { it.close(); it.destroy(); return }
        let arr = [it].concat(items)
        while (arr.length > 60) { const old = arr.pop(); old.close(); old.destroy(1500) }
        items = arr
    }

    function _remove(it, notifyApp) {
        if (items.indexOf(it) < 0) return
        items = items.filter(x => x !== it)
        if (notifyApp) it.close()
        it.popup = false
        it.destroy(1500)
    }

    // ---- дії ----
    function dismiss(it) { _remove(it, true) }
    function hidePopup(it) { it.popup = false }
    function activate(it, id) { it.invoke(id); _remove(it, true) }
    function clearAll() {
        const all = items
        items = []
        for (let i = 0; i < all.length; i++) { all[i].close(); all[i].destroy(1500) }
    }
    function clearApp(key) {
        const gone = items.filter(i => (i.appName || i.desktopEntry || "—") === key)
        items = items.filter(i => (i.appName || i.desktopEntry || "—") !== key)
        for (let i = 0; i < gone.length; i++) { gone[i].close(); gone[i].destroy(1500) }
    }

    // після перезавантаження shell — відновлюємо з сервера
    Component.onCompleted: {
        const tracked = server.trackedNotifications.values
        const arr = []
        for (let i = 0; i < tracked.length; i++) arr.unshift(_wrap(tracked[i]))
        items = arr
    }
}
