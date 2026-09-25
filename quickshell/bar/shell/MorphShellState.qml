import QtQuick

// MorphShellState — стан ОДНІЄЇ shell-поверхні (годинник + модулі бару + активний модуль).
// НЕ singleton: кожен BarWindow створює свій екземпляр (п.18 — власний shell instance на
// монітор, спільні лише сервіси). Ієрархія станів:
//
//   idle ──hover──► peek ──click(module)──► module ──click(inside)──► dialog
//   idle ◄─leave───┘      ◄──Esc/outside──┘        ◄──Esc/outside───┘
//
// "peek" — компактний ряд глімпсів (годинник + іконки), "module" — повна панель модуля
// (Wi-Fi, Volume...), "dialog" — великий стан (Launcher, Settings). Esc/клік-поза-межами
// завжди йдуть на ОДИН крок назад (back-stack), а не одразу в idle.
Item {
    id: root

    readonly property string idle: "idle"
    readonly property string peek: "peek"
    readonly property string module: "module"
    readonly property string dialog: "dialog"

    property string state: idle
    property string activeModule: ""
    property var _stack: []   // [{state, activeModule}, ...]

    property int hoverCollapseDelay: 350   // мс; п.9 — configurable close delay

    readonly property bool hovered: _hoverCount > 0
    property int _hoverCount: 0

    function _push() { _stack.push({ state: state, activeModule: activeModule }) }

    // Наведення миші на shell (compact pill або будь-яку частину поверхні)
    function hoverEnter() {
        _hoverCount += 1
        collapseTimer.stop()
        if (state === idle) state = peek
    }
    function hoverExit() {
        _hoverCount = Math.max(0, _hoverCount - 1)
        if (_hoverCount === 0 && state === peek) collapseTimer.restart()
    }
    Timer {
        id: collapseTimer
        interval: root.hoverCollapseDelay
        onTriggered: if (!root.hovered && root.state === root.peek) root.state = root.idle
    }

    // Відкрити модуль (Wi-Fi, Volume...) — з idle або peek
    function openModule(key) {
        if (state !== module || activeModule !== key) _push()
        state = module
        activeModule = key
    }
    // Відкрити великий стан (Launcher, Settings) — з будь-якого стану
    function openDialog(key) {
        _push()
        state = dialog
        activeModule = key
    }
    function toggleModule(key) {
        if (state === module && activeModule === key) back()
        else openModule(key)
    }
    function toggleDialog(key) {
        if (state === dialog && activeModule === key) back()
        else openDialog(key)
    }

    // Клік по compact pill (не hover) — той самий ефект, що hoverEnter, але без лічильника:
    // фолбек для touch/без-hover пристроїв.
    function reveal() { if (state === idle) state = peek }

    // Esc / клік поза межами — на один крок назад, а не одразу idle
    function back() {
        if (_stack.length > 0) {
            const prev = _stack.pop()
            state = prev.state
            activeModule = prev.activeModule
        } else {
            state = idle
            activeModule = ""
        }
    }
    // Повне закриття (напр. клік по тій самій пігулці, що вже відкрита) — скидає стек одразу
    function collapse() {
        _stack = []
        state = idle
        activeModule = ""
    }
}
