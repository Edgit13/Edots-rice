pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings/material"
import Quickshell
import QtQuick
import QtQuick.Layouts

// NotificationGroup — сповіщення одного застосунку: заголовок + connected list карток;
// у згорнутому вигляді — найновіша картка і «стопка» під нею.
ColumnLayout {
    id: group
    required property var modelData
    readonly property string gkey: modelData.key
    readonly property var gItems: NotificationService.itemsFor(gkey)
    property bool expanded: false

    Layout.fillWidth: true
    spacing: Theme.space.xs

    // ---- заголовок ----
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Theme.space.sm
        spacing: Theme.space.sm

        ThemedText {
            Layout.fillWidth: true
            text: group.gkey
            style: Theme.type.labelLarge
            emphasized: true
            color: Theme.color.primary
            elide: Text.ElideRight
        }
        Rectangle {
            visible: group.gItems.length > 1
            implicitWidth: cnt.implicitWidth + Theme.space.md
            implicitHeight: Theme.components.dp(20)
            radius: height / 2
            color: Theme.color.secondaryContainer
            ThemedText {
                id: cnt
                anchors.centerIn: parent
                text: group.gItems.length
                style: Theme.type.labelSmall
                color: Theme.color.fgSecondaryContainer
            }
        }
        MaterialIconButton {
            visible: group.gItems.length > 1
            icon: group.expanded ? "expand_less" : "expand_more"
            width: Theme.components.dp(32); height: width
            onClicked: group.expanded = !group.expanded
        }
        MaterialIconButton {
            icon: "close"
            width: Theme.components.dp(32); height: width
            onClicked: NotificationService.clearApp(group.gkey)
        }
    }

    // ---- картки ----
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.space.listGap

        Repeater {
            model: ScriptModel { values: group.gItems }

            Item {
                id: slot
                required property var modelData
                required property int index
                readonly property bool shown: group.expanded || index === 0
                readonly property int lastShown: group.expanded ? group.gItems.length - 1 : 0

                Layout.fillWidth: true
                implicitHeight: shown ? card.implicitHeight : 0
                visible: implicitHeight > 0.5
                clip: true
                Behavior on implicitHeight { MotionAnimation { role: "morph" } }

                NotificationCard {
                    id: card
                    width: parent.width
                    notif: slot.modelData
                    topR: slot.index === 0 ? Theme.shape.cardLarge : Theme.shape.listInner
                    bottomR: slot.index === slot.lastShown ? Theme.shape.cardLarge : Theme.shape.listInner
                    opacity: slot.shown ? 1 : 0
                    Behavior on opacity { MotionAnimation { role: "fade" } }
                    onRemoved: NotificationService.dismiss(slot.modelData)
                }
            }
        }

        // «стопка» під згорнутою групою
        Item {
            Layout.fillWidth: true
            implicitHeight: (!group.expanded && group.gItems.length > 1) ? Theme.components.dp(12) : 0
            visible: implicitHeight > 0.5
            clip: true
            Behavior on implicitHeight { MotionAnimation { role: "morph" } }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.components.dp(-8)
                width: parent.width * 0.93
                height: Theme.components.dp(16)
                radius: Theme.shape.md
                color: Theme.color.surfaceContainerHigh
                opacity: 0.7
            }
            Rectangle {
                visible: group.gItems.length > 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: Theme.components.dp(-2)
                width: parent.width * 0.86
                height: Theme.components.dp(12)
                radius: Theme.shape.md
                color: Theme.color.surfaceContainerHigh
                opacity: 0.45
            }
        }
    }
}
