pragma ComponentBehavior: Bound
import "root:/theme"
import "."
import "material"
import "controls"
import Quickshell
import QtQuick
import QtQuick.Layouts

// SettingsApp — M3 Expressive: навігація зі слайд-індикатором, search bar, секції як connected list.
Item {
    id: app
    property int currentIndex: 0

    readonly property real navItemH: Theme.components.buttonM
    readonly property real navGap: Theme.space.xxs

    onCurrentIndexChanged: pageIn.restart()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ───────── navigation ─────────
        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: Theme.components.dp(236)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.lg
                spacing: 0

                ThemedText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space.md
                    Layout.bottomMargin: Theme.space.lg
                    text: Lang.t("settings.title")
                    style: Theme.type.headlineSmall
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: navCol.implicitHeight

                    // індикатор активної сторінки: їде між пунктами
                    Rectangle {
                        width: parent.width
                        height: app.navItemH
                        radius: Theme.shape.navItem
                        color: Theme.color.secondaryContainer
                        y: app.currentIndex * (app.navItemH + app.navGap)
                        Behavior on y { MotionAnimation { role: "move" } }
                    }

                    ColumnLayout {
                        id: navCol
                        width: parent.width
                        spacing: app.navGap

                        Repeater {
                            model: Schema.pages
                            Item {
                                id: navItem
                                required property var modelData
                                required property int index
                                readonly property bool active: app.currentIndex === index

                                Layout.fillWidth: true
                                implicitHeight: app.navItemH

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.shape.navItem
                                    color: Theme.color.fgSurface
                                    opacity: navMa.pressed ? Theme.components.statePressed
                                           : (navMa.containsMouse && !navItem.active) ? Theme.components.stateHover : 0
                                    Behavior on opacity { MotionAnimation { role: "hover" } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.space.lg
                                    anchors.rightMargin: Theme.space.lg
                                    spacing: Theme.space.md
                                    Text {
                                        text: navItem.modelData.icon
                                        color: navItem.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                                        font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                                        Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                    }
                                    ThemedText {
                                        Layout.fillWidth: true
                                        text: Lang.t(navItem.modelData.name)
                                        style: Theme.type.labelLarge
                                        emphasized: navItem.active
                                        color: navItem.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurface
                                        Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                    }
                                }

                                MouseArea {
                                    id: navMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: app.currentIndex = navItem.index
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        // ───────── content ─────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // search bar
            Rectangle {
                id: searchBar
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.lg
                Layout.leftMargin: Theme.space.lg
                Layout.rightMargin: Theme.space.lg
                Layout.bottomMargin: Theme.space.sm
                implicitHeight: Theme.components.dp(52)
                radius: Theme.shape.radius("full", height)
                color: Theme.color.surfaceContainerHigh
                border.width: search.activeFocus ? Theme.components.dp(2) : 0
                border.color: Theme.color.primary
                Behavior on border.color { MotionColorAnimation { role: "hover" } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space.lg
                    anchors.rightMargin: Theme.space.sm
                    spacing: Theme.space.md

                    Text {
                        text: "search"
                        color: Theme.color.fgSurfaceVariant
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.color.fgSurface
                        font.family: Theme.type.bodyLarge.family
                        font.pixelSize: Theme.type.bodyLarge.size
                        selectByMouse: true
                        clip: true
                        onTextChanged: SettingsSearch.query = text
                        Keys.onEscapePressed: { text = ""; SettingsSearch.clear() }
                        ThemedText {
                            anchors.fill: parent
                            visible: search.text.length === 0
                            text: Lang.t("search.placeholder")
                            style: Theme.type.bodyLarge
                            color: Theme.color.fgSurfaceVariant
                        }
                    }
                    MaterialIconButton {
                        icon: "close"
                        visible: search.text.length > 0
                        onClicked: { search.text = ""; SettingsSearch.clear() }
                    }
                }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: pageCol.implicitHeight + Theme.space.xl * 2
                boundsBehavior: Flickable.StopAtBounds

                ParallelAnimation {
                    id: pageIn
                    MotionAnimation { target: pageCol; property: "opacity"; from: 0; to: 1; role: "enter" }
                    MotionAnimation { target: pageCol; property: "y"; from: Theme.space.xl; to: Theme.space.sm; role: "enter" }
                }

                ColumnLayout {
                    id: pageCol
                    width: flick.width - Theme.space.lg * 2
                    x: Theme.space.lg
                    y: Theme.space.sm
                    spacing: Theme.space.md

                    Repeater {
                        model: Settings.sectionsForPage(app.currentIndex)

                        ColumnLayout {
                            id: sectionWrap
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Theme.space.sm

                            ThemedText {
                                Layout.fillWidth: true
                                Layout.topMargin: Theme.space.md
                                Layout.leftMargin: Theme.space.md
                                text: Lang.t(sectionWrap.modelData.label).toUpperCase()
                                style: Theme.type.labelMedium
                                emphasized: true
                                color: Theme.color.primary
                                font.letterSpacing: 1.2 * Theme.space.k
                            }

                            // connected list: кожен рядок — окрема плитка, заокруглені лише краї групи
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space.listGap

                                Repeater {
                                    id: rows
                                    model: sectionWrap.modelData.fields

                                    Rectangle {
                                        id: rowBox
                                        required property var modelData
                                        required property int index

                                        function vis(i) {
                                            const f = sectionWrap.modelData.fields[i]
                                            return !!f && SettingsSearch.matches(Lang.searchText(f.cat, f.key, f.field))
                                        }
                                        readonly property bool shown: vis(index)
                                        readonly property bool isFirst: {
                                            for (let j = 0; j < index; j++) if (vis(j)) return false
                                            return true
                                        }
                                        readonly property bool isLast: {
                                            const n = sectionWrap.modelData.fields.length
                                            for (let j = index + 1; j < n; j++) if (vis(j)) return false
                                            return true
                                        }
                                        readonly property real big: Theme.shape.cardLarge
                                        readonly property real small: Theme.shape.listInner

                                        Layout.fillWidth: true
                                        visible: shown
                                        implicitHeight: sr.implicitHeight + Theme.space.md * 2
                                        color: Theme.color.surfaceContainer

                                        topLeftRadius: isFirst ? big : small
                                        topRightRadius: isFirst ? big : small
                                        bottomLeftRadius: isLast ? big : small
                                        bottomRightRadius: isLast ? big : small
                                        Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
                                        Behavior on topRightRadius { MotionAnimation { role: "morph" } }
                                        Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
                                        Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }

                                        SchemaRow {
                                            id: sr
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: Theme.space.lg
                                                rightMargin: Theme.space.lg
                                            }
                                            cat: rowBox.modelData.cat
                                            key: rowBox.modelData.key
                                            field: rowBox.modelData.field
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ───────── About ─────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: app.currentIndex === Schema.pages.length - 1
                        spacing: Theme.space.sm

                        ThemedText {
                            Layout.fillWidth: true
                            Layout.topMargin: Theme.space.md
                            Layout.leftMargin: Theme.space.md
                            text: Lang.t("page.about").toUpperCase()
                            style: Theme.type.labelMedium
                            emphasized: true
                            color: Theme.color.primary
                            font.letterSpacing: 1.2 * Theme.space.k
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: aboutCol.implicitHeight + Theme.space.lg * 2
                            radius: Theme.shape.cardLarge
                            color: Theme.color.surfaceContainer

                            ColumnLayout {
                                id: aboutCol
                                anchors {
                                    left: parent.left; right: parent.right; top: parent.top
                                    margins: Theme.space.lg
                                }
                                spacing: Theme.space.sm
                                ThemedText {
                                    Layout.fillWidth: true
                                    text: Lang.t("about.title")
                                    style: Theme.type.titleMedium
                                    emphasized: true
                                }
                                ThemedText {
                                    Layout.fillWidth: true
                                    text: Lang.t("about.body")
                                    style: Theme.type.bodyMedium
                                    color: Theme.color.fgSurfaceVariant
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
