import "root:/theme"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool vertical: false
    property real spacing: Theme.space.sm
    property alias leading: leadingGrid.data
    property alias center: centerGrid.data
    property alias trailing: trailingGrid.data

    GridLayout {
        id: leadingGrid
        columns: root.vertical ? 1 : 999
        rowSpacing: root.spacing
        columnSpacing: root.spacing
        x: root.vertical ? (root.width - width) / 2 : 0
        y: root.vertical ? 0 : (root.height - height) / 2
    }

    GridLayout {
        id: centerGrid
        columns: root.vertical ? 1 : 999
        rowSpacing: root.spacing
        columnSpacing: root.spacing
        x: (root.width - width) / 2
        y: (root.height - height) / 2
    }

    GridLayout {
        id: trailingGrid
        columns: root.vertical ? 1 : 999
        rowSpacing: root.spacing
        columnSpacing: root.spacing
        x: root.vertical ? (root.width - width) / 2 : root.width - width
        y: root.vertical ? root.height - height : (root.height - height) / 2
    }
}
