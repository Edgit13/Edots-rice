import "root:/theme"
import QtQuick
import QtQuick.Layouts

// DashCard — M3 Expressive картка-контейнер для дашборду.
// DashCard { title: "Погода"; content: [ ... ] }
Item {
    id: root
    default property alias content: body.data
    property string title: ""
    property int level: Theme.elevation.resting

    implicitHeight: Math.max(72, col.implicitHeight + Theme.space.lg * 2)

    ElevationShadow {
        anchors.fill: parent
        level: root.level
        radius: Theme.shape.cardLarge
        color: Theme.color.surfaceContainer
    }

    ColumnLayout {
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

        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
