pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Layouts

// M3 Expressive BasicDialog: scrim + картка (shape.dialog) зі scale-морфом.
// Scrim і картка — окремі елементи (раніше картка успадковувала 50% opacity від scrim).
Item {
    id: dlg

    property bool open: false
    property string title: ""
    property string supporting: ""
    default property alias content: contentCol.children
    property alias actions: actionsRow.children

    anchors.fill: parent
    visible: scrim.opacity > 0.01

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Theme.color.scrim
        opacity: dlg.open ? 0.5 : 0
        Behavior on opacity { MotionAnimation { role: "fade" } }
        MouseArea { anchors.fill: parent; enabled: dlg.open }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(Theme.components.dialogMaxW, dlg.width - Theme.space.xxl * 2)
        implicitHeight: col.implicitHeight + Theme.space.xl * 2
        radius: Theme.shape.dialog
        color: Theme.color.surfaceContainerHigh
        border.width: Theme.settings.nothing ? 1 : 0
        border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.22)
        scale: dlg.open ? 1 : 0.9
        opacity: dlg.open ? 1 : 0
        Behavior on scale { MotionAnimation { role: "expand" } }
        Behavior on opacity { MotionAnimation { role: "fade" } }

        ColumnLayout {
            id: col
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Theme.space.xl
            }
            spacing: Theme.space.lg

            ThemedText {
                visible: dlg.title.length > 0
                Layout.fillWidth: true
                text: Theme.settings.nothing ? dlg.title.toUpperCase() : dlg.title
                style: Theme.settings.nothing ? Theme.type.titleSmall : Theme.type.headlineSmall
                font.letterSpacing: Theme.settings.nothing ? 2 : style.tracking
                wrapMode: Text.Wrap
            }
            ThemedText {
                visible: dlg.supporting.length > 0
                Layout.fillWidth: true
                text: dlg.supporting
                style: Theme.type.bodyMedium
                color: Theme.color.fgSurfaceVariant
                wrapMode: Text.Wrap
            }
            ColumnLayout {
                id: contentCol
                Layout.fillWidth: true
                spacing: Theme.space.sm
            }
            RowLayout {
                id: actionsRow
                Layout.alignment: Qt.AlignRight
                spacing: Theme.space.sm
            }
        }
    }
}
