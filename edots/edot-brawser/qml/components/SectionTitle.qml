import QtQuick

Text {
    readonly property var c: theme.c
    color: c.primary
    font.pixelSize: 14
    font.weight: Font.DemiBold
    leftPadding: 8
    topPadding: 12
}
