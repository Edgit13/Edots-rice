pragma ComponentBehavior: Bound
import "root:/"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Material 3 BasicDialog: scrim + surfaceContainerHigh картка (rXL),
// title / supporting text / actions через аліаси. plain-файл.
Rectangle {
    id: dlg
    property bool open: false
    property string title: ""
    property string supporting: ""
    default property alias content: contentCol.children
    property alias actions: actionsRow.children

    anchors.fill: parent
    color: M3.scrim
    opacity: dlg.open ? 0.5 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: M3.durMed } }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 64)
        implicitHeight: col.implicitHeight + M3.s24 * 2
        radius: M3.rXL
        color: M3.surfaceContainerHigh
        scale: dlg.open ? 1.0 : 0.92
        opacity: dlg.open ? 1.0 : 0.0
        Behavior on scale { NumberAnimation { duration: M3.durMed; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: M3.durFast } }

        ColumnLayout {
            id: col
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: M3.s24
            }
            spacing: M3.s16

            Text {
                visible: dlg.title.length > 0
                Layout.fillWidth: true
                text: dlg.title
                color: M3.onSurface
                font: M3.titleLarge
                wrapMode: Text.Wrap
            }
            Text {
                visible: dlg.supporting.length > 0
                Layout.fillWidth: true
                text: dlg.supporting
                color: M3.onSurfaceVariant
                font: M3.bodyMedium
                wrapMode: Text.Wrap
            }
            ColumnLayout {
                id: contentCol
                Layout.fillWidth: true
                spacing: M3.s8
            }
            RowLayout {
                id: actionsRow
                Layout.alignment: Qt.AlignRight
                spacing: M3.s8
            }
        }
    }
}
