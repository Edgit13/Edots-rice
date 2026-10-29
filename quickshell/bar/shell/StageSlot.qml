import "root:/theme"
import QtQuick
import QtQuick.Layouts

// StageSlot — слот етапу для пілла: з'являється (ширина + прозорість), коли stage >= minStage;
// порожній (усі модулі всередині сховані) — не займає місця.
Item {
    id: slot

    property int stage: 0
    property int minStage: 0
    property bool vertical: false
    default property alias content: g.data

    readonly property bool open: stage >= minStage
    readonly property bool has: g.visibleChildren.length > 0

    implicitWidth: vertical ? g.implicitWidth : (open && has ? g.implicitWidth : 0)
    implicitHeight: vertical ? (open && has ? g.implicitHeight : 0) : g.implicitHeight
    opacity: open ? 1 : 0
    clip: true
    visible: has && (open || implicitWidth > 0.5 || implicitHeight > 0.5)

    Behavior on implicitWidth  { MotionAnimation { role: slot.open ? "expand" : "collapse" } }
    Behavior on implicitHeight { MotionAnimation { role: slot.open ? "expand" : "collapse" } }
    Behavior on opacity        { MotionAnimation { role: "fade" } }

    GridLayout {
        id: g
        flow: slot.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: slot.vertical ? 1 : 64
        rows: slot.vertical ? 64 : 1
        rowSpacing: Theme.space.sm
        columnSpacing: Theme.space.sm
    }
}
