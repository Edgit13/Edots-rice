import "root:/theme"
import "root:/settings"
import "root:/services"
import "root:/modules/workspace"
import QtQuick
import QtQuick.Layouts

// WorkspacesTab — огляд тегів і активного вікна (M3 Expressive).
// Теги малюються тим самим WorkspaceStrip, що й у барі, але більші.
Item {
    id: root

    readonly property var monitorNames: Object.keys(MangoService.monitors)
    readonly property var fc: MangoService.focusedClient
    readonly property bool hasClient: !!fc && fc.id !== null && fc.id !== undefined

    function stats(mon) {
        const n = MangoService.tagCount(mon)
        let occ = 0, clients = 0
        for (let i = 1; i <= n; i++) {
            const t = MangoService.tag(mon, i)
            if (t.occupied) occ++
            clients += t.clients || 0
        }
        return { occupied: occ, clients: clients, active: MangoService.activeIndex(mon) }
    }

    // кнопка-дія: коло/пігулка → при натисканні морф у менший радіус
    component ActionButton: Rectangle {
        id: btn
        property string icon: ""
        property string label: ""
        property string tone: "tonal"        // tonal | error | toggle
        property bool toggled: false
        signal clicked()

        readonly property color fg: tone === "error" ? (Theme.settings.nothing ? ThemeNothing.red : Theme.color.fgErrorContainer)
                                  : (tone === "toggle" && !toggled) ? Theme.color.fgSurfaceVariant
                                  : (Theme.settings.nothing ? Theme.color.fgSurface : Theme.color.fgSecondaryContainer)

        implicitHeight: Theme.components.buttonS
        implicitWidth: row.implicitWidth + Theme.space.xl
        readonly property bool nothing: Theme.settings.nothing
        color: nothing ? "transparent"
             : tone === "error" ? Theme.color.errorContainer
             : (tone === "toggle" && !toggled) ? Theme.color.surfaceContainerHighest
             : Theme.color.secondaryContainer
        // Nothing: контурні кнопки; error — червоний контур, toggled — яскравіший
        border.width: nothing ? 1 : 0
        border.color: tone === "error" ? Qt.rgba(ThemeNothing.red.r, ThemeNothing.red.g, ThemeNothing.red.b, 0.7)
                    : Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, toggled ? 0.75 : 0.26)
        radius: bma.pressed ? Theme.shape.radius("md", height)
              : toggled ? Theme.shape.radius("lg", height)
              : height / 2
        Behavior on radius { MotionAnimation { role: "morph" } }
        Behavior on color { MotionColorAnimation { role: "hover" } }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: btn.fg
            opacity: bma.pressed ? Theme.components.statePressed
                   : bma.containsMouse ? Theme.components.stateHover : 0
            Behavior on opacity { MotionAnimation { role: "hover" } }
        }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.space.xs
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.icon
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                color: btn.fg
            }
            ThemedText {
                visible: btn.label.length > 0
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                style: Theme.type.labelLarge
                color: btn.fg
            }
        }
        MouseArea {
            id: bma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component InfoChip: Rectangle {
        id: chip
        property string text: ""
        property bool accent: false
        implicitHeight: Theme.components.chipHeight
        implicitWidth: chipText.implicitWidth + Theme.space.xl
        radius: Theme.shape.chip
        color: Theme.settings.nothing ? "transparent"
             : accent ? Theme.color.primaryContainer : Theme.color.surfaceContainerHighest
        border.width: Theme.settings.nothing ? 1 : 0
        border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, chip.accent ? 0.65 : 0.22)
        ThemedText {
            id: chipText
            anchors.centerIn: parent
            text: chip.text
            style: Theme.type.labelLarge
            color: Theme.settings.nothing ? (chip.accent ? Theme.color.fgSurface : Theme.color.fgSurfaceVariant)
                 : chip.accent ? Theme.color.fgPrimaryContainer : Theme.color.fgSurfaceVariant
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.lg
        spacing: Theme.space.lg

        // ---- активне вікно ----
        DashCard {
            visible: root.hasClient
            Layout.fillWidth: true
            title: Lang.t("ui.ws.active")

            RowLayout {
                width: parent.width
                spacing: Theme.space.md

                // аватар: форма морфиться, коли вікно floating
                Rectangle {
                    Layout.preferredWidth: Theme.components.dp(48)
                    Layout.preferredHeight: Theme.components.dp(48)
                    radius: root.fc && root.fc.floating ? Theme.shape.radius("lg", height) : height / 2
                    color: Theme.color.primaryContainer
                    Behavior on radius { MotionAnimation { role: "morph" } }
                    ThemedText {
                        anchors.centerIn: parent
                        text: {
                            const id = root.fc ? (root.fc.appid || "") : ""
                            const last = id.split(".").pop()
                            return last.length > 0 ? last.charAt(0).toUpperCase() : "?"
                        }
                        style: Theme.type.titleMedium
                        emphasized: true
                        color: Theme.color.fgPrimaryContainer
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    ThemedText {
                        Layout.fillWidth: true
                        text: root.fc && root.fc.title ? root.fc.title : "—"
                        style: Theme.type.bodyLarge
                        elide: Text.ElideRight
                    }
                    ThemedText {
                        Layout.fillWidth: true
                        text: root.fc ? (root.fc.appid || "") : ""
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                        elide: Text.ElideRight
                    }
                }

                ActionButton {
                    icon: "\ue8aa"
                    label: Lang.t("ui.ws.floating")
                    tone: "toggle"
                    toggled: !!root.fc && !!root.fc.floating
                    onClicked: MangoService.toggleFloatingFocusedClient()
                }
                ActionButton {
                    icon: "\ue5cd"
                    label: Lang.t("ui.ws.close")
                    tone: "error"
                    onClicked: MangoService.closeFocusedClient()
                }
            }
        }

        // ---- монітори ----
        Repeater {
            model: root.monitorNames
            DashCard {
                id: monCard
                required property string modelData
                readonly property var st: root.stats(modelData)
                Layout.fillWidth: true
                title: modelData

                ColumnLayout {
                    width: parent.width
                    spacing: Theme.space.md

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: strip.implicitHeight
                        WorkspaceStrip {
                            id: strip
                            anchors.horizontalCenter: parent.horizontalCenter
                            monitor: monCard.modelData
                            itemSize: Theme.components.buttonS
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Theme.space.sm
                        InfoChip { text: Lang.tn("ui.ws.tag", monCard.st.active); accent: true; visible: monCard.st.active > 0 }
                        InfoChip { text: Lang.tn("ui.ws.occupied", monCard.st.occupied) }
                        InfoChip { text: Lang.tn("ui.ws.windows", monCard.st.clients) }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
