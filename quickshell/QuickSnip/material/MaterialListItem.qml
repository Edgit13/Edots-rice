pragma ComponentBehavior: Bound
import "root:/"
import QtQuick
import QtQuick.Layouts

// Material 3 ListItem: icon/headline/supporting/trailing.
Rectangle {
    id: li
    property string icon: ""
    property string headline: ""
    property string supporting: ""
    property bool enabled_: true
    default property alias trailing: tr.children

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + M3.s16
    radius: M3.rM
    color: ma.containsMouse && li.enabled_ ? M3.hoverOf(M3.surfaceContainerHigh) : "transparent"
    opacity: li.enabled_ ? 1.0 : M3.disabledOpacity

    RowLayout {
        id: row
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: M3.s12
            rightMargin: M3.s12
        }
        spacing: M3.s12

        Text {
            visible: li.icon.length > 0
            text: li.icon
            color: M3.onSurfaceVariant
            font { family: "Material Symbols Rounded"; pixelSize: 20 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: li.headline
                color: M3.onSurface
                font: M3.bodyLarge
                elide: Text.ElideRight
            }
            Text {
                visible: li.supporting.length > 0
                Layout.fillWidth: true
                text: li.supporting
                color: M3.onSurfaceVariant
                font: M3.bodySmall
                elide: Text.ElideRight
            }
        }
        RowLayout {
            id: tr
            spacing: M3.s4
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
