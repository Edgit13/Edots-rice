import QtQuick
import QtQuick.Layouts
import "../components"

// Головне меню (окреме вікно-попап)
Item {
    id: root
    readonly property var c: theme.c
    width: 296
    height: card.height + 2
    focus: true
    Keys.onEscapePressed: browser.closePopup()

    Rectangle {
        id: card
        x: 1; y: 1
        width: parent.width - 2
        height: col.implicitHeight + 16
        radius: 24
        color: c.surface_container
        border.width: 1
        border.color: c.outline_variant

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 8 }
            spacing: 2

            MenuRow { icon: "add"; text: "Нова вкладка"; hint: "Ctrl+T"; onClicked: { browser.closePopup(); browser.newTab() } }
            MenuRow { icon: "bookmarks"; text: "Закладки"; hint: "Ctrl+Shift+O"; onClicked: { browser.closePopup(); browser.showSection("bookmarks") } }
            MenuRow { icon: "history"; text: "Історія"; hint: "Ctrl+H"; onClicked: { browser.closePopup(); browser.showSection("history") } }

            Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; Layout.preferredHeight: 1; color: c.outline_variant }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 14
                Layout.rightMargin: 6
                spacing: 8
                Text { Layout.fillWidth: true; text: "Масштаб"; color: c.on_surface; font.pixelSize: 14 }
                IconButton { icon: "remove"; size: 32; iconSize: 20; onClicked: browser.zoomBy(-10) }
                Text {
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignHCenter
                    text: browser.zoomPercent + "%"
                    color: c.on_surface
                    font.pixelSize: 14
                }
                IconButton { icon: "add"; size: 32; iconSize: 20; onClicked: browser.zoomBy(10) }
            }

            Rectangle { Layout.fillWidth: true; Layout.topMargin: 4; Layout.bottomMargin: 4; Layout.preferredHeight: 1; color: c.outline_variant }

            MenuRow { icon: "settings"; text: "Параметри"; hint: "Ctrl+,"; onClicked: { browser.closePopup(); browser.showSettings() } }
        }
    }
}
