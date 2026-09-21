import "root:/theme"
import QtQuick
import QtQuick.Layouts

// BarLayout — Leading / Center / Trailing. Один компонент для горизонтального і вертикального
// бару: `vertical` перебудовує осі (без окремих layout'ів під кожну позицію).
//   BarLayout { vertical: false; leading: [ ... ]; center: [ ... ]; trailing: [ ... ] }
//
// Позиції секцій — явні x/y-біндинги, а не умовні якорі: перемикання vertical наживо
// з умовними anchors залишало секції у «старих» координатах.
Item {
    id: root

    property bool vertical: false
    property real spacing: Theme.space.sm
    property alias leading: leadingGrid.data
    property alias center: centerGrid.data
    property alias trailing: trailingGrid.data

    // Leading: початок осі (ліворуч / зверху)
    GridLayout {
        id: leadingGrid
        columns: root.vertical ? 1 : Math.max(1, children.length)
        rowSpacing: root.spacing
        columnSpacing: root.spacing
        x: root.vertical ? (root.width - width) / 2 : 0
        y: root.vertical ? 0 : (root.height - height) / 2
    }

    // Center: справжній центр смуги (не «між» leading і trailing)
    GridLayout {
        id: centerGrid
        columns: root.vertical ? 1 : Math.max(1, children.length)
        rowSpacing: root.spacing
        columnSpacing: root.spacing
        x: (root.width - width) / 2
        y: (root.height - height) / 2
    }

    // Trailing: кінець осі (праворуч / знизу)
    GridLayout {
        id: trailingGrid
        columns: root.vertical ? 1 : Math.max(1, children.length)
        rowSpacing: root.spacing
        columnSpacing: root.spacing
        x: root.vertical ? (root.width - width) / 2 : root.width - width
        y: root.vertical ? root.height - height : (root.height - height) / 2
    }
}
