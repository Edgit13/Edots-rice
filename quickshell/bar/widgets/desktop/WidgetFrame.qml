import "root:/theme"
import QtQuick

// WidgetFrame — M3-форма + кольори за темою. Контент кладеться в default-слот (вписаний у форму).
Item {
    id: root

    property string kind: "clock"
    default property alias content: contentArea.data

    readonly property string shapeName: WidgetsConfig.shapeFor(kind)
    readonly property color fillColor: WidgetsConfig.fill(kind)
    readonly property color onColor: WidgetsConfig.on(kind)
    readonly property color accentColor: WidgetsConfig.accent(kind)
    // текст на заповненій кнопці (у Nothing фон прозорий)
    readonly property color onOnColor: WidgetsConfig.plain ? ThemeColors.surface : WidgetsConfig.baseFill(kind)
    property alias contentItem: contentArea

    opacity: 0
    scale: 0.92
    Component.onCompleted: { opacity = 1; scale = 1 }
    Behavior on opacity { MotionAnimation { role: "fade" } }
    Behavior on scale   { MotionAnimation { role: "morphIn" } }

    ExpressiveShape {
        anchors.fill: parent
        shapeName: root.shapeName
        fillColor: root.fillColor
        strokeWidth: WidgetsConfig.borderWidth()
        strokeColor: WidgetsConfig.bgStyle === "outline" ? Theme.alpha(root.onColor, 0.6)
                   : ThemeSettings.nothing ? Theme.alpha(ThemeColors.fgSurface, 0.28)
                   : Theme.alpha(root.onColor, 0.18)
    }

    Item {
        id: contentArea
        anchors.centerIn: parent
        width: parent.width * 0.74
        height: parent.height * 0.72
    }
}
