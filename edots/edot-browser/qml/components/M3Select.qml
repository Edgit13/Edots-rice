import QtQuick
import QtQuick.Controls

// Outlined select з випадним меню. model: [{value, label}]
Item {
    id: root
    readonly property var c: theme.c
    property var model: []
    property var currentValue
    signal activated(var value)

    implicitWidth: 220
    implicitHeight: 40

    readonly property string currentLabel: {
        for (var i = 0; i < model.length; ++i)
            if (model[i].value === currentValue) return model[i].label
        return ""
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "transparent"
        border.width: popup.visible ? 2 : 1
        border.color: popup.visible ? c.primary : (ma.containsMouse ? c.on_surface : c.outline)
    }
    Text {
        anchors { left: parent.left; leftMargin: 12; right: arrow.left; rightMargin: 4; verticalCenter: parent.verticalCenter }
        text: root.currentLabel
        color: c.on_surface
        font.pixelSize: 14
        elide: Text.ElideRight
    }
    Icon {
        id: arrow
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        name: "arrow_drop_down"
        size: 24
        color: c.on_surface_variant
        rotation: popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: theme.animations ? 150 : 0 } }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible ? popup.close() : popup.open()
    }

    Popup {
        id: popup
        y: root.height + 4
        width: root.width
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            radius: 12
            color: c.surface_container
            border.width: 1
            border.color: c.outline_variant
        }
        contentItem: Column {
            spacing: 0
            Repeater {
                model: root.model
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool selected: modelData.value === root.currentValue
                    width: popup.availableWidth
                    height: 40
                    radius: 8
                    color: selected ? theme.alpha(c.primary, 0.12) : "transparent"
                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: c.on_surface
                        opacity: itemMa.containsMouse ? 0.08 : 0
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        text: modelData.label
                        color: selected ? c.primary : c.on_surface
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: itemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.activated(modelData.value); popup.close() }
                    }
                }
            }
        }
    }
}
