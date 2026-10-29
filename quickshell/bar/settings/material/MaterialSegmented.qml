pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Layouts

// M3 Expressive Connected Button Group: options=[{icon,label}], selectedIndex.
// Вибраний елемент — повна пігулка (primary), решта — заокруглені лише зовнішні краї.
Item {
    id: seg

    property var options: []
    property int selectedIndex: 0
    signal selected(int index)

    Layout.fillWidth: true
    implicitHeight: Theme.components.buttonS

    RowLayout {
        anchors.fill: parent
        spacing: Theme.space.listGap

        Repeater {
            model: seg.options
            Rectangle {
                id: cell
                required property var modelData
                required property int index
                readonly property bool sel: seg.selectedIndex === index
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === seg.options.length - 1
                readonly property real big: height / 2
                readonly property real small: Theme.shape.xs
                readonly property color fg: sel ? Theme.color.fgPrimary : Theme.color.fgSurfaceVariant

                Layout.fillWidth: true
                Layout.fillHeight: true
                color: sel ? Theme.color.primary : (Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainerHighest)
                border.width: Theme.settings.nothing && !sel ? 1 : 0
                border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.22)

                topLeftRadius: (sel || isFirst) ? big : small
                bottomLeftRadius: (sel || isFirst) ? big : small
                topRightRadius: (sel || isLast) ? big : small
                bottomRightRadius: (sel || isLast) ? big : small

                Behavior on color { MotionColorAnimation { role: "stateChange" } }
                Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
                Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
                Behavior on topRightRadius { MotionAnimation { role: "morph" } }
                Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }

                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: parent.topLeftRadius
                    bottomLeftRadius: parent.bottomLeftRadius
                    topRightRadius: parent.topRightRadius
                    bottomRightRadius: parent.bottomRightRadius
                    color: cell.fg
                    opacity: ma.pressed ? Theme.components.statePressed
                           : ma.containsMouse ? Theme.components.stateHover : 0
                    Behavior on opacity { MotionAnimation { role: "hover" } }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Theme.space.xs
                    Text {
                        visible: cell.modelData.icon !== undefined && cell.modelData.icon.length > 0
                        text: cell.modelData.icon || ""
                        color: cell.fg
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                    }
                    ThemedText {
                        text: cell.modelData.label || String(cell.modelData)
                        style: Theme.type.labelLarge
                        color: cell.fg
                    }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        seg.selectedIndex = cell.index
                        seg.selected(cell.index)
                    }
                }
            }
        }
    }
}
