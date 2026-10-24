import "root:/theme"
import QtQuick

// BarIcon — іконка-гліф (Material Symbols) стандартного розміру для бару.
// Раніше `font { family: Theme.type.icons; pixelSize: Theme.type.iconS }` + колір копіювались у кожному модулі.
Text {
    property int size: Theme.type.iconS
    color: Theme.color.fgSurface
    font { family: Theme.type.icons; pixelSize: size }
}
