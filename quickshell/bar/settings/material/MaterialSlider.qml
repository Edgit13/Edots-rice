pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick

// M3 Expressive Slider: активна/неактивна частини з проміжком навколо handle, handle стискається при натисканні.
Item {
    id: sl

    property real value: 0.5
    property bool enabled_: true
    property bool showValue: false
    property string suffix: ""
    property int decimals: 2
    signal moved(real v)

    readonly property real trackH: Theme.components.sliderXS
    readonly property real handleW: Theme.components.sliderHandleW * (ma.pressed ? 0.5 : 1)
    readonly property real handleH: trackH + Theme.components.dp(12)
    readonly property real gap: Theme.components.dp(6)

    implicitHeight: handleH + Theme.space.sm
    opacity: enabled_ ? 1 : Theme.components.disabledContent

    property bool _dragging: false
    property real _dragValue: 0
    readonly property real clamped: Math.max(0, Math.min(1, value))
    property real shown: _dragging ? _dragValue : clamped
    Behavior on shown { enabled: !sl._dragging; MotionAnimation { role: "move" } }

    readonly property real hx: width * Math.max(0, Math.min(1, shown))

    function _fromMouse(mx) { return Math.max(0, Math.min(1, mx / width)) }

    // активна частина
    Rectangle {
        x: 0
        y: (sl.height - sl.trackH) / 2
        width: Math.max(0, sl.hx - sl.handleW / 2 - sl.gap)
        height: sl.trackH
        color: Theme.color.primary
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: Theme.shape.xs
        bottomRightRadius: Theme.shape.xs
    }

    // неактивна частина
    Rectangle {
        x: Math.min(sl.width, sl.hx + sl.handleW / 2 + sl.gap)
        y: (sl.height - sl.trackH) / 2
        width: Math.max(0, sl.width - x)
        height: sl.trackH
        color: Theme.color.secondaryContainer
        topLeftRadius: Theme.shape.xs
        bottomLeftRadius: Theme.shape.xs
        topRightRadius: height / 2
        bottomRightRadius: height / 2
    }

    // handle
    Rectangle {
        id: handle
        width: sl.handleW
        height: sl.handleH
        radius: width / 2
        x: sl.hx - width / 2
        y: (sl.height - height) / 2
        color: Theme.color.primary
        Behavior on width { MotionAnimation { role: "press" } }
    }

    // value indicator
    Rectangle {
        anchors.horizontalCenter: handle.horizontalCenter
        anchors.bottom: handle.top
        anchors.bottomMargin: Theme.space.xs
        implicitWidth: valTxt.implicitWidth + Theme.space.lg
        implicitHeight: Theme.components.chipHeight
        radius: Theme.shape.full
        color: Theme.color.inverseSurface
        opacity: sl.showValue && ma.pressed ? 1 : 0
        visible: opacity > 0.01
        scale: ma.pressed ? 1 : 0.8
        Behavior on opacity { MotionAnimation { role: "hover" } }
        Behavior on scale { MotionAnimation { role: "morph" } }
        ThemedText {
            id: valTxt
            anchors.centerIn: parent
            text: sl.shown.toFixed(sl.decimals) + sl.suffix
            style: Theme.type.labelLarge
            color: Theme.color.inverseOnSurface
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: sl.enabled_
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: m => { sl._dragging = true; sl._dragValue = sl._fromMouse(m.x) }
        onPositionChanged: m => { if (pressed) sl._dragValue = sl._fromMouse(m.x) }
        onReleased: m => {
            sl._dragValue = sl._fromMouse(m.x)
            sl._dragging = false
            sl.moved(sl._dragValue)
        }
        onCanceled: sl._dragging = false
    }
}
