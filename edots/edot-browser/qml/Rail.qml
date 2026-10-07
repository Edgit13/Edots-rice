import QtQuick
import "components"

// M3 Navigation Rail
Rectangle {
    id: root
    readonly property var c: theme.c
    color: c.surface

    readonly property var items: [
        { key: "browser",   icon: "public",    label: i18n.s.rail_browser },
        { key: "bookmarks", icon: "bookmarks", label: i18n.s.rail_bookmarks },
        { key: "history",   icon: "history",   label: i18n.s.rail_history }
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
        label: i18n.s.rail_settings
        selected: browser.section === "settings"
        onClicked: browser.showSection("settings")
    }
}
