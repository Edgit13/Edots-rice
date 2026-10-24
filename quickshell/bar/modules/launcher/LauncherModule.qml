import "root:/theme"
import "root:/modules/common"
import QtQuick

// LauncherModule — кругла tonal-кнопка (як лівий край бару в end-4); при натисканні форма морфиться.
BarModule {
    id: root

    signal activated()

    BarButton {
        anchors.fill: parent
        fillColor: Theme.color.primaryContainer
        stateColor: Theme.color.fgPrimaryContainer
        onClicked: root.activated()

        BarIcon {
            anchors.centerIn: parent
            text: "\ue5c3"
            color: Theme.color.fgPrimaryContainer
        }
    }
}
