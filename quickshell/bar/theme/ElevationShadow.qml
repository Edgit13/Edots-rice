import "root:/theme"
import QtQuick
import QtQuick.Effects

// Тінь для рівня elevation (0..5) + tonal-заливка. Клади ПІД контент або використовуй як фон:
//   ElevationShadow { level: 2; radius: Theme.shape.card; anchors.fill: parent }
// Caster непрозорий (tonal-колір), тож для напівпрозорих поверхонь ставь color: "transparent"
// і level: 0 (без тіні) або вимикай shadowVisible.
Item {
    id: root
    property real level: 1
    property real radius: ThemeShapes.card
    property color color: ThemeElevation.surfaceFor(level)
    property bool shadowVisible: level > 0.05
    property alias content: caster   // фон-прямокутник (для border тощо)

    Rectangle {
        id: caster
        anchors.fill: parent
        radius: root.radius
        color: root.color
        layer.enabled: root.shadowVisible
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: ThemeColors.shadow
            shadowOpacity: ThemeElevation.opacity(root.level)
            shadowBlur: Math.min(1, ThemeElevation.blur(root.level) / 32)
            shadowVerticalOffset: ThemeElevation.offsetY(root.level)
            blurMax: 32
        }
    }
}
