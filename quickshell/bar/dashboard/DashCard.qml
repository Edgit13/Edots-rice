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

        Row {
            visible: root.title.length > 0
            spacing: Theme.space.xs
            // Nothing: червона крапка + моно-капс заголовок; Material: звичайний titleSmall
            Rectangle {
                visible: Theme.settings.nothing
                width: 5; height: 5; radius: 2.5
                anchors.verticalCenter: parent.verticalCenter
                color: ThemeNothing.red
            }
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.settings.nothing ? root.title.toUpperCase() : root.title
                style: Theme.settings.nothing ? Theme.type.labelMedium : Theme.type.titleSmall
                color: Theme.color.fgSurfaceVariant
                font.letterSpacing: Theme.settings.nothing ? 2 : style.tracking
            }
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
