import "root:/theme"
import "root:/services"
import "root:/notifications"
import "root:/modules/common"
import QtQuick

// NotificationModule — M3 Expressive: дзвіночок, що при новому сповіщенні розгортається у пігулку
// з іконкою застосунку, заголовком і текстом (+ прогрес таймера), а потім згортається назад.
// ЛКМ: центр сповіщень · ПКМ: сховати поточне / «Не турбувати» · СКМ: «Не турбувати».
BarModule {
    id: root

    readonly property int count: NotificationService.count
    readonly property bool dnd: NotificationService.dnd
    readonly property var live: NotificationService.barLive ? NotificationService.latest : null
    readonly property bool expanded: !!live && !vertical

    // тримаємо останнє для анімації згортання
    property var shownItem: null
    onLiveChanged: if (live) shownItem = live
    readonly property bool critical: !!shownItem && shownItem.urgency === 2

    readonly property bool active: count > 0 && !dnd
    readonly property string glyph: dnd ? "\ue7f6" : (count > 0 ? "\ue7f5" : "\ue7f4")

    function esc(t) { return String(t || "").replace(/<[^>]*>/g, "").replace(/&/g, "&amp;").replace(/</g, "&lt;") }

    readonly property real bellW: root.count > 0 ? (bellRow.implicitWidth + Theme.space.sm * 2) : cross
    readonly property real liveW: Math.min(Theme.components.dp(340), liveRow.implicitWidth + Theme.space.md * 2)

    animate: true
    widthRole: expanded ? "expand" : "collapse"
    contentW: expanded ? liveW : bellW
    contentH: (root.count > 0 || live) ? (contentCol.implicitHeight + Theme.space.xs * 2) : cross

    // колір вмісту залежить від стану плашки (є непрочитані / критичне / DND)
    readonly property bool tinted: (expanded && critical) || dnd
    readonly property color fg: tinted ? Theme.color.fgErrorContainer
                              : (expanded || active) ? Theme.color.fgSecondaryContainer
                              : Theme.color.fgSurfaceVariant

    HoverHandler { onHoveredChanged: if (root.live) root.live.paused = hovered }

    BarButton {
        id: btn
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        pressScale: 0.96
        fillColor: root.tinted ? Theme.color.errorContainer
                 : (root.expanded || root.active) ? Theme.color.secondaryContainer
                 : "transparent"
        stateColor: root.tinted ? Theme.color.fgErrorContainer
                  : (root.expanded || root.active) ? Theme.color.fgSecondaryContainer
                  : Theme.color.fgSurface
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.live) NotificationService.hidePopup(root.live)
                else NotificationService.setDnd(!NotificationService.dnd)
            } else if (mouse.button === Qt.MiddleButton) {
                NotificationService.setDnd(!NotificationService.dnd)
            } else NotificationService.toggleCenter()
        }

        // ---- дзвіночок (спокій) ----
        Row {
            id: bellRow
            visible: !root.vertical
            anchors.centerIn: parent
            spacing: Theme.space.xs
            opacity: root.expanded ? 0 : 1
            Behavior on opacity { MotionAnimation { role: "fade" } }

            BarIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: root.glyph
                color: root.fg
                Behavior on color { MotionColorAnimation { role: "hover" } }
            }
            ThemedText {
                visible: root.count > 0
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.count)
                style: Theme.type.labelSmall
                emphasized: true
                color: root.fg
            }
        }

        // ---- живе сповіщення ----
        Row {
            id: liveRow
            visible: !root.vertical && opacity > 0.01
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.space.sm
            spacing: Theme.space.sm
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { MotionAnimation { role: root.expanded ? "enter" : "fade" } }

            Loader {
                anchors.verticalCenter: parent.verticalCenter
                active: !!root.shownItem
                sourceComponent: NotifIcon {
                    notif: root.shownItem
                    critical: root.critical
                    width: root.cross - Theme.space.sm
                    height: width
                }
            }
            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!root.shownItem
                textFormat: Text.StyledText
                text: root.shownItem
                      ? ("<b>" + root.esc(root.shownItem.summary) + "</b>"
                         + (root.shownItem.body ? "&nbsp;&nbsp;" + root.esc(root.shownItem.body) : ""))
                      : ""
                style: Theme.type.labelMedium
                color: root.fg
                elide: Text.ElideRight
                maximumLineCount: 1
                width: Math.min(implicitWidth, Theme.components.dp(340) - root.cross - Theme.space.md * 3)
            }
        }

        // ---- вертикальний бар ----
        Column {
            id: contentCol
            visible: root.vertical
            anchors.centerIn: parent
            spacing: 2

            Loader {
                anchors.horizontalCenter: parent.horizontalCenter
                active: root.vertical && !!root.live
                visible: active
                sourceComponent: NotifIcon {
                    notif: root.live
                    critical: root.live && root.live.urgency === 2
                    width: root.cross - Theme.space.sm
                    height: width
                }
            }
            BarIcon {
                visible: !root.live
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.glyph
                color: root.fg
            }
            Rectangle {
                visible: root.count > 0 && !root.live
                anchors.horizontalCenter: parent.horizontalCenter
                width: 6; height: 6
                radius: 3
                color: Theme.color.error
            }
        }

        // ---- прогрес таймера ----
        Rectangle {
            visible: root.expanded && !!root.shownItem && root.shownItem.totalMs > 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.components.dp(3)
            x: btn.cornerRadius * 0.6
            height: Theme.components.dp(2)
            radius: height / 2
            width: root.shownItem && root.shownItem.totalMs > 0
                   ? (btn.width - btn.cornerRadius * 1.2) * Math.max(0, root.shownItem.remainingMs / root.shownItem.totalMs) : 0
            color: root.critical ? Theme.color.error : Theme.color.primary
            opacity: 0.85
            Behavior on width { NumberAnimation { duration: 40 } }
        }
    }
}
