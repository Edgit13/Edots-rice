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
    property string newTime: ""                    // "HH:MM" — разом із датою створює нагадування (utimer)
    signal dayCleared()

    readonly property var items: TodoService.list(filter, selectedDay)
    // нагадування (utimer): вибраного дня або найближчі; ті, що належать справам, не дублюємо
    readonly property var reminders: TimerService.listFor(selectedDay, 3).filter(t => !TodoService.timerIds[t.id])
    readonly property var filters: ["active", "all", "done"]

    onSelectedDayChanged: newDue = selectedDay

    function dueLabel(due) {
        if (!due) return ""
        if (due === TodoService.today()) return Lang.t("ui.todo.today")
        if (due === TodoService.tomorrow()) return Lang.t("ui.todo.tomorrow")
        const p = due.split("-")
        return p[2] + "." + p[1]
    }
    readonly property bool timeValid: /^([01]?\d|2[0-3]):[0-5]\d$/.test(newTime)
    function addNow() {
        if (input.text.trim().length === 0) return
        TodoService.add(input.text, newDue, (newDue && timeValid) ? newTime : "")
        input.text = ""
        newTime = ""
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
                color: Theme.settings.nothing ? "transparent" : Theme.color.primaryContainer
                border.width: Theme.settings.nothing ? 1 : 0
                border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.4)
                ThemedText { id: cnt; anchors.centerIn: parent; text: TodoService.activeCount; style: Theme.type.labelSmall; emphasized: true; color: Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.fgPrimaryContainer }
            }
            Rectangle {
                visible: TodoService.overdueCount > 0
                implicitWidth: od.implicitWidth + Theme.space.lg
                implicitHeight: Theme.components.dp(22)
                radius: height / 2
                color: Theme.settings.nothing ? "transparent" : Theme.color.errorContainer
                border.width: Theme.settings.nothing ? 1 : 0
                border.color: Qt.rgba(ThemeNothing.red.r, ThemeNothing.red.g, ThemeNothing.red.b, 0.7)
                ThemedText { id: od; anchors.centerIn: parent; text: Lang.t("ui.todo.overdue") + " " + TodoService.overdueCount; style: Theme.type.labelSmall; emphasized: true; color: Theme.settings.nothing ? ThemeNothing.red : Theme.color.fgErrorContainer }
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
            color: Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainerHighest
            border.width: Theme.settings.nothing ? 1 : (input.activeFocus ? Theme.components.dp(2) : 0)
            border.color: Theme.settings.nothing ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, input.activeFocus ? 0.75 : 0.25) : Theme.color.primary
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
                    color: root.newDue && !Theme.settings.nothing ? Theme.color.secondaryContainer : "transparent"
                    border.width: Theme.settings.nothing ? 1 : (root.newDue ? 0 : 1)
                    border.color: Theme.settings.nothing ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, root.newDue ? 0.7 : 0.25) : Theme.color.outlineVariant
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

                // час нагадування (лише коли обрано дату): 13:00
                Rectangle {
                    visible: !!root.newDue
                    implicitHeight: Theme.components.dp(30)
                    implicitWidth: Theme.components.dp(64)
                    radius: height / 2
                    color: Theme.settings.nothing ? "transparent"
                         : root.timeValid ? Theme.color.secondaryContainer : "transparent"
                    border.width: Theme.settings.nothing ? 1 : (root.timeValid ? 0 : 1)
                    border.color: Theme.settings.nothing
                        ? Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, root.timeValid ? 0.7 : 0.25)
                        : Theme.color.outlineVariant
                    Text {
                        id: clockIco
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.space.sm
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\ue855"                                                    // alarm
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                        color: root.timeValid && !Theme.settings.nothing ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                    }
                    TextInput {
                        id: timeInput
                        anchors.left: clockIco.right
                        anchors.leftMargin: 4
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.space.sm
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.newTime
                        onTextChanged: root.newTime = text
                        color: Theme.color.fgSurface
                        font.family: Theme.type.mono
                        font.pixelSize: Theme.type.labelMedium.size
                        maximumLength: 5
                        selectByMouse: true
                        validator: RegularExpressionValidator { regularExpression: /^[0-9:]{0,5}$/ }
                        onAccepted: root.addNow()
                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: timeInput.text.length === 0
                            text: "13:00"
                            style: Theme.type.labelMedium
                            color: Theme.color.fgSurfaceVariant
                            opacity: 0.6
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

        // ---- нагадування (utimer): вибраного дня або найближчі ----
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.reminders.length > 0
            spacing: Theme.space.xs

            Repeater {
                model: root.reminders
                delegate: Rectangle {
                    id: rem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: Theme.components.dp(36)
                    radius: Theme.shape.md
                    color: Theme.settings.nothing ? "transparent" : Theme.color.tertiaryContainer
                    border.width: Theme.settings.nothing ? 1 : 0
                    border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.2)
                    readonly property color fg: Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.fgTertiaryContainer

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.space.md
                        anchors.rightMargin: Theme.space.xs
                        spacing: Theme.space.sm
                        Text {
                            text: "\ue855"                                                // alarm
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                            color: rem.modelData.state === "ringing" ? Theme.color.error : rem.fg
                        }
                        ThemedText {
                            text: (root.selectedDay ? TimerService.hm(rem.modelData.at) : TimerService.short(rem.modelData.at))
                            style: Theme.type.labelMedium
                            emphasized: true
                            color: rem.fg
                        }
                        ThemedText {
                            Layout.fillWidth: true
                            text: rem.modelData.message
                            style: Theme.type.bodySmall
                            color: rem.fg
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                        Rectangle {
                            Layout.preferredWidth: Theme.components.dp(26)
                            Layout.preferredHeight: Theme.components.dp(26)
                            radius: height / 2
                            color: remX.containsMouse ? Qt.rgba(rem.fg.r, rem.fg.g, rem.fg.b, 0.14) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: "\ue5cd"                                            // close
                                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                                color: rem.fg
                            }
                            MouseArea {
                                id: remX
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: TimerService.cancel(rem.modelData.id)
                            }
                        }
                    }
                }
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
                            color: Theme.settings.nothing ? "transparent"
                                 : row.overdue ? Theme.color.errorContainer
                                 : row.modelData.due === TodoService.today() ? Theme.color.primaryContainer
                                 : Theme.color.surfaceContainerHighest
                            border.width: Theme.settings.nothing ? 1 : 0
                            border.color: row.overdue ? Qt.rgba(ThemeNothing.red.r, ThemeNothing.red.g, ThemeNothing.red.b, 0.7)
                                                      : Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, row.modelData.due === TodoService.today() ? 0.6 : 0.2)
                            ThemedText {
                                id: dl
                                anchors.centerIn: parent
                                text: root.dueLabel(row.modelData.due) + (row.modelData.time ? "  \u23F0 " + row.modelData.time : "")
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
                    color: Theme.settings.nothing ? "transparent" : Theme.color.secondaryContainer
                    border.width: Theme.settings.nothing ? 1 : 0
                    border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.22)
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
