import QtQuick
import "components"

// M3 Navigation Rail
Rectangle {
    id: root
    readonly property var c: theme.c
    color: c.surface

    readonly property var items: [
        { key: "browser",   icon: "public",    label: "Браузер" },
        { key: "bookmarks", icon: "bookmarks", label: "Закладки" },
        { key: "history",   icon: "history",   label: "Історія" }
    ]

    Column {
        y: 12
        width: parent.width
        spacing: 4
        Repeater {
            model: root.items
            delegate: RailItem {
                required property var modelData
                icon: modelData.icon
                label: modelData.label
                selected: browser.section === modelData.key
                onClicked: browser.showSection(modelData.key)
            }
        }
    }
    RailItem {
        anchors { bottom: parent.bottom; bottomMargin: 12 }
        icon: "settings"
        label: "Параметри"
        selected: browser.section === "settings"
        onClicked: browser.showSection("settings")
    }
}
