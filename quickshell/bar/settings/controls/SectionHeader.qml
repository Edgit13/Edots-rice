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
    color: Theme.color.primary
    font.letterSpacing: 1.2 * Theme.space.k
}
