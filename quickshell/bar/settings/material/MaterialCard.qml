pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Layouts

// M3 Card: filled (surfaceContainerLow) або outlined.
Rectangle {
    id: card

    property string title: ""
    property bool outlined: false
    default property alias content: body.children

    Layout.fillWidth: true
    radius: Theme.shape.cardLarge
    color: card.outlined ? "transparent" : Theme.color.surfaceContainerLow
    border.width: card.outlined ? 1 : 0
    border.color: Theme.color.outlineVariant
    implicitHeight: body.implicitHeight + Theme.space.lg * 2

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Theme.space.lg
        }
        spacing: Theme.space.sm

        ThemedText {
            visible: card.title.length > 0
            Layout.fillWidth: true
            text: card.title
            style: Theme.type.titleSmall
            emphasized: true
        }
    }
}
