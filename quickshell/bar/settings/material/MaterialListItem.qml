pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Layouts

// M3 ListItem: icon / headline / supporting / trailing.
Rectangle {
    id: li

    property string icon: ""
    property string headline: ""
    property string supporting: ""
    property bool enabled_: true
    default property alias trailing: tr.children

    Layout.fillWidth: true
    implicitHeight: Math.max(supporting.length > 0 ? Theme.components.listItemTwo : Theme.components.listItemOne,
                             row.implicitHeight + Theme.space.md * 2)
    radius: Theme.shape.listItem
    color: "transparent"
    opacity: li.enabled_ ? 1 : Theme.components.disabledContent

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Theme.color.fgSurface
        opacity: ma.pressed ? Theme.components.statePressed
               : ma.containsMouse && li.enabled_ ? Theme.components.stateHover : 0
        Behavior on opacity { MotionAnimation { role: "hover" } }
    }

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: Theme.space.lg
            rightMargin: Theme.space.lg
        }
        spacing: Theme.space.lg

        Text {
            visible: li.icon.length > 0
            text: li.icon
            color: Theme.color.fgSurfaceVariant
            font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            ThemedText {
                Layout.fillWidth: true
                text: li.headline
                style: Theme.type.bodyLarge
                elide: Text.ElideRight
            }
            ThemedText {
                visible: li.supporting.length > 0
                Layout.fillWidth: true
                text: li.supporting
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
                elide: Text.ElideRight
            }
        }
        RowLayout {
            id: tr
            spacing: Theme.space.xs
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: li.enabled_
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
