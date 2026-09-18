pragma ComponentBehavior: Bound
import "root:/"
import QtQuick
import QtQuick.Layouts

// Material 3 Card: filled (surfaceContainerLow) або outlined.
Rectangle {
    id: card
    property string title: ""
    property bool outlined: false
    default property alias content: body.children

    Layout.fillWidth: true
    radius: M3.rL
    color: card.outlined ? "transparent" : M3.surfaceContainerLow
    border.width: card.outlined ? 1 : 0
    border.color: M3.outlineVariant
    implicitHeight: body.implicitHeight + (card.title.length > 0 ? titleTxt.implicitHeight + M3.s16 : 0) + M3.s24

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: M3.s12
        }
        spacing: M3.s8

        Text {
            id: titleTxt
            visible: card.title.length > 0
            Layout.fillWidth: true
            text: card.title
            color: M3.onSurface
            font: M3.titleSmall
        }
    }
}
