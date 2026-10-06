import QtQuick

// M3 standard icon button з state layer (hover 8%, pressed 12%)
Item {
    id: root
    readonly property var c: theme.c

    property string icon: ""
    property int size: 40
    property int iconSize: 24
    property color iconColor: c.on_surface_variant
    property string tip: ""
    property bool filled: false          // tonal-варіант
    readonly property alias hovered: ma.containsMouse
    signal clicked()

    width: size
    height: size
    opacity: enabled ? 1 : 0.38

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.filled ? c.secondary_container : "transparent"
    }
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.filled ? c.on_secondary_container : root.iconColor
        opacity: ma.pressed ? 0.12 : (ma.containsMouse ? 0.08 : 0)
        Behavior on opacity { NumberAnimation { duration: theme.animations ? 100 : 0 } }
    }
    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.filled ? c.on_secondary_container : root.iconColor
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onContainsMouseChanged: {
            if (containsMouse && root.tip) tipTimer.restart()
            else { tipTimer.stop(); browser.hideTip() }
        }
    }
    Timer {
        id: tipTimer
        interval: 550
        onTriggered: {
            if (!ma.containsMouse || !root.tip) return
            var p = root.mapToItem(null, root.width / 2, root.height + 2)
            browser.showTip(uiArea, root.tip, p.x, p.y)
        }
    }
}
