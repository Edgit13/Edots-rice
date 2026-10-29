pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

ThemedText {
    required property string label
    Layout.fillWidth: true
    Layout.topMargin: Theme.space.lg
    text: label.toUpperCase()
    style: Theme.type.labelMedium
    emphasized: true
    color: Theme.settings.nothing ? Theme.color.fgSurfaceVariant : Theme.color.primary
    font.letterSpacing: (Theme.settings.nothing ? 2.5 : 1.2) * Theme.space.k
}
