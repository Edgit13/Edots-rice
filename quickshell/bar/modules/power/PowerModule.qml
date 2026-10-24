import "root:/theme"
import "root:/modules/common"
import QtQuick

// PowerModule — кругла кнопка живлення; при hover підсвічується error-кольором, при натисканні форма морфиться.
// ЛКМ: Power menu · ПКМ: Налаштування.
BarModule {
    id: root

    signal powerRequested()
    signal settingsRequested()

    BarButton {
        id: btn
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        fillColor: hovered ? Theme.color.errorContainer : Theme.color.surfaceContainerHigh
        stateLayer: false                          // hover вже змінює заливку
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.settingsRequested()
            else root.powerRequested()
        }

        BarIcon {
            anchors.centerIn: parent
            text: "\ue8ac"
            color: btn.hovered ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
            Behavior on color { MotionColorAnimation { role: "hover" } }
        }
    }
}
