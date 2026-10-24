import "root:/theme"
import "root:/media"
import QtQuick

// BarRingStat — кільце-індикатор з іконкою + підпис поруч (горизонтально) або під ним (вертикально).
// Єдине місце для пари «MediaRing + текст», що раніше дублювалась у Media, Battery і Resources.
Grid {
    id: root

    property bool vertical: false
    property real value: 0
    property string glyph: ""
    property real ringSize: Math.max(Theme.components.dp(20), Theme.components.islandCompact - Theme.space.sm)
    property color ringColor: Theme.color.primary
    property color iconColor: ringColor

    property string text: ""                  // підпис у горизонтальному барі
    property string verticalText: ""          // підпис у вертикальному ("" = лише кільце)
    property color textColor: Theme.color.fgSurface
    property color verticalTextColor: Theme.color.fgSurfaceVariant
    property real maxTextWidth: -1            // >0 → обрізати з «…»

    columns: vertical ? 1 : 2
    spacing: vertical ? 2 : Theme.space.xs
    horizontalItemAlignment: Grid.AlignHCenter
    verticalItemAlignment: Grid.AlignVCenter

    MediaRing {
        width: root.ringSize
        height: root.ringSize
        value: root.value
        icon: root.glyph
        ringColor: root.ringColor
        iconColor: root.iconColor
    }

    ThemedText {
        readonly property string shownText: root.vertical ? root.verticalText : root.text
        visible: shownText.length > 0
        text: shownText
        style: root.vertical ? Theme.type.labelSmall : Theme.type.labelMedium
        color: root.vertical ? root.verticalTextColor : root.textColor
        elide: Text.ElideRight
        width: root.maxTextWidth > 0 ? Math.min(implicitWidth, root.maxTextWidth) : implicitWidth
    }
}
