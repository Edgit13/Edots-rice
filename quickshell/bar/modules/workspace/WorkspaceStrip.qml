import "root:/theme"
import "root:/services"
import QtQuick

// WorkspaceStrip — M3 Expressive теги (MangoWM), у дусі end-4:
//  • сусідні зайняті теги зливаються в одну «connected» групу
//  • активний тег — primary-індикатор, що еластично розтягується
//    і має ту саму форму, що й фон групи (заокруглений лише зовні)
//  • порожній тег — крапка (при hover перетворюється на номер)
Item {
    id: root

    property string monitor: ""
    property bool vertical: false
    property real itemSize: 24

    readonly property int count: MangoService.tagCount(monitor)
    readonly property int activeIdx: MangoService.activeIndex(monitor)
    readonly property real cell: itemSize
    readonly property real gap: Theme.space.xxs

    implicitWidth: vertical ? cell : cell * count
    implicitHeight: vertical ? cell * count : cell

    function filled(i) {
        if (i < 1 || i > count) return false
        const t = MangoService.tag(monitor, i)
        return t.occupied || t.urgent || t.active
    }

    property real indStart: 0
    property real indEnd: 0
    property bool forward: true
    property bool animate: false
    property bool hadActive: false

    function snap() {
        animate = false
        indStart = (activeIdx - 1) * cell
        indEnd = activeIdx * cell
        hadActive = activeIdx > 0
        animate = true
    }
    onActiveIdxChanged: {
        if (activeIdx <= 0) return
        if (!hadActive) { snap(); return }
        const e = activeIdx * cell
        forward = e > indEnd
        indStart = (activeIdx - 1) * cell
        indEnd = e
    }
    onCellChanged: snap()
    Component.onCompleted: snap()

    Behavior on indStart { enabled: root.animate; MotionAnimation { role: root.forward ? "morph" : "move" } }
    Behavior on indEnd   { enabled: root.animate; MotionAnimation { role: root.forward ? "move" : "morph" } }

    // ---- шар 1: фон зайнятих тегів (connected group) ----
    Repeater {
        model: root.count
        Rectangle {
            id: bg
            required property int index
            readonly property int n: index + 1
            readonly property bool isOn: root.filled(n)
            readonly property bool hasPrev: root.filled(n - 1)
            readonly property bool hasNext: root.filled(n + 1)
            readonly property real big: Math.min(width, height) / 2
            readonly property real small: Theme.shape.xs
            readonly property real rStart: hasPrev ? small : big
            readonly property real rEnd: hasNext ? small : big

            x: root.vertical ? root.gap / 2 : index * root.cell + root.gap / 2
            y: root.vertical ? index * root.cell + root.gap / 2 : root.gap / 2
            width: root.cell - root.gap
            height: root.cell - root.gap
            color: Theme.color.secondaryContainer
            opacity: isOn ? 1 : 0
            visible: opacity > 0.01

            topLeftRadius: rStart
            bottomLeftRadius: root.vertical ? rEnd : rStart
            topRightRadius: root.vertical ? rStart : rEnd
            bottomRightRadius: rEnd

            Behavior on opacity { MotionAnimation { role: "stateChange" } }
            Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
            Behavior on topRightRadius { MotionAnimation { role: "morph" } }
            Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
            Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }
        }
    }

    // ---- шар 2: індикатор активного тега (та сама форма, що й фон) ----
    Rectangle {
        id: indicator
        visible: root.activeIdx > 0
        color: Theme.color.primary

        readonly property int a: root.activeIdx
        readonly property bool hasPrev: root.filled(a - 1)
        readonly property bool hasNext: root.filled(a + 1)
        readonly property real big: Math.min(width, height) / 2
        readonly property real small: Theme.shape.xs
        readonly property real rStart: hasPrev ? small : big
        readonly property real rEnd: hasNext ? small : big

        readonly property real len: Math.max(0, root.indEnd - root.indStart - root.gap)
        x: root.vertical ? root.gap / 2 : root.indStart + root.gap / 2
        y: root.vertical ? root.indStart + root.gap / 2 : root.gap / 2
        width: root.vertical ? root.cell - root.gap : len
        height: root.vertical ? len : root.cell - root.gap

        topLeftRadius:    rStart
        topRightRadius:   root.vertical ? rStart : rEnd
        bottomLeftRadius: root.vertical ? rEnd   : rStart
        bottomRightRadius: rEnd

        Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
        Behavior on topRightRadius { MotionAnimation { role: "morph" } }
        Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
        Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }
    }

    // ---- шар 3: підписи, hover, натискання ----
    Repeater {
        model: root.count
        Item {
            id: lab
            required property int index
            readonly property int n: index + 1
            readonly property var t: MangoService.tag(root.monitor, n)
            readonly property bool isActive: t.active
            readonly property bool urgent: t.urgent
            readonly property bool occupied: t.occupied
            readonly property bool isFilled: isActive || urgent || occupied
            readonly property bool hovered: ma.containsMouse

            x: root.vertical ? 0 : index * root.cell
            y: root.vertical ? index * root.cell : 0
            width: root.cell
            height: root.cell
            scale: ma.pressed ? 0.88 : 1
            Behavior on scale { MotionAnimation { role: "press" } }

            Rectangle {
                anchors.centerIn: parent
                width: root.cell - root.gap * 3
                height: width
                radius: width / 2
                color: Theme.color.errorContainer
                opacity: lab.urgent && !lab.isActive ? 1 : 0
                Behavior on opacity { MotionAnimation { role: "stateChange" } }
            }
            Rectangle {
                anchors.centerIn: parent
                width: root.cell - root.gap * 2
                height: width
                radius: width / 2
                color: Theme.color.fgSurface
                opacity: lab.hovered && !lab.isFilled ? Theme.components.stateHover : 0
                Behavior on opacity { MotionAnimation { role: "hover" } }
            }
            Rectangle {
                anchors.centerIn: parent
                width: Math.max(4, root.cell * 0.2)
                height: width
                radius: width / 2
                color: Theme.color.outline
                opacity: (!lab.isFilled && !lab.hovered) ? 0.7 : 0
                Behavior on opacity { MotionAnimation { role: "hover" } }
            }
            ThemedText {
                anchors.centerIn: parent
                text: lab.n
                style: Theme.type.labelMedium
                emphasized: lab.isActive
                opacity: (lab.isFilled || lab.hovered) ? 1 : 0
                color: lab.isActive ? Theme.color.fgPrimary
                     : lab.urgent ? Theme.color.fgErrorContainer
                     : lab.occupied ? Theme.color.fgSecondaryContainer
                     : Theme.color.fgSurfaceVariant
                Behavior on opacity { MotionAnimation { role: "hover" } }
                Behavior on color { MotionColorAnimation { role: "stateChange" } }
            }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: MangoService.switchTag(root.monitor, lab.n)
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function (e) { MangoService.stepTag(root.monitor, e.angleDelta.y > 0 ? -1 : 1) }
    }
}
