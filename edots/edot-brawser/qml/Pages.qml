import QtQuick
import "components"
import "pages"

// Внутрішні сторінки: закладки, історія, параметри
Rectangle {
    id: root
    readonly property var c: theme.c
    color: c.surface_container_low

    Connections {
        target: browser
        function onSectionChanged() { if (theme.animations) fade.restart() }
    }
    NumberAnimation { id: fade; target: stack; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }

    Item {
        id: stack
        anchors.fill: parent

        Loader {
            anchors.fill: parent
            active: browser.section === "bookmarks"
            sourceComponent: ToolPage {
                title: "Закладки"
                searchHint: "Пошук у закладках"
                emptyTitle: "Закладок поки немає"
                emptyHint: "Натисніть зірочку в адресному рядку, щоб зберегти сторінку."
                emptyIcon: "bookmarks"
                clearText: "Видалити всі"
                items: store.bookmarks
                onOpenRequested: function(url) { browser.openUrl(url) }
                onRemoveRequested: function(id) { store.removeBookmark(id) }
                onClearRequested: confirmClear.openFor("bookmarks")
            }
        }
        Loader {
            anchors.fill: parent
            active: browser.section === "history"
            sourceComponent: ToolPage {
                title: "Історія"
                searchHint: "Пошук в історії"
                emptyTitle: "Історія порожня"
                emptyHint: "Тут з'являтимуться відвідані сторінки."
                emptyIcon: "history"
                clearText: "Очистити історію"
                items: store.history
                onOpenRequested: function(url) { browser.openUrl(url) }
                onRemoveRequested: function(id) { store.removeHistory(id) }
                onClearRequested: confirmClear.openFor("history")
            }
        }
        Loader {
            anchors.fill: parent
            active: browser.section === "settings"
            source: "pages/SettingsPage.qml"
        }
    }

    M3Dialog {
        id: confirmClear
        property string kind: ""
        function openFor(k) {
            kind = k
            title = k === "history" ? "Очистити історію?" : "Видалити всі закладки?"
            body = k === "history" ? "Усі відвідані сторінки буде видалено." : "Цю дію не можна скасувати."
            confirmText = "Видалити"
            danger = true
            open()
        }
        onConfirmed: browser.clearData(kind)
    }
}
