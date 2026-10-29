import "root:/theme"
import QtQuick
import QtQuick.Layouts

// WidgetSlot — обгортка віджета: або в авто-кластері (GridLayout), або вільно на екрані (за збереженими x/y).
// У режимі редагування — рамка й перетягування мишею (ручне, без drag.target: працює і для авто-віджетів).
Item {
    id: slot

    required property string kind
    property Item layoutHost
    property Item freeHost
    property real unit: 200
    property real wFactor: 1
    default property alias content: box.data

    readonly property bool free: WidgetsConfig.placementOf(kind) === "free"
    property bool dragging: false
    readonly property real rangeX: Math.max(0, (freeHost ? freeHost.width : 0) - width)
    readonly property real rangeY: Math.max(0, (freeHost ? freeHost.height : 0) - height)

    parent: free ? freeHost : layoutHost
    implicitWidth: unit * wFactor
    implicitHeight: unit
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    z: dragging ? 10 : 0

    // координати вільного віджета: частка від доступного діапазону (завжди лишається на екрані)
    Binding { target: slot; property: "x"; value: WidgetsConfig.fxOf(slot.kind) * slot.rangeX; when: slot.free && !slot.dragging }
    Binding { target: slot; property: "y"; value: WidgetsConfig.fyOf(slot.kind) * slot.rangeY; when: slot.free && !slot.dragging }

    Item { id: box; anchors.fill: parent }

    Rectangle {
        anchors.fill: parent
        visible: WidgetsConfig.editing
        color: slot.dragging ? Theme.alpha(ThemeColors.primary, 0.14) : Theme.alpha(ThemeColors.primary, handle.containsMouse ? 0.08 : 0)
        radius: Math.min(Theme.shape.token("xl"), Math.min(width, height) / 2)
        border.width: 2
        border.color: ThemeColors.primary
        opacity: handle.containsMouse || slot.dragging ? 1 : 0.6
        Behavior on opacity { MotionAnimation { role: "hover" } }
    }

    MouseArea {
        id: handle
        anchors.fill: parent
        enabled: WidgetsConfig.editing
        visible: WidgetsConfig.editing
        hoverEnabled: true
        preventStealing: true
        cursorShape: slot.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real grabX: 0       // зміщення курсора всередині віджета
        property real grabY: 0
        property real startX: 0      // позиція курсора при натисканні (координати freeHost)
        property real startY: 0
        property bool armed: false

        function _clamp(v, max) { return Math.max(0, Math.min(max, v)) }

        onPressed: (m) => {
            if (!slot.freeHost) return
            const p = slot.mapToItem(slot.freeHost, m.x, m.y)
            grabX = m.x; grabY = m.y
            startX = p.x; startY = p.y
            armed = true
        }
        onPositionChanged: (m) => {
            if (!armed || !slot.freeHost) return
            const p = slot.mapToItem(slot.freeHost, m.x, m.y)
            if (!slot.dragging) {
                if (Math.abs(p.x - startX) + Math.abs(p.y - startY) < 4) return
                // початок перетягування: авто-віджет стає вільним на тому ж місці
                const o = slot.mapToItem(slot.freeHost, 0, 0)
                slot.dragging = true
                if (!slot.free) {
                    WidgetsConfig.setFree(slot.kind,
                        slot.rangeX > 0 ? _clamp(o.x / slot.rangeX, 1) : 0,
                        slot.rangeY > 0 ? _clamp(o.y / slot.rangeY, 1) : 0)
                }
                slot.x = _clamp(o.x, slot.rangeX)
                slot.y = _clamp(o.y, slot.rangeY)
                return
            }
            slot.x = _clamp(p.x - grabX, slot.rangeX)
            slot.y = _clamp(p.y - grabY, slot.rangeY)
        }
        onReleased: {
            if (slot.dragging) {
                WidgetsConfig.setFree(slot.kind,
                    slot.rangeX > 0 ? _clamp(slot.x / slot.rangeX, 1) : 0,
                    slot.rangeY > 0 ? _clamp(slot.y / slot.rangeY, 1) : 0)
                slot.dragging = false
            }
            armed = false
        }
        onCanceled: { slot.dragging = false; armed = false }
    }
}
