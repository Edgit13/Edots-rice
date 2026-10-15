pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/settings"
import "root:/services"
import QtQuick
import QtQuick.Layouts

// NotificationCard — M3 Expressive картка сповіщення (спливаюча і в центрі).
//  • свайп вбік — прибрати; тап — дія за замовчуванням / розгорнути
//  • popup: тінь, прогрес таймера внизу, пауза при hover; critical — errorContainer
//  • topR/bottomR — радіуси для «connected list» у центрі
Item {
    id: card

    required property var notif
    property bool popup: false
    property bool expanded: false
    property real topR: Theme.shape.cardLarge
    property real bottomR: Theme.shape.cardLarge
    signal removed()

    implicitWidth: Theme.components.dp(380)
    implicitHeight: surface.height

    readonly property bool critical: notif.urgency === 2

    // у popup показуємо всі дії крім default (він = тап); у центрі — усі
    readonly property var shownActions: {
        const out = []
        for (let i = 0; i < notif.actions.length; i++) {
            const a = notif.actions[i]
            if (a.id === "default") { if (!card.popup) out.push({ id: a.id, text: a.text || Lang.t("ui.notif.open") }) }
            else out.push(a)
        }
        return out
    }

    function activate() {
        if (card.popup) {
            if (notif.hasDefault()) { notif.invoke("default"); card.removed() }
            else notif.popup = false                 // сховати у центр
        } else card.expanded = !card.expanded
    }
    function release() {
        if (Math.abs(surface.x) > surface.width * 0.32) {
            surface.flying = true
            flyOut.to = (surface.x > 0 ? 1 : -1) * surface.width * 1.15
            flyOut.start()
        } else surface.x = 0
    }

    HoverHandler {
        id: hover
        enabled: card.popup
        onHoveredChanged: card.notif.paused = hovered
    }

    Item {
        id: surface
        width: card.width
        height: bg.height
        property bool flying: false
        opacity: 1 - Math.min(1, Math.abs(x) / (width * 0.9)) * 0.85

        Behavior on x { enabled: !drag.active && !surface.flying; MotionAnimation { role: "morph" } }
        MotionAnimation { id: flyOut; target: surface; property: "x"; role: "exit"; onFinished: card.removed() }

        DragHandler {
            id: drag
            target: surface
            xAxis.enabled: true
            yAxis.enabled: false
            onActiveChanged: if (!active) card.release()
        }
        TapHandler { onTapped: card.activate() }

        ElevationShadow {
            visible: card.popup
            anchors.fill: bg
            level: 0.5
            radius: Theme.shape.cardLarge
            color: card.critical ? Theme.color.errorContainer : Theme.color.surfaceContainerHigh
        }

        Rectangle {
            id: bg
            width: parent.width
            height: content.implicitHeight + Theme.space.md * 2
            color: card.critical ? Theme.color.errorContainer : Theme.color.surfaceContainerHigh
            topLeftRadius: card.topR
            topRightRadius: card.topR
            bottomLeftRadius: card.bottomR
            bottomRightRadius: card.bottomR
            Behavior on color { MotionColorAnimation { role: "stateChange" } }
            Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
            Behavior on topRightRadius { MotionAnimation { role: "morph" } }
            Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }
            Behavior on bottomRightRadius { MotionAnimation { role: "morph" } }
            Behavior on height { MotionAnimation { role: "morph" } }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Theme.space.md
                }
                spacing: Theme.space.sm

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.md

                    NotifIcon {
                        Layout.preferredWidth: Theme.components.dp(40)
                        Layout.preferredHeight: Theme.components.dp(40)
                        Layout.alignment: Qt.AlignTop
                        notif: card.notif
                        critical: card.critical
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.space.xs
                            ThemedText {
                                Layout.fillWidth: true
                                text: card.notif.appName
                                style: Theme.type.labelSmall
                                color: card.critical ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
                                elide: Text.ElideRight
                            }
                            ThemedText {
                                text: NotificationService.rel(card.notif.time)
                                style: Theme.type.labelSmall
                                color: card.critical ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
                            }
                        }
                        ThemedText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: card.notif.summary
                            style: Theme.type.titleSmall
                            emphasized: true
                            color: card.critical ? Theme.color.fgErrorContainer : Theme.color.fgSurface
                            elide: Text.ElideRight
                            maximumLineCount: card.expanded ? 3 : 1
                            wrapMode: Text.Wrap
                        }
                        ThemedText {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: card.notif.body
                            style: Theme.type.bodyMedium
                            color: card.critical ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
                            textFormat: Text.StyledText
                            linkColor: Theme.color.primary
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                            maximumLineCount: card.expanded ? 14 : (card.popup ? 3 : 2)
                            onLinkActivated: link => Qt.openUrlExternally(link)
                        }
                    }

                    // закрити
                    Rectangle {
                        id: closeBtn
                        Layout.preferredWidth: Theme.components.dp(28)
                        Layout.preferredHeight: Theme.components.dp(28)
                        Layout.alignment: Qt.AlignTop
                        radius: closeMa.pressed ? Theme.shape.iconButtonPressed : height / 2
                        color: "transparent"
                        opacity: card.popup ? (hover.hovered ? 1 : 0) : 0.8
                        Behavior on radius { MotionAnimation { role: "morph" } }
                        Behavior on opacity { MotionAnimation { role: "hover" } }
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.color.fgSurface
                            opacity: closeMa.pressed ? Theme.components.statePressed
                                   : closeMa.containsMouse ? Theme.components.stateHover : 0
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "\ue5cd"
                            color: card.critical ? Theme.color.fgErrorContainer : Theme.color.fgSurfaceVariant
                            font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                        }
                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.removed()
                        }
                    }
                }

                // дії
                Flow {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.components.dp(40) + Theme.space.md
                    visible: card.shownActions.length > 0
                    spacing: Theme.space.xs

                    Repeater {
                        model: card.shownActions
                        Rectangle {
                            id: act
                            required property var modelData
                            implicitHeight: Theme.components.dp(32)
                            implicitWidth: actTxt.implicitWidth + Theme.space.xl
                            radius: actMa.pressed ? Theme.shape.buttonPressed : height / 2
                            color: card.critical ? Theme.color.error : Theme.color.secondaryContainer
                            Behavior on radius { MotionAnimation { role: "morph" } }
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: card.critical ? Theme.color.fgError : Theme.color.fgSecondaryContainer
                                opacity: actMa.pressed ? Theme.components.statePressed
                                       : actMa.containsMouse ? Theme.components.stateHover : 0
                            }
                            ThemedText {
                                id: actTxt
                                anchors.centerIn: parent
                                text: act.modelData.text
                                style: Theme.type.labelLarge
                                color: card.critical ? Theme.color.fgError : Theme.color.fgSecondaryContainer
                            }
                            MouseArea {
                                id: actMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { card.notif.invoke(act.modelData.id); card.removed() }
                            }
                        }
                    }
                }
            }

            // прогрес таймера (popup)
            Rectangle {
                visible: card.popup && card.notif.totalMs > 0
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.components.dp(5)
                x: Theme.space.lg
                height: Theme.components.dp(3)
                radius: height / 2
                width: (parent.width - Theme.space.lg * 2) * Math.max(0, card.notif.remainingMs / card.notif.totalMs)
                color: card.critical ? Theme.color.error : Theme.color.primary
                opacity: 0.8
                Behavior on width { NumberAnimation { duration: 40 } }
            }
        }
    }
}
