import "root:/theme"
import QtQuick

// DashCard — M3 Expressive картка-контейнер для дашборду.
// DashCard { title: "Погода"; content: [ ... ] }
Item {
    id: root
    default property alias content: body.data
    property string title: ""
    property int level: Theme.elevation.resting

    implicitHeight: col.implicitHeight + Theme.space.lg * 2

    ElevationShadow {
        anchors.fill: parent
        level: root.level
        radius: Theme.shape.cardLarge
        color: Theme.color.surfaceContainer
    }

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.space.lg
        spacing: Theme.space.sm

        ThemedText {
            visible: root.title.length > 0
            text: root.title
            style: Theme.type.titleSmall
            color: Theme.color.fgSurfaceVariant
        }

        Item { id: body; width: parent.width; height: childrenRect.height }
    }
}
