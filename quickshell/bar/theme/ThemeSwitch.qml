pragma Singleton
import "root:/settings"
import "root:/states"
import "root:/theme"
import QtQuick
import Quickshell

// ThemeSwitch — диригент анімації перемикання теми (design Material↔Nothing, dark↔light).
//
// Стилі (theme.transition): off | fade | dots | scan
//   fade — плавне перетікання всіх кольорів (ThemeColors)
//   dots — точкова хвиля від верху екрана: стара тема "розсипається" точками й відкриває нову
//   scan — те саме, але лінією-сканером зверху вниз
//
// Потік для dots/scan:  request(fn) → begin (оверлей покриває екран кольором старої теми)
//   → через ~90 мс fn() (справжнє перемикання, сховане під покриттям) → applied → оверлей відкриває нову тему.
// Без анімацій / reduce motion / ігровий режим / запуск shell → fn() викликається одразу.
Singleton {
    id: root

    readonly property string style: Settings.get("theme", "transition") || "dots"
    readonly property bool overlayStyle: style === "dots" || style === "scan"
    readonly property bool motionOk: ThemeMotion.enabled && !ThemeMotion.reduced

    property bool armed: false          // false перші секунди після старту — без анімацій
    property bool busy: false           // оверлей зараз на екрані
    property var _pending: null

    signal begin(string cover, string style)
    signal applied()

    Timer { interval: 2500; running: true; onTriggered: root.armed = true }
    Timer { id: guard; interval: 4000; running: root.busy; onTriggered: root.busy = false }   // страховка

    Timer {
        id: applyTimer
        interval: 90
        onTriggered: {
            const f = root._pending
            root._pending = null
            if (f) f()
            root.applied()
        }
    }

    // fn — функція, що реально перемикає тему
    function request(fn) {
        if (!armed || !overlayStyle || !motionOk || GameModeState.active || busy) { fn(); return }
        _pending = fn
        busy = true
        begin(String(ThemeColors.scheme.background), style)
        applyTimer.restart()
    }

    // тривалість плавної зміни кольорів (мс); 0 = миттєво
    function fadeDuration() {
        if (!armed || style === "off" || !motionOk || busy) return 0
        return ThemeMotion.scaled(style === "fade" ? 520 : 260, false)
    }
}
