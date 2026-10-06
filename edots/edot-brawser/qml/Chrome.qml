import QtQuick
import QtQuick.Layouts
import "components"

// Верхня панель: вкладки + навігація + адресний рядок
Rectangle {
    id: root
    readonly property var c: theme.c
    color: c.surface

    readonly property int tabCount: Math.max(1, browser.tabs.length)
    readonly property real tabWidth: Math.max(64, Math.min(220, (tabStrip.width - 56) / tabCount - 2))

    Connections {
        target: browser
        function onFocusAddressRequested() {
            address.forceActiveFocus()
            address.selectAll()
        }
    }

    // ------------------------------------------------ вкладки
    Item {
        id: tabStrip
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 8; rightMargin: 8; topMargin: 6 }
        height: 38

        ListView {
            id: tabList
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: Math.min(contentWidth, parent.width - 44)
            orientation: ListView.Horizontal
            interactive: false
            spacing: 2
            clip: true
            model: browser.tabs

            delegate: Rectangle {
                id: tab
                required property var modelData
                readonly property bool active: modelData.active
                readonly property bool showClose: width > 96 || active

                width: root.tabWidth
                height: 36
                radius: 12
                color: active ? c.secondary_container : "transparent"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: c.on_surface
                    opacity: !active && hover.hovered ? 0.08 : 0
                }
                HoverHandler { id: hover }

                MouseArea {
                    anchors { fill: parent; rightMargin: tab.showClose ? 30 : 0 }
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) browser.closeTab(modelData.index)
                        else browser.activateTab(modelData.index)
                    }
                }
                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 4 }
                    spacing: 8

                    Item {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        Image {
                            anchors.fill: parent
                            visible: modelData.icon !== ""
                            source: modelData.icon
                            sourceSize: Qt.size(32, 32)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            cache: false
                        }
                        Icon {
                            visible: modelData.icon === ""
                            name: "public"
                            size: 16
                            color: active ? c.on_secondary_container : c.on_surface_variant
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.title
                        color: active ? c.on_secondary_container : c.on_surface_variant
                        font.pixelSize: 13
                        font.weight: active ? Font.Medium : Font.Normal
                        elide: Text.ElideRight
                    }
                    IconButton {
                        visible: tab.showClose
                        icon: "close"
                        size: 24
                        iconSize: 16
                        iconColor: active ? c.on_secondary_container : c.on_surface_variant
                        onClicked: browser.closeTab(modelData.index)
                    }
                }
            }
        }
        IconButton {
            anchors { left: tabList.right; leftMargin: 4; verticalCenter: parent.verticalCenter }
            icon: "add"
            size: 32
            iconSize: 20
            tip: "Нова вкладка (Ctrl+T)"
            onClicked: browser.newTab()
        }
    }

    // ------------------------------------------------ навігація
    RowLayout {
        id: nav
        anchors { left: parent.left; right: parent.right; top: tabStrip.bottom; topMargin: 4; leftMargin: 8; rightMargin: 8 }
        height: 52
        spacing: 2

        IconButton { icon: "arrow_back"; enabled: browser.canGoBack; tip: "Назад (Alt+←)"; onClicked: browser.back() }
        IconButton { icon: "arrow_forward"; enabled: browser.canGoForward; tip: "Вперед (Alt+→)"; onClicked: browser.forward() }
        IconButton {
            icon: browser.loading ? "close" : "refresh"
            tip: browser.loading ? "Зупинити" : "Оновити (Ctrl+R)"
            onClicked: browser.loading ? browser.stop() : browser.reload()
        }
        IconButton { icon: "home"; tip: "Додому"; onClicked: browser.goHome() }

        Item { Layout.preferredWidth: 6 }

        // ---- адресний рядок
        Rectangle {
            id: pill
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            radius: 22
            color: address.activeFocus ? c.surface_container_high
                 : (pillHover.hovered ? c.surface_container_highest : c.surface_container_high)
            border.width: address.activeFocus ? 2 : 0
            border.color: c.primary
            HoverHandler { id: pillHover }

            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                spacing: 10

                Icon {
                    readonly property string u: browser.currentUrl
                    readonly property bool secure: u.indexOf("https://") === 0
                    readonly property bool insecure: u.indexOf("http://") === 0
                    name: u.length === 0 ? "search" : secure ? "lock" : insecure ? "lock_open" : "info"
                    size: 20
                    color: insecure ? c.error : c.on_surface_variant
                }
                TextInput {
                    id: address
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: browser.currentUrl.indexOf("about:") === 0 ? "" : browser.currentUrl
                    color: c.on_surface
                    font.pixelSize: 14
                    clip: true
                    selectByMouse: true
                    selectionColor: c.primary_container
                    selectedTextColor: c.on_primary_container
                    onAccepted: browser.navigate(text)
                    Keys.onEscapePressed: { text = browser.currentUrl; browser.focusWeb() }

                    Text {
                        visible: address.text.length === 0 && !address.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Пошук або адреса сайту"
                        color: c.on_surface_variant
                        font.pixelSize: 14
                    }
                    Connections {
                        target: browser
                        function onCurrentUrlChanged() {
                            if (!address.activeFocus)
                                address.text = browser.currentUrl.indexOf("about:") === 0 ? "" : browser.currentUrl
                        }
                    }
                }

                // ---- чіп дозволів сайту (assist chip)
                Rectangle {
                    id: chip
                    visible: browser.currentHost.length > 0
                    Layout.preferredHeight: 30
                    Layout.preferredWidth: chipRow.implicitWidth + 20
                    radius: 8
                    color: browser.permission === "trusted" ? c.primary_container
                         : browser.permission === "blocked" ? c.error_container : "transparent"
                    border.width: browser.permission === "default" ? 1 : 0
                    border.color: c.outline

                    readonly property color fg: browser.permission === "trusted" ? c.on_primary_container
                                              : browser.permission === "blocked" ? c.on_error_container
                                              : c.on_surface_variant
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: chip.fg
                        opacity: chipMa.pressed ? 0.12 : (chipMa.containsMouse ? 0.08 : 0)
                    }
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6
                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: browser.permission === "trusted" ? "verified_user"
                                : browser.permission === "blocked" ? "block" : "shield"
                            size: 16
                            color: chip.fg
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: browser.permission === "trusted" ? "Довірений"
                                : browser.permission === "blocked" ? "Заблокований" : "Типово"
                            color: chip.fg
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var p = chip.mapToItem(null, chip.width, chip.height + 6)
                            browser.openPopup("permission", p.x, p.y)
                        }
                    }
                }
                IconButton {
                    icon: browser.bookmarked ? "star" : "star_border"
                    size: 32
                    iconSize: 22
                    iconColor: browser.bookmarked ? c.primary : c.on_surface_variant
                    tip: browser.bookmarked ? "Видалити із закладок (Ctrl+D)" : "Додати в закладки (Ctrl+D)"
                    onClicked: browser.toggleBookmark()
                }
            }
        }

        Item { Layout.preferredWidth: 4 }
        IconButton {
            id: menuBtn
            icon: "more_vert"
            tip: "Меню"
            onClicked: {
                var p = menuBtn.mapToItem(null, menuBtn.width, menuBtn.height + 4)
                browser.openPopup("menu", p.x, p.y)
            }
        }
    }

    // ------------------------------------------------ прогрес
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 3
        visible: browser.loading
        color: c.surface_container_highest
        Rectangle {
            height: parent.height
            width: parent.width * browser.loadProgress / 100
            color: c.primary
            Behavior on width { NumberAnimation { duration: theme.animations ? 120 : 0 } }
        }
    }
}
