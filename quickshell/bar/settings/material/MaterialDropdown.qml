pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Controls

// M3 Expressive Dropdown (menu): поле-заголовок + popup зі scale/fade, вибраний пункт — secondaryContainer.
Item {
    id: dd

    property var options: []
    property var value: null
    property string label: ""
    property bool enabled_: true
    property bool open: popup.visible
    signal selected(var v)

    implicitHeight: Theme.components.dp(48)
    implicitWidth: Theme.components.dp(200)
    opacity: enabled_ ? 1 : Theme.components.disabledContent

    readonly property var current: {
        for (let i = 0; i < options.length; i++) {
            const o = options[i]
            const v = (typeof o === "object" && o !== null) ? o.value : o
            if (v === value) return o
        }
        return null
    }
    readonly property string currentLabel: {
        const o = current
        if (o === null) return label.length > 0 ? label : "—"
        return (typeof o === "object") ? (o.label || String(o.value)) : String(o)
    }

    Rectangle {
        id: header
        anchors.fill: parent
        radius: Theme.shape.field
        color: Theme.color.surfaceContainerHighest
        border.width: dd.open ? Theme.components.dp(2) : 0
        border.color: Theme.color.primary
        Behavior on border.color { MotionColorAnimation { role: "hover" } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.color.fgSurface
            opacity: ma.pressed ? Theme.components.statePressed
                   : ma.containsMouse ? Theme.components.stateHover : 0
            Behavior on opacity { MotionAnimation { role: "hover" } }
        }

        ThemedText {
            anchors.left: parent.left
            anchors.leftMargin: Theme.space.lg
            anchors.right: arrow.left
            anchors.rightMargin: Theme.space.sm
            anchors.verticalCenter: parent.verticalCenter
            text: dd.currentLabel
            style: Theme.type.bodyLarge
            elide: Text.ElideRight
        }
        Text {
            id: arrow
            anchors.right: parent.right
            anchors.rightMargin: Theme.space.md
            anchors.verticalCenter: parent.verticalCenter
            text: "keyboard_arrow_down"
            color: Theme.color.fgSurfaceVariant
            font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
            rotation: dd.open ? 180 : 0
            Behavior on rotation { MotionAnimation { role: "morph" } }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            enabled: dd.enabled_
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: dd.open ? popup.close() : popup.open()
        }
    }

    Popup {
        id: popup
        y: header.height + Theme.space.xs
        width: header.width
        height: Math.min(Theme.components.dp(300), popupCol.implicitHeight + Theme.space.sm * 2)
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        transformOrigin: Popup.Top

        enter: Transition {
            MotionAnimation { property: "scale"; from: 0.9; to: 1; role: "expand" }
            MotionAnimation { property: "opacity"; from: 0; to: 1; role: "fade" }
        }
        exit: Transition {
            MotionAnimation { property: "opacity"; to: 0; role: "exit" }
        }

        background: Rectangle {
            radius: Theme.shape.menu
            color: Theme.color.surfaceContainerHigh
            border.width: 1
            border.color: Theme.color.outlineVariant
        }

        contentItem: Flickable {
            anchors.fill: parent
            anchors.margins: Theme.space.sm
            clip: true
            contentHeight: popupCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: popupCol
                width: parent.width
                spacing: Theme.space.listGap

                Repeater {
                    model: dd.options
                    delegate: Rectangle {
                        id: item
                        required property var modelData
                        required property int index
                        readonly property var v: (typeof modelData === "object" && modelData !== null) ? modelData.value : modelData
                        readonly property string l: (typeof modelData === "object" && modelData !== null) ? (modelData.label || String(modelData.value)) : String(modelData)
                        readonly property bool sel: dd.value === v

                        width: parent.width
                        height: Theme.components.dp(40)
                        radius: sel ? Theme.shape.radius("md", height) : Theme.shape.sm
                        color: sel ? Theme.color.secondaryContainer : "transparent"
                        Behavior on radius { MotionAnimation { role: "morph" } }
                        Behavior on color { MotionColorAnimation { role: "hover" } }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.color.fgSurface
                            opacity: ma2.pressed ? Theme.components.statePressed
                                   : ma2.containsMouse ? Theme.components.stateHover : 0
                            Behavior on opacity { MotionAnimation { role: "hover" } }
                        }

                        ThemedText {
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.space.lg
                            anchors.verticalCenter: parent.verticalCenter
                            text: item.l
                            style: Theme.type.bodyLarge
                            color: item.sel ? Theme.color.fgSecondaryContainer : Theme.color.fgSurface
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.space.lg
                            anchors.verticalCenter: parent.verticalCenter
                            visible: item.sel
                            text: "check"
                            color: Theme.color.fgSecondaryContainer
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                        }

                        MouseArea {
                            id: ma2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dd.value = item.v
                                dd.selected(item.v)
                                popup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
