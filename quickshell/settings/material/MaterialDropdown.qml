pragma ComponentBehavior: Bound
import "."
import QtQuick
import QtQuick.Controls

Item {
    id: dd
    property var options: []
    property var value: null
    property string label: ""
    property bool enabled_: true
    property bool open: popup.visible
    signal selected(var v)

    implicitHeight: 40
    implicitWidth: 180
    opacity: enabled_ ? 1 : M3.disabledOpacity

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
        radius: M3.rS
        color: ma.containsMouse ? M3.surfaceContainerHighest : M3.surfaceContainer
        border.width: dd.open ? 2 : 1
        border.color: dd.open ? M3.primary : M3.outline
        Behavior on color { ColorAnimation { duration: M3.durFast } }
        Behavior on border.color { ColorAnimation { duration: M3.durFast } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: M3.s12
            anchors.rightMargin: M3.s12
            spacing: M3.s8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: dd.currentLabel
                color: M3.m3OnSurface
                font: M3.bodyMedium
                elide: Text.ElideRight
                width: parent.width - 30
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "keyboard_arrow_down"
                color: M3.m3OnSurfaceVariant
                font { family: "Material Symbols Rounded"; pixelSize: 18 }
                rotation: dd.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: M3.durFast } }
            }
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
        y: header.height + 4
        width: header.width
        height: Math.min(280, popupCol.implicitHeight + M3.s8 * 2)
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: M3.rM
            color: M3.surfaceContainerHigh
            border.width: 1
            border.color: M3.outlineVariant
        }

        contentItem: Flickable {
            anchors.fill: parent
            anchors.margins: M3.s8
            clip: true
            contentHeight: popupCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: popupCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: dd.options
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property var v: (typeof modelData === "object" && modelData !== null) ? modelData.value : modelData
                        readonly property string l: (typeof modelData === "object" && modelData !== null) ? (modelData.label || String(modelData.value)) : String(modelData)

                        width: parent.width
                        height: 36
                        radius: M3.rS
                        color: (ma2.containsMouse || dd.value === v) ? M3.hoverOf(M3.m3OnSurface) : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: M3.s12
                            anchors.verticalCenter: parent.verticalCenter
                            text: parent.l
                            color: dd.value === parent.v ? M3.primary : M3.m3OnSurface
                            font: M3.bodyMedium
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: M3.s12
                            anchors.verticalCenter: parent.verticalCenter
                            visible: dd.value === parent.v
                            text: "check"
                            color: M3.primary
                            font { family: "Material Symbols Rounded"; pixelSize: 18 }
                        }

                        MouseArea {
                            id: ma2
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dd.value = parent.v
                                dd.selected(parent.v)
                                popup.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
