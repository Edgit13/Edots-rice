import "root:/theme"
import QtQuick

// MorphSurface — одна поверхня, що плавно морфиться між станами без візуальних «стрибків»:
//
//   closed ⇄ compact (pill) ⇄ [hover-pill] ⇄ expanded (surface) ⇄ dialog
//
// Анімуються: width, height, radius, position, opacity, scale, elevation, колір (state layer)
// та контент (crossfade зі зсувом у часі: fade-in — після росту, fade-out — до згортання).
// Root резервує в layout лише compact-розмір; тіло виростає поверх сусідів (origin* задають, яка
// точка лишається на місці: 0 / 0.5 / 1).
//
//   MorphSurface {
//       compact:  [ ThemedText { text: "12:42" } ]
//       expanded: [ ... ]                       // контент фіксованого розміру (див. expandedWidth)
//       onClicked: surfaceState = "expanded"
//   }
Item {
    id: root

    // ---------- API ----------
    property string surfaceState: "compact"      // closed | compact | expanded | dialog
    property real originX: 0.5                   // 0 = ріст праворуч, 0.5 = від центру, 1 = ліворуч
    property real originY: 0.5                   // 0 = ріст вниз, 0.5 = від центру, 1 = вгору
    property Item dialogParent: null             // у стані dialog поверхня центрується в цьому Item
    property bool closeOnEscape: true

    // розміри (0 = авто за вмістом слота + padding)
    property real compactWidth: 0
    property real compactHeight: 0
    property real hoverWidth: 0                  // > 0 вмикає hover-pill (compact → трохи ширший)
    property real hoverHeight: 0
    property real expandedWidth: 0
    property real expandedHeight: 0
    property real dialogWidth: 0
    property real dialogHeight: 0
    property real padding: Theme.space.md
    property real dialogPadding: Theme.space.xl

    // контент (кожен слот: дочірні Item фіксованого розміру, що не залежать від anchors.fill,
    // якщо відповідний розмір авто)
    property alias compact: compactSlot.data
    property alias hover: hoverSlot.data
    property alias expanded: expandedSlot.data
    property alias dialog: dialogSlot.data

    // колір тіла за станом; можна перевизначити
    property color baseColor: (_st === "dialog") ? Theme.color.surfaceContainerHighest : Theme.color.surfaceContainerHigh

    // стани взаємодії (readonly)
    readonly property bool hovered: hh.hovered
    readonly property bool pressed: th.pressed
    readonly property bool focused: activeFocus
    readonly property real scrimOpacity: _scrim       // для хоста: Rectangle { color: scrim; opacity: surface.scrimOpacity }
    readonly property Item bodyItem: body            // для хоста: mask: Region { item: surface.bodyItem }
    readonly property bool busy: Math.abs(body.width - _tw) > 0.5 || Math.abs(body.height - _th) > 0.5

    signal clicked()

    function open()       { surfaceState = "expanded" }
    function openDialog() { surfaceState = "dialog" }
    function collapse()   { surfaceState = "compact" }
    function hide()       { surfaceState = "closed" }
    function toggle()     { surfaceState = (surfaceState === "expanded") ? "compact" : "expanded" }

    // ---------- внутрішній стан ----------
    // Напрям руху (_closing) виставляється ДО зміни _st/_hov — Behavior тоді бере правильну роль.
    property string _st: "compact"
    property bool _hov: false
    property bool _closing: false
    property int _rank: 1
    property real _dx: 0
    property real _dy: 0
    Behavior on _dx { MotionAnimation { role: root._sizeRole } }
    Behavior on _dy { MotionAnimation { role: root._sizeRole } }

    function _rankOf(s) { return s === "closed" ? 0 : s === "compact" ? 1 : s === "expanded" ? 2 : 3 }

    onSurfaceStateChanged: {
        const r = _rankOf(surfaceState)
        _closing = r < _rank
        _rank = r
        _st = surfaceState
        _hov = _st === "compact" && hovered
        if (_st === "dialog") _centerDialog(); else { _dx = 0; _dy = 0 }
        if (_st === "dialog" || _st === "expanded") forceActiveFocus()
    }
    onHoveredChanged: {
        _closing = !hovered
        _hov = _st === "compact" && hovered
    }
    Component.onCompleted: { _rank = _rankOf(surfaceState); _st = surfaceState }

    // авто-розміри
    readonly property real _cw: compactWidth > 0 ? compactWidth : compactSlot.childrenRect.width + padding * 2
    readonly property real _ch: compactHeight > 0 ? compactHeight
                                : Math.max(Theme.components.islandCompact, compactSlot.childrenRect.height + Theme.space.sm * 2)
    readonly property real _hw: hoverWidth > 0 ? hoverWidth : _cw
    readonly property real _hh: hoverHeight > 0 ? hoverHeight : _ch
    readonly property real _ew: expandedWidth > 0 ? expandedWidth : Math.max(_cw, expandedSlot.childrenRect.width + padding * 2)
    readonly property real _eh: expandedHeight > 0 ? expandedHeight : Math.max(_ch, expandedSlot.childrenRect.height + padding * 2)
    readonly property real _dw: dialogWidth > 0 ? dialogWidth
                                : Math.max(Theme.components.dialogMinW, dialogSlot.childrenRect.width + dialogPadding * 2)
    readonly property real _dh: dialogHeight > 0 ? dialogHeight : Math.max(_eh, dialogSlot.childrenRect.height + dialogPadding * 2)

    readonly property bool _hoverPill: _st === "compact" && _hov && hoverWidth > 0

    // цільова геометрія тіла
    readonly property real _tw: _st === "closed" ? _cw * 0.6
                              : _st === "compact" ? (_hoverPill ? _hw : _cw)
                              : _st === "expanded" ? _ew : _dw
    readonly property real _th: _st === "closed" ? _ch * 0.6
                              : _st === "compact" ? (_hoverPill ? _hh : _ch)
                              : _st === "expanded" ? _eh : _dh
    readonly property real _radius: {
        const cap = Math.min(_tw, _th) / 2
        const r = (_st === "expanded") ? Theme.shape.islandExpanded
                : (_st === "dialog") ? Theme.shape.islandDialog
                : Theme.shape.island
        return Math.min(r, cap)
    }
    readonly property real _elevation: _st === "closed" ? 0 : _st === "compact" ? 1 : _st === "expanded" ? 3 : 5
    readonly property real _opacity: _st === "closed" ? 0 : 1
    readonly property real _scale: (th.pressed && _st !== "dialog") ? 0.97 : (_st === "closed" ? 0.9 : 1)
    readonly property real _scrim: _st === "dialog" ? Theme.color.scrimOpacity : 0
    readonly property string _sizeRole: _closing ? "collapse" : "expand"

    function _centerDialog() {
        if (!dialogParent) { _dx = 0; _dy = 0; return }
        const base = { x: (width - _dw) * originX, y: (height - _dh) * originY }
        const want = root.mapFromItem(dialogParent, (dialogParent.width - _dw) / 2, (dialogParent.height - _dh) / 2)
        _dx = want.x - base.x
        _dy = want.y - base.y
    }
    Connections {
        target: root.dialogParent
        function onWidthChanged()  { if (root._st === "dialog") root._centerDialog() }
        function onHeightChanged() { if (root._st === "dialog") root._centerDialog() }
    }

    implicitWidth: _cw
    implicitHeight: _ch
    z: (_st === "expanded" || _st === "dialog" || _hoverPill) ? 1000 : 0
    activeFocusOnTab: true

    Keys.onEscapePressed: function (e) {
        if (closeOnEscape && (_st === "expanded" || _st === "dialog")) { collapse(); e.accepted = true }
    }
    Keys.onPressed: function (e) {
        if ((e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) && _st === "compact") {
            root.clicked(); e.accepted = true
        }
    }

    // ---------- тіло ----------
    Item {
        id: body
        width: root._tw
        height: root._th
        x: (root.width - width) * root.originX + root._dx
        y: (root.height - height) * root.originY + root._dy
        opacity: root._opacity
        scale: root._scale
        transformOrigin: Item.Center
        enabled: root._st !== "closed"

        Behavior on width   { MotionAnimation { role: root._sizeRole } }
        Behavior on height  { MotionAnimation { role: root._sizeRole } }
        Behavior on opacity { MotionAnimation { role: root._st === "closed" ? "exit" : "enter" } }
        Behavior on scale   { MotionAnimation { role: "press" } }

        property real bodyRadius: root._radius
        property real bodyElevation: root._elevation
        property color bodyColor: root.pressed ? Theme.stateLayer(root.baseColor, Theme.color.fgSurface, Theme.components.statePressed)
                                  : root.hovered ? Theme.stateLayer(root.baseColor, Theme.color.fgSurface, Theme.components.stateHover)
                                  : root.baseColor
        Behavior on bodyRadius    { MotionAnimation { role: root._sizeRole } }
        Behavior on bodyElevation { MotionAnimation { role: root._sizeRole } }
        Behavior on bodyColor     { MotionColorAnimation { role: "hover" } }

        ElevationShadow {
            anchors.fill: parent
            level: body.bodyElevation
            radius: body.bodyRadius
            color: body.bodyColor
        }

        MorphSlot {
            id: compactSlot
            host: body
            shown: (root._st === "compact" && !root._hoverPill) || root._st === "closed"
            slotWidth: root._cw - root.padding * 2
            slotHeight: root._ch - Theme.space.sm * 2
        }
        MorphSlot {
            id: hoverSlot
            host: body
            shown: root._hoverPill
            slotWidth: root._hw - root.padding * 2
            slotHeight: root._hh - Theme.space.sm * 2
        }
        MorphSlot {
            id: expandedSlot
            host: body
            shown: root._st === "expanded"
            slotWidth: root._ew - root.padding * 2
            slotHeight: root._eh - root.padding * 2
        }
        MorphSlot {
            id: dialogSlot
            host: body
            shown: root._st === "dialog"
            slotWidth: root._dw - root.dialogPadding * 2
            slotHeight: root._dh - root.dialogPadding * 2
        }

        // Handlers у body: hit-area = поточна (анімована) форма, тож hover-pill не «відпускає» курсор.
        // Діти (кнопки в контенті) мають пріоритет, тап по порожньому місцю → clicked()
        HoverHandler { id: hh; enabled: root._st !== "closed" }
        // clicked() лише якщо стан не змінився між press і release (кнопка в контенті могла його змінити)
        TapHandler {
            id: th
            property string pressState: ""
            enabled: root._st !== "closed"
            onPressedChanged: if (pressed) pressState = root._st
            onTapped: if (root._st === pressState) root.clicked()
        }

        // focus ring (клавіатурна навігація)
        Rectangle {
            anchors.fill: parent
            anchors.margins: -Theme.components.focusRingOffset
            radius: body.bodyRadius + Theme.components.focusRingOffset
            color: "transparent"
            border.width: Theme.components.focusRingWidth
            border.color: Theme.color.primary
            visible: root.activeFocus
        }
    }
}
