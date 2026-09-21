import "root:/theme"
import QtQuick
import QtQuick.Layouts

// BarPill — тимчасовий контейнер модуля (Stage 2). У Stage 3 його замінює MorphSurface.
Rectangle {
    id: root

    property string text: ""
    property bool vertical: false
    property bool emphasized: false
    property bool debug: false
    property int cross: Theme.components.islandCompact - Theme.space.sm   // доступна ширина/висота впоперек осі бару
    property var textStyle: vertical ? Theme.type.labelSmall : Theme.type.labelLarge
    default property alias content: extra.data

    readonly property int pad: Theme.space.md

    implicitWidth: vertical ? cross : grid.implicitWidth + pad * 2
    implicitHeight: vertical ? grid.implicitHeight + pad : cross
    radius: Theme.shape.radius("full", Math.min(width, height))
    color: emphasized ? Theme.color.primaryContainer : Theme.color.surfaceContainerHighest
    border.width: debug ? 1 : 0
    border.color: "lime"
    Behavior on color { MotionColorAnimation { role: "stateChange" } }

    GridLayout {
        id: grid
        anchors.centerIn: parent
        columns: root.vertical ? 1 : 2
        rowSpacing: 0
        columnSpacing: Theme.space.sm

        ThemedText {
            visible: root.text.length > 0
            text: root.text
            style: root.textStyle
            horizontalAlignment: Text.AlignHCenter
            color: root.emphasized ? Theme.color.fgPrimaryContainer : Theme.color.fgSurface
        }
        Item { id: extra; visible: children.length > 0; implicitWidth: childrenRect.width; implicitHeight: childrenRect.height }
    }
}
