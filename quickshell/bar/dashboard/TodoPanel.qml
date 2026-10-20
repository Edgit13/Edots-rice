pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings"
import "root:/settings/material"
import Quickshell
import QtQuick
import QtQuick.Layouts

// TodoPanel — список справ: додавання з датою, фільтри, редагування (подвійний клік), connected list.
DashCard {
    id: root

    property string selectedDay: ""                // вибраний у календарі день (фільтр + дата за замовчуванням)
    property string filter: "active"               // active | all | done
    property string newDue: ""
    signal dayCleared()

    readonly property var items: TodoService.list(filter, selectedDay)
    readonly property var filters: ["active", "all", "done"]

    onSelectedDayChanged: newDue = selectedDay

    function dueLabel(due) {
        if (!due) return ""
        if (due === TodoService.today()) return Lang.t("ui.todo.today")
        if (due === TodoService.tomorrow()) return Lang.t("ui.todo.tomorrow")
        const p = due.split("-")
        return p[2] + "." + p[1]
    }
    function addNow() {
        if (input.text.trim().length === 0) return
        TodoService.add(input.text, newDue)
        input.text = ""
    }

    component TodoCheck: Rectangle {
        id: chk
        property bool checked: false
        signal toggled()
        implicitWidth: Theme.components.dp(24)
        implicitHeight: implicitWidth
        radius: cma.pressed ? 4 : (checked ? height / 2 : Theme.components.dp(8))      // квадрат ↔ коло
        color: checked ? Theme.color.primary : "transparent"
        border.width: checked ? 0 : 2
        border.color: Theme.color.outline
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "stateChange" } }
        Text {
            anchors.centerIn: parent
            text: "\ue5ca"                                                              // check
            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
            color: Theme.color.fgPrimary
            opacity: chk.checked ? 1 : 0
            scale: chk.checked ? 1 : 0.4
            Behavior on opacity { MotionAnimation { role: "stateChange" } }
            Behavior on scale { MotionAnimation { role: "morph" } }
        }
        MouseArea { id: cma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: chk.toggled() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space.md

        // ---- заголовок ----
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm
            ThemedText { text: Lang.t("ui.todo.title"); style: Theme.type.titleMedium; emphasized: true }
            Rectangle {
                visible: TodoService.activeCount > 0
                implicitWidth: cnt.implicitWidth + Theme.space.lg
                implicitHeight: Theme.components.dp(22)
                radius: height / 2
                color: Theme.color.primaryContainer
                ThemedText { id: cnt; anchors.centerIn: parent; text: TodoService.activeCount; style: Theme.type.labelSmall; emphasized: true; color: Theme.color.fgPrimaryContainer }
            }
            Rectangle {
                visible: TodoService.overdueCount > 0
                implicitWidth: od.implicitWidth + Theme.space.lg
                implicitHeight: Theme.components.dp(22)
                radius: height / 2
                color: Theme.color.errorContainer
                ThemedText { id: od; anchors.centerIn: parent; text: Lang.t("ui.todo.overdue") + " " + TodoService.overdueCount; style: Theme.type.labelSmall; emphasized: true; color: Theme.color.fgErrorContainer }
            }
            Item { Layout.fillWidth: true }
            MaterialButton {
                visible: root.filter === "done" && root.items.length > 0
                text: Lang.t("ui.todo.clear")
                icon: "delete_sweep"
                style: "text"
                onClicked: TodoService.clearDone()
            }
        }

        // ---- додати ----
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Theme.components.dp(48)
            radius: Theme.shape.radius("full", height)
            color: Theme.color.surfaceContainerHighest
            border.width: input.activeFocus ? Theme.components.dp(2) : 0
            border.color: Theme.color.primary
            Behavior on border.color { MotionColorAnimation { role: "hover" } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.space.lg
                anchors.rightMargin: Theme.space.xs
                spacing: Theme.space.sm

                TextInput {
                    id: input
                    Layout.fillWidth: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.color.fgSurface
                    font.family: Theme.type.bodyLarge.family
                    font.pixelSize: Theme.type.bodyLarge.size
                    selectByMouse: true
                    clip: true
                    onAccepted: root.addNow()
                    ThemedText {
                        anchors.fill: parent
                        visible: input.text.length === 0
                        text: Lang.t("ui.todo.placeholder")
                        style: Theme.type.bodyLarge
                        color: Theme.color.fgSurfaceVariant
                    }
                }

                // дата: без / сьогодні / завтра (+ вибраний день, якщо є)
                Rectangle {
                    implicitHeight: Theme.components.dp(30)
                    implicitWidth: dueTxt.implicitWidth + Theme.space.lg + Theme.type.iconXS
                    radius: dueMa.pressed ? Theme.shape.sm : height / 2
                    color: root.newDue ? Theme.color.secondaryContainer : "transparent"
                    border.width: root.newDue ? 0 : 1
                    border.color: Theme.color.outlineVariant
                    Behavior on radius { MotionAnimation { role: "morph" } }
                    Behavior on color { MotionColorAnimation { role: "stateChange" } }
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.space.xs
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\ue878"
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                            color: root.newDue ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                        }
                        ThemedText {
                            id: dueTxt
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.newDue ? root.dueLabel(root.newDue) : Lang.t("ui.todo.noDate")
                            style: Theme.type.labelMedium
                            color: root.newDue ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                        }
                    }
                    MouseArea {
                        id: dueMa
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const t = TodoService.today(), m = TodoService.tomorrow()
                            if (!root.newDue) root.newDue = t
                            else if (root.newDue === t) root.newDue = m
                            else if (root.newDue === m && root.selectedDay && root.selectedDay !== m && root.selectedDay !== t) root.newDue = root.selectedDay
                            else root.newDue = ""
                        }
                    }
                }

                MaterialIconButton {
                    icon: "add"
                    style: "filled"
                    selected: input.text.trim().length > 0
                    onClicked: root.addNow()
                }
            }
        }

        // ---- фільтри ----
        MaterialSegmented {
            Layout.fillWidth: true
            options: [{ label: Lang.t("ui.todo.f.active") }, { label: Lang.t("ui.todo.f.all") }, { label: Lang.t("ui.todo.f.done") }]
            selectedIndex: root.filters.indexOf(root.filter)
            onSelected: i => root.filter = root.filters[i]
        }

        // ---- день із календаря ----
        RowLayout {
            Layout.fillWidth: true
            visible: root.selectedDay.length > 0
            spacing: Theme.space.sm
            Text {
                text: "\ue878"
                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                color: Theme.color.primary
            }
            ThemedText { Layout.fillWidth: true; text: root.dueLabel(root.selectedDay) + "  (" + root.selectedDay + ")"; style: Theme.type.labelMedium; color: Theme.color.fgSurfaceVariant }
            ThemedText {
                text: Lang.t("ui.todo.showAll")
                style: Theme.type.labelMedium
                color: Theme.color.primary
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.dayCleared() }
            }
        }

        // ---- список ----
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: Theme.space.listGap
                boundsBehavior: Flickable.StopAtBounds
                model: ScriptModel { values: root.items; objectProp: "id" }

                add: Transition {
                    MotionAnimation { property: "opacity"; from: 0; to: 1; role: "enter" }
                    MotionAnimation { property: "scale"; from: 0.92; to: 1; role: "expand" }
                }
                remove: Transition { MotionAnimation { property: "opacity"; to: 0; role: "exit" } }
                displaced: Transition { MotionAnimation { properties: "y"; role: "move" } }

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool isFirst: index === 0
                    readonly property bool isLast: index === list.count - 1
                    readonly property bool overdue: !modelData.done && modelData.due && modelData.due < TodoService.today()
                    property bool editing: false

                    width: list.width
                    implicitHeight: Math.max(Theme.components.dp(48), rowL.implicitHeight + Theme.space.sm * 2)
                    height: implicitHeight
                    color: Theme.color.surfaceContainerHigh
                    topLeftRadius: isFirst ? Theme.shape.md : Theme.shape.listInner
                    topRightRadius: isFirst ? Theme.shape.md : Theme.shape.listInner
                    bottomLeftRadius: isLast ? Theme.shape.md : Theme.shape.listInner
                    bottomRightRadius: isLast ? Theme.shape.md : Theme.shape.listInner
                    Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
                    Behavior on topRightRadius { MotionAnimation { role: "morph" } }
                    Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
                    Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }

                    HoverHandler { id: hov }

                    RowLayout {
                        id: rowL
                        anchors {
                            left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                            leftMargin: Theme.space.md; rightMargin: Theme.space.sm
                        }
                        spacing: Theme.space.md

                        TodoCheck {
                            checked: row.modelData.done
                            onToggled: TodoService.toggle(row.modelData.id)
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(txt.implicitHeight, editInput.implicitHeight)
                            ThemedText {
                                id: txt
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !row.editing
                                text: row.modelData.text
                                style: Theme.type.bodyMedium
                                color: row.modelData.done ? Theme.color.fgSurfaceVariant : Theme.color.fgSurface
                                font.strikeout: row.modelData.done
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                opacity: row.modelData.done ? 0.65 : 1
                                Behavior on opacity { MotionAnimation { role: "stateChange" } }
                                MouseArea {
                                    anchors.fill: parent
                                    onDoubleClicked: { editInput.text = row.modelData.text; row.editing = true; editInput.forceActiveFocus(); editInput.selectAll() }
                                }
                            }
                            TextInput {
                                id: editInput
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                visible: row.editing
                                color: Theme.color.fgSurface
                                font.family: Theme.type.bodyMedium.family
                                font.pixelSize: Theme.type.bodyMedium.size
                                selectByMouse: true
                                clip: true
                                onAccepted: { TodoService.edit(row.modelData.id, text); row.editing = false }
                                Keys.onEscapePressed: e => { row.editing = false; e.accepted = true }
                                onActiveFocusChanged: if (!activeFocus && row.editing) row.editing = false
                            }
                        }

                        // дата
                        Rectangle {
                            visible: !!row.modelData.due
                            implicitHeight: Theme.components.dp(22)
                            implicitWidth: dl.implicitWidth + Theme.space.md
                            radius: height / 2
                            color: row.overdue ? Theme.color.errorContainer
                                 : row.modelData.due === TodoService.today() ? Theme.color.primaryContainer
                                 : Theme.color.surfaceContainerHighest
                            ThemedText {
                                id: dl
                                anchors.centerIn: parent
                                text: root.dueLabel(row.modelData.due)
                                style: Theme.type.labelSmall
                                color: row.overdue ? Theme.color.fgErrorContainer
                                     : row.modelData.due === TodoService.today() ? Theme.color.fgPrimaryContainer
                                     : Theme.color.fgSurfaceVariant
                            }
                        }

                        // видалити (при наведенні)
                        Rectangle {
                            Layout.preferredWidth: Theme.components.dp(28)
                            Layout.preferredHeight: Theme.components.dp(28)
                            radius: delMa.pressed ? Theme.shape.iconButtonPressed : height / 2
                            color: delMa.containsMouse ? Theme.color.errorContainer : "transparent"
                            opacity: hov.hovered ? 1 : 0
                            Behavior on opacity { MotionAnimation { role: "hover" } }
                            Behavior on radius { MotionAnimation { role: "morph" } }
                            Behavior on color { MotionColorAnimation { role: "hover" } }
                            Text {
                                anchors.centerIn: parent
                                text: "\ue872"                                                  // delete
                                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                                color: delMa.containsMouse ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
                            }
                            MouseArea { id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: TodoService.remove(row.modelData.id) }
                        }
                    }
                }
            }

            // порожній стан
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.items.length === 0
                spacing: Theme.space.sm
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: Theme.components.dp(64)
                    implicitHeight: implicitWidth
                    radius: Theme.shape.radius("lg", height)
                    color: Theme.color.secondaryContainer
                    Text {
                        anchors.centerIn: parent
                        text: "\ue86c"                                                          // task_alt
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconXL }
                        color: Theme.color.fgSecondaryContainer
                    }
                }
                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.selectedDay ? Lang.t("ui.todo.emptyDay") : Lang.t("ui.todo.empty")
                    style: Theme.type.bodyMedium
                    color: Theme.color.fgSurfaceVariant
                }
            }
        }
    }
}
