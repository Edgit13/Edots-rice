pragma ComponentBehavior: Bound
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

Text {
    required property string label
    Layout.fillWidth: true
    Layout.topMargin: M3.s16
    text: label.toUpperCase()
    color: M3.primary
    font {
        family: M3.labelMedium.family
        pixelSize: M3.labelMedium.pixelSize
        weight: 700
        letterSpacing: 1.5
    }
}
