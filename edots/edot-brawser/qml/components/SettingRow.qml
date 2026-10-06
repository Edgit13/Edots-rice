import QtQuick
import QtQuick.Layouts

// Рядок налаштування: заголовок + опис ліворуч, елемент керування праворуч
Item {
    id: root
    readonly property var c: theme.c
    property string title: ""
    property string desc: ""
    property bool divider: true
    default property alias control: holder.data

    Layout.fillWidth: true
    implicitHeight: Math.max(64, textCol.implicitHeight + 24)

    RowLayout {
        anchors { fill: parent; leftMargin: 20; rightMargin: 20 }
        spacing: 16

        ColumnLayout {
            id: textCol
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            Text {
                Layout.fillWidth: true
                text: root.title
                color: c.on_surface
                font.pixelSize: 16
                wrapMode: Text.WordWrap
            }
            Text {
                Layout.fillWidth: true
                visible: root.desc !== ""
                text: root.desc
                color: c.on_surface_variant
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }
        }
        Item {
            id: holder
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
    Rectangle {
        visible: root.divider
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 20; rightMargin: 20 }
        height: 1
        color: c.outline_variant
    }
}
