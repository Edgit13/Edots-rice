import "root:/theme"
import QtQuick
import QtQuick.Layouts

// BarGroup — «група» як у end-4: заокруглена плитка (surfaceContainerHigh) із плоскими модулями всередині.
// Ховається, якщо всередині немає видимих елементів.
Rectangle {
    id: root

    property bool vertical: false
    property real pad: Theme.space.xxs
    default property alias content: grid.data

    color: Theme.color.surfaceContainerHigh
    radius: Theme.shape.radius("full", Math.min(width, height))
    visible: grid.visibleChildren.length > 0

    implicitWidth: grid.implicitWidth + pad * 2
    implicitHeight: grid.implicitHeight + pad * 2

    GridLayout {
        id: grid
        x: root.pad
        y: root.pad
        flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columns: root.vertical ? 1 : 64
        rows: root.vertical ? 64 : 1
        rowSpacing: Theme.space.xxs
        columnSpacing: Theme.space.xxs
    }
}
