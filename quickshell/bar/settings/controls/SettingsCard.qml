pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: c
    property string title: ""
    default property alias content: body.data

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + M3.s24 * 2
    radius: M3.rL
    color: M3.surfaceContainer

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: M3.s16
        }
        spacing: M3.s12

        Text {
            visible: c.title.length > 0
            Layout.fillWidth: true
            text: c.title
            color: M3.m3OnSurfaceVariant
            font: M3.labelLarge
        }

        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: M3.s8
        }
    }
}
