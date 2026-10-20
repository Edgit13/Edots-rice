import "root:/theme"
import "root:/states"
import "root:/settings"
import "root:/modules/common"
import QtQuick

// GameModeModule — з'являється в барі лише в ігровому режимі: пігулка з геймпадом; клік вимикає режим.
Item {
    id: root

    property bool vertical: false
    property int cross: Theme.components.islandCompact

    readonly property bool active: GameModeState.active

    visible: implicitWidth > 0
    implicitWidth: active ? (vertical ? cross : row.implicitWidth + Theme.space.md * 2) : 0
    implicitHeight: active ? cross : 0
    Behavior on implicitWidth { MotionAnimation { role: root.active ? "expand" : "collapse" } }
    opacity: active ? 1 : 0
    Behavior on opacity { MotionAnimation { role: "fade" } }

    BarButton {
        anchors.fill: parent
        accent: true
        accentColor: Theme.color.tertiaryContainer
        stateColor: Theme.color.fgTertiaryContainer
        onClicked: GameModeState.disable()

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.space.xs
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uea28"                                   // sports_esports
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: Theme.color.fgTertiaryContainer
            }
            ThemedText {
                visible: !root.vertical
                anchors.verticalCenter: parent.verticalCenter
                text: Lang.t("ui.game.label")
                style: Theme.type.labelMedium
                emphasized: true
                color: Theme.color.fgTertiaryContainer
            }
        }
    }
}
