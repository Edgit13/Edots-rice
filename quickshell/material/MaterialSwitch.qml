pragma ComponentBehavior: Bound
import "root:/"
import QtQuick

// Material 3 Switch (52x32).
Rectangle {
    id: sw
    property bool checked: false
    property bool enabled_: true
    signal toggled()

    width: 52
    height: 32
    radius: 16
    opacity: enabled_ ? 1.0 : M3.disabledOpacity

    color: {
        if (!sw.enabled_) return M3.surfaceContainerHighest
        if (sw.checked) {
            if (ma.pressed) return M3.mix(M3.primary, M3.onPrimary, 0.12)
            return M3.primary
        }
        return ma.containsMouse ? M3.mix(M3.surfaceContainerHighest, M3.onSurface, 0.08)
                                : M3.surfaceContainerHighest
    }
    border.width: sw.checked ? 0 : 2
    border.color: M3.outline

    Behavior on color { ColorAnimation { duration: M3.durMed; easing.type: Easing.OutCubic } }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        y: 8
        x: sw.checked ? parent.width - width - 8 : 8
        color: sw.checked ? M3.onPrimary : M3.outline
        scale: ma.pressed ? 1.4 : 1.0

        Behavior on x { NumberAnimation { duration: M3.durMed; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: M3.durFast } }
        Behavior on color { ColorAnimation { duration: M3.durMed } }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: sw.enabled_
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: sw.toggled()
    }
}
