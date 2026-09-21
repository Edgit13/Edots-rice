pragma Singleton
import "root:/theme"
import QtQuick
import Quickshell

// ThemeShapes — corner scale + ролі компонентів. Corner Style: material | expressive | rounded.
// radius(name, h) обмежує радіус висотою (h/2), щоб не було артефактів.
Singleton {
    id: root

    readonly property string style: ThemeSettings.cornerStyle
    readonly property real k: ThemeSettings.uiScale
    readonly property real full: 9999

    readonly property var _tables: ({
        material:   { none: 0, xs: 4, sm: 8,  md: 12, lg: 16, xl: 28, xxl: 48 },
        expressive: { none: 0, xs: 4, sm: 8,  md: 16, lg: 24, xl: 36, xxl: 56 },
        rounded:    { none: 0, xs: 8, sm: 14, md: 20, lg: 28, xl: 40, xxl: 64 }
    })

    function token(name) {
        if (name === "full") return full
        const t = _tables[style] || _tables.material
        return t[name] !== undefined ? Math.round(t[name] * k) : 0
    }
    function radius(name, h) {
        const r = token(name)
        return h > 0 ? Math.min(r, h / 2) : r
    }

    // scale
    readonly property real none: 0
    readonly property real xs: token("xs")
    readonly property real sm: token("sm")
    readonly property real md: token("md")
    readonly property real lg: token("lg")
    readonly property real xl: token("xl")
    readonly property real xxl: token("xxl")

    // ролі (M3E: різні форми для різних компонентів; pressed — морф у менший радіус)
    readonly property real button: full
    readonly property real buttonPressed: token("md")
    readonly property real iconButton: full
    readonly property real iconButtonPressed: token("md")
    readonly property real chip: token("sm")
    readonly property real field: token("xs")
    readonly property real card: token("md")
    readonly property real cardLarge: token("lg")
    readonly property real menu: token("md")
    readonly property real tooltip: token("xs")
    readonly property real dialog: token("xl")
    readonly property real sheet: token("xxl")
    readonly property real listItem: token("md")
    readonly property real listEdge: token("lg")     // перший/останній елемент згрупованого списку
    readonly property real listInner: token("xs")    // внутрішні елементи (connected list)
    readonly property real navItem: full
    readonly property real slider: full
    readonly property real switchShape: full
    readonly property real badge: full

    // bar / morph-поверхні: pill → expanded → dialog
    readonly property real island: full
    readonly property real islandExpanded: token("xl")
    readonly property real islandDialog: token("xxl")
}
