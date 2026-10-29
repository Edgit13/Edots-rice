pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings"
import QtQuick
import QtQuick.Layouts

// BindsSurface — шпаргалка гарячих клавіш (як cheatsheet в end-4): пошук + групи з секцій binds.conf.
Item {
    id: root

    property string query: ""

    readonly property var groups: {
        const q = root.query.trim().toLowerCase()
        const map = {}, out = []
        const all = BindsService.entries
        for (let i = 0; i < all.length; i++) {
            const e = all[i]
            const desc = BindsService.describe(e)
            const g = BindsService.groupLabel(e.group)
            const hay = (desc + " " + e.keys.join(" ") + " " + e.cmd + " " + g).toLowerCase()
            if (q.length > 0 && hay.indexOf(q) < 0) continue
            if (!map[g]) { map[g] = { name: g, rows: [] }; out.push(map[g]) }
            map[g].rows.push({ desc: desc, keys: e.keys, cmd: e.cmd })
        }
        return out
    }

    Component.onCompleted: search.forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space.md

        // ---- пошук ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.components.dp(48)
            radius: Theme.shape.radius("full", height)
            color: Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainerHighest
            border.width: Theme.settings.nothing ? 1 : (search.activeFocus ? Theme.components.dp(2) : 0)
            border.color: Theme.settings.nothing
                ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, search.activeFocus ? 0.75 : 0.22)
                : Theme.color.primary
            Behavior on border.color { MotionColorAnimation { role: "hover" } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.lg
                anchors.rightMargin: Theme.space.md
                spacing: Theme.space.md

                Text {
                    text: "\ue8b6"
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
                    selectionColor: Theme.settings.nothing ? ThemeNothing.red : Theme.color.primary
                    selectedTextColor: Theme.settings.nothing ? "#FFFFFF" : Theme.color.fgPrimary
                    onTextChanged: root.query = text
                    ThemedText {
                        anchors.fill: parent
                        visible: search.text.length === 0
                        text: Lang.t("ui.binds.search")
                        style: Theme.type.bodyLarge
                        color: Theme.color.fgSurfaceVariant
                    }
                }
                ThemedText {
                    text: String(BindsService.entries.length)
                    style: Theme.type.labelMedium
                    color: Theme.color.fgSurfaceVariant
                }
            }
        }

        // ---- список ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: col.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: col
                    width: flick.width
                    spacing: Theme.space.md

                    Repeater {
                        model: root.groups

                        ColumnLayout {
                            id: grp
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: Theme.space.xs

                            ThemedText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.space.sm
                                text: grp.modelData.name.toUpperCase()
                                style: Theme.type.labelMedium
                                emphasized: true
                                color: Theme.color.primary
                                font.letterSpacing: 1.2 * Theme.space.k
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space.listGap

                                Repeater {
                                    model: grp.modelData.rows

                                    Rectangle {
                                        id: row
                                        required property var modelData
                                        required property int index
                                        readonly property bool isFirst: index === 0
                                        readonly property bool isLast: index === grp.modelData.rows.length - 1
                                        readonly property real big: Theme.shape.md
                                        readonly property real small: Theme.shape.listInner

                                        Layout.fillWidth: true
                                        implicitHeight: Math.max(Theme.components.dp(44), rowContent.implicitHeight + Theme.space.sm * 2)
                                        color: Theme.color.surfaceContainer
                                        topLeftRadius: isFirst ? big : small
                                        topRightRadius: isFirst ? big : small
                                        bottomLeftRadius: isLast ? big : small
                                        bottomRightRadius: isLast ? big : small

                                        Rectangle {
                                            anchors.fill: parent
                                            topLeftRadius: parent.topLeftRadius
                                            topRightRadius: parent.topRightRadius
                                            bottomLeftRadius: parent.bottomLeftRadius
                                            bottomRightRadius: parent.bottomRightRadius
                                            color: Theme.color.fgSurface
                                            opacity: hov.hovered ? Theme.components.stateHover : 0
                                            Behavior on opacity { MotionAnimation { role: "hover" } }
                                        }
                                        HoverHandler { id: hov }

                                        RowLayout {
                                            id: rowContent
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: Theme.space.md
                                                rightMargin: Theme.space.md
                                            }
                                            spacing: Theme.space.md

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0
                                                ThemedText {
                                                    Layout.fillWidth: true
                                                    text: row.modelData.desc
                                                    style: Theme.type.bodyMedium
                                                    elide: Text.ElideRight
                                                }
                                                ThemedText {
                                                    Layout.fillWidth: true
                                                    visible: hov.hovered && row.modelData.cmd.length > 0
                                                    text: row.modelData.cmd
                                                    style: Theme.type.labelSmall
                                                    color: Theme.color.fgSurfaceVariant
                                                    elide: Text.ElideMiddle
                                                }
                                            }

                                            // кейкапи
                                            Row {
                                                spacing: Theme.space.xxs
                                                Repeater {
                                                    model: row.modelData.keys
                                                    Rectangle {
                                                        id: cap
                                                        required property string modelData
                                                        implicitHeight: Theme.components.dp(26)
                                                        implicitWidth: Math.max(Theme.components.dp(26), capText.implicitWidth + Theme.space.md)
                                                        radius: Theme.shape.xs
                                                        color: Theme.color.surfaceContainerHighest
                                                        border.width: 1
                                                        border.color: Theme.color.outlineVariant
                                                        ThemedText {
                                                            id: capText
                                                            anchors.centerIn: parent
                                                            text: cap.modelData
                                                            style: Theme.type.labelMedium
                                                            emphasized: true
                                                            color: Theme.color.fgSurface
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // нічого не знайдено
            ThemedText {
                anchors.centerIn: parent
                visible: root.groups.length === 0
                text: Lang.t("ui.binds.empty")
                style: Theme.type.bodyLarge
                color: Theme.color.fgSurfaceVariant
            }
        }
    }
}
