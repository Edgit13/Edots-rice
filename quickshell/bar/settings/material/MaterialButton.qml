pragma ComponentBehavior: Bound
import "root:/theme"
import QtQuick
import QtQuick.Layouts

// M3 Expressive Button: filled | tonal | outlined | text. Форма: пігулка → при натисканні морф у менший радіус.
Rectangle {
    id: btn

    property string text: ""
    property string icon: ""
    property string style: "filled"
    property bool enabled_: true
    property string tooltip: ""
    signal clicked()

    implicitWidth: Math.max(Theme.components.dp(64), row.implicitWidth + Theme.space.xl)
    implicitHeight: Theme.components.buttonS
    opacity: enabled_ ? 1 : Theme.components.disabledContent

    readonly property color _bg: {
        switch (style) {
        case "tonal":    return Theme.settings.nothing ? "transparent" : Theme.color.secondaryContainer
        case "outlined": return "transparent"
        case "text":     return "transparent"
        default:         return Theme.color.primary
        }
    }
    readonly property color _fg: {
        switch (style) {
        case "tonal":    return Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.fgSecondaryContainer
        case "outlined": return Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.primary
        case "text":     return Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.primary
        default:         return Theme.color.fgPrimary
        }
    }

    color: btn._bg
    radius: ma.pressed ? Theme.shape.buttonPressed : Theme.shape.radius("full", height)
    border.width: (style === "outlined" || (Theme.settings.nothing && style === "tonal")) ? 1 : 0
    border.color: Theme.settings.nothing
        ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.35)
        : Theme.color.outline

    Behavior on color { MotionColorAnimation { role: "hover" } }
    Behavior on radius { MotionAnimation { role: "morph" } }

    // state layer
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: btn._fg
        opacity: ma.pressed ? Theme.components.statePressed
               : ma.containsMouse ? Theme.components.stateHover : 0
        Behavior on opacity { MotionAnimation { role: "hover" } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.space.sm

        Text {
            visible: btn.icon.length > 0
            text: btn.icon
            color: btn._fg
            font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
        }
        ThemedText {
            visible: btn.text.length > 0
            text: btn.text
            color: btn._fg
            style: Theme.type.labelLarge
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: btn.enabled_
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: btn.clicked()
    }

    Rectangle {
        visible: btn.tooltip.length > 0 && ma.containsMouse
        anchors.top: parent.bottom
        anchors.topMargin: Theme.space.xs
        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: tipTxt.implicitWidth + Theme.space.md * 2
        implicitHeight: Theme.components.tooltipHeight
        radius: Theme.shape.tooltip
        color: Theme.color.inverseSurface
        z: 99
        ThemedText {
            id: tipTxt
            anchors.centerIn: parent
            text: btn.tooltip
            style: Theme.type.labelSmall
            color: Theme.color.inverseOnSurface
        }
    }
}
