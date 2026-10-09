pragma ComponentBehavior: Bound
import "."
import QtQuick

Item {
    id: sl
    property real value: 0.5
    property bool enabled_: true
    property bool showValue: false
    property string suffix: ""
    property int decimals: 2
    signal moved(real v)

    implicitHeight: 28
    opacity: enabled_ ? 1 : M3.disabledOpacity

    property bool _dragging: false
    property real _dragValue: 0

    readonly property real clamped: Math.max(0, Math.min(1, value))
    readonly property real visualValue: _dragging ? _dragValue : clamped

    function _fromMouse(mx) {
        return Math.max(0, Math.min(1, mx / width))
    }

    Rectangle {
        id: track
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 16
        radius: 8
        color: M3.surfaceContainerHighest

        Rectangle {
            width: parent.width * sl.visualValue
            height: parent.height
            radius: parent.radius
            color: M3.primary
            Behavior on width { NumberAnimation { duration: M3.durFast } }
        }
    }

    Rectangle {
        id: thumb
        width: ma.pressed ? 6 : 4
        height: 24
        radius: width / 2
        x: track.x + track.width * sl.visualValue - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: M3.primary
        Behavior on width { NumberAnimation { duration: M3.durFast } }
    }

    Rectangle {
        visible: sl.showValue && ma.pressed
        anchors.bottom: track.top
        anchors.bottomMargin: 6
        anchors.horizontalCenter: thumb.horizontalCenter
        implicitWidth: valTxt.implicitWidth + M3.s12
        implicitHeight: 22
        radius: M3.rS
        color: M3.surfaceContainerHighest

        Text {
            id: valTxt
            anchors.centerIn: parent
            text: sl.visualValue.toFixed(sl.decimals) + sl.suffix
            color: M3.m3OnSurface
            font: M3.labelMedium
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        anchors.topMargin: -6
        anchors.bottomMargin: -6
        enabled: sl.enabled_
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: (m) => {
            sl._dragging = true
            sl._dragValue = sl._fromMouse(m.x)
        }
        onPositionChanged: (m) => {
            if (pressed) sl._dragValue = sl._fromMouse(m.x)
        }
        onReleased: (m) => {
            sl._dragValue = sl._fromMouse(m.x)
            sl._dragging = false
            sl.moved(sl._dragValue)
        }
        onCanceled: sl._dragging = false
    }
}
