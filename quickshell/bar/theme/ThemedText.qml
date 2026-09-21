import "root:/theme"
import QtQuick

// Text із M3-типографікою: ThemedText { style: Theme.type.titleMedium; emphasized: true }
Text {
    property var style: ThemeTypography.bodyMedium
    property bool emphasized: false

    color: ThemeColors.fgSurface
    font.family: style.family
    font.pixelSize: style.size
    font.weight: emphasized ? style.emphasizedWeight : style.weight
    font.letterSpacing: style.tracking
    lineHeight: style.line
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter
}
