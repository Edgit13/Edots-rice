import "root:/theme"
import "root:/states"
import "root:/settings"
import "root:/modules/common"
import QtQuick

// GameModeModule — з'являється в барі лише в ігровому режимі: пігулка з геймпадом; клік вимикає режим.
BarModule {
    id: root

    readonly property bool active: GameModeState.active

    shown: active
    animate: true
    contentW: row.implicitWidth + Theme.space.md * 2

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
            BarIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: "\uea28"                                   // sports_esports
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
