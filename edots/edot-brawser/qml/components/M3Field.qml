import QtQuick

// Outlined text field (M3)
Item {
    id: root
    readonly property var c: theme.c
    property alias text: input.text
    property string placeholder: ""
    property alias inputFocus: input.activeFocus
    signal accepted()
    signal editingFinished()

    implicitWidth: 280
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "transparent"
        border.width: input.activeFocus ? 2 : 1
        border.color: input.activeFocus ? c.primary : (hh.hovered ? c.on_surface : c.outline)
    }
    TextInput {
        id: input
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        verticalAlignment: TextInput.AlignVCenter
        color: c.on_surface
        font.pixelSize: 14
        clip: true
        selectByMouse: true
        selectionColor: c.primary_container
        selectedTextColor: c.on_primary_container
        onAccepted: root.accepted()
        onEditingFinished: root.editingFinished()
    }
    Text {
        visible: input.text.length === 0 && !input.activeFocus
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: root.placeholder
        color: c.on_surface_variant
        font.pixelSize: 14
    }
    HoverHandler { id: hh }

    function focusField() { input.forceActiveFocus() }
}
