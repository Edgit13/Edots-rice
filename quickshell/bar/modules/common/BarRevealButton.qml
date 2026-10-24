import "root:/theme"
import QtQuick

// BarRevealButton — кнопка-іконка, що при hover «виїжджає» підписом (Volume, Network).
// Раніше fullW / iconBox / opacity-підпис / Behavior дублювались у двох модулях.
BarModule {
    id: root

    property string glyph: ""
    property color glyphColor: Theme.color.fgSurface
    property string label: ""
    property color labelColor: Theme.color.fgSurface
    property real maxLabelWidth: Theme.components.dp(140)
    property string verticalLabel: ""         // дрібний підпис під іконкою у вертикальному барі
    property color verticalLabelColor: Theme.color.fgSurfaceVariant
    property int acceptedButtons: Qt.LeftButton

    readonly property bool hovered: btn.hovered
    signal clicked(var mouse)
    signal wheeled(var event)

    readonly property real iconBox: Theme.type.iconS
    readonly property real fullW: (cross + iconBox) / 2 + Theme.space.xs
                                  + Math.min(labelItem.implicitWidth, maxLabelWidth) + Theme.space.md

    animate: true
    contentW: hovered ? fullW : cross
    contentH: verticalLabel.length > 0 ? (vcol.implicitHeight + Theme.space.xs * 2) : cross

    BarButton {
        id: btn
        anchors.fill: parent
        acceptedButtons: root.acceptedButtons
        onClicked: mouse => root.clicked(mouse)
        onWheeled: e => root.wheeled(e)

        Row {
            visible: !root.vertical
            anchors.verticalCenter: parent.verticalCenter
            x: (btn.height - root.iconBox) / 2
            spacing: Theme.space.xs
            BarIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: root.glyphColor
                Behavior on color { MotionColorAnimation { role: "hover" } }
            }
            ThemedText {
                id: labelItem
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                style: Theme.type.labelMedium
                color: root.labelColor
                elide: Text.ElideRight
                width: Math.min(implicitWidth, root.maxLabelWidth)
                opacity: btn.hovered ? 1 : 0
                Behavior on opacity { MotionAnimation { role: "hover" } }
            }
        }

        Column {
            id: vcol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2
            BarIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.glyph
                color: root.glyphColor
            }
            ThemedText {
                visible: root.verticalLabel.length > 0
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.verticalLabel
                style: Theme.type.labelSmall
                color: root.verticalLabelColor
            }
        }
    }
}
