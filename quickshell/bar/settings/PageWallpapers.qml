pragma ComponentBehavior: Bound
import "root:/theme"
import "material"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property int current: 0
    property int total: 0
    property string state: "idle"
    property string statusMessage: ""
    property var categoryCounts: ({})
    readonly property string home: Quickshell.env("HOME")
    readonly property string statusPath: home + "/.cache/quickshell/wallpaper-colors-status.json"
    readonly property int percent: total > 0 ? Math.round(current * 100 / total) : 0

    function localizedMessage(d) {
        const st = d.state || "idle"
        const msg = d.message || ""
        if (st === "done") return Number(d.total || 0) === 0 ? Lang.t("wall.msg.none") : Lang.t("wall.msg.done")
        if (st === "running") return Number(d.current || 0) === 0 ? Lang.t("wall.msg.starting") : msg   // msg = file name
        if (st === "error") return msg.indexOf("Wallpaper folder not found") === 0 ? Lang.t("wall.msg.noFolder") : msg
        return msg
    }

    function readStatus(raw) {
        if (!raw || !raw.trim()) return
        try {
            const d = JSON.parse(raw)
            state = d.state || "idle"
            current = Number(d.current || 0)
            total = Number(d.total || 0)
            statusMessage = localizedMessage(d)
            categoryCounts = d.categories || ({})
        } catch (e) {}
    }

    FileView {
        id: statusFile
        path: root.statusPath
        watchChanges: true
        printErrors: false
        onTextChanged: root.readStatus(text())
        Component.onCompleted: reload()
    }
    // Some filesystem backends do not emit a change notification for atomic
    // rename writes. Poll while the scan is active so completion always appears.
    Timer {
        interval: 400
        repeat: true
        running: root.state === "running"
        onTriggered: statusFile.reload()
    }
    Process {
        id: scanProcess
        command: ["python3", root.home + "/.config/quickshell/scripts/wallpaper_color_index.py"]
        onExited: (exitCode, exitStatus) => {
            statusFile.reload()
            if (exitCode !== 0 && root.state !== "error" && root.state !== "cancelled") {
                root.state = "error"
                root.statusMessage = Lang.t("wall.msg.exitError").replace("{code}", exitCode)
            } else if (exitCode === 0) {
                // Give the status file one more read after the process has flushed it.
                statusFile.reload()
                if (root.state === "running") {
                    root.state = "done"
                    root.current = root.total
                    root.statusMessage = Lang.t("wall.msg.done")
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space.lg

        ThemedText {
            Layout.fillWidth: true
            text: Lang.t("wall.title")
            style: Theme.type.headlineMedium
        }
        ThemedText {
            Layout.fillWidth: true
            text: Lang.t("wall.intro")
            style: Theme.type.bodyMedium
            color: Theme.color.fgSurfaceVariant
            wrapMode: Text.Wrap
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: infoColumn.implicitHeight + Theme.space.xl * 2
            radius: Theme.shape.cardLarge
            color: Theme.color.surfaceContainer
            border.width: 1
            border.color: Theme.color.outlineVariant
            ColumnLayout {
                id: infoColumn
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space.xl }
                spacing: Theme.space.md
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.md
                    Rectangle {
                        Layout.preferredWidth: Theme.components.dp(52)
                        Layout.preferredHeight: Theme.components.dp(52)
                        radius: Theme.shape.card
                        color: Theme.color.secondaryContainer
                        Text { anchors.centerIn: parent; text: "palette"; color: Theme.color.fgSecondaryContainer; font.family: Theme.type.icons; font.pixelSize: Theme.type.iconL }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.xxs
                        ThemedText { Layout.fillWidth: true; text: Lang.t("wall.autoTitle"); style: Theme.type.titleMedium }
                        ThemedText { Layout.fillWidth: true; text: Lang.t("wall.autoList"); style: Theme.type.bodySmall; color: Theme.color.fgSurfaceVariant; wrapMode: Text.Wrap }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    radius: Theme.shape.card
                    color: Theme.color.tertiaryContainer
                    implicitHeight: warningRow.implicitHeight + Theme.space.md * 2
                    RowLayout {
                        id: warningRow
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.space.md }
                        spacing: Theme.space.sm
                        Text { text: "schedule"; color: Theme.color.fgTertiaryContainer; font.family: Theme.type.icons; font.pixelSize: Theme.type.iconM }
                        ThemedText { Layout.fillWidth: true; text: Lang.t("wall.warn"); style: Theme.type.bodyMedium; color: Theme.color.fgTertiaryContainer; wrapMode: Text.Wrap }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.sm
                    MaterialButton {
                        text: root.state === "running" ? Lang.t("wall.btn.scanning") : (root.state === "done" ? Lang.t("wall.btn.rescan") : Lang.t("wall.btn.analyze"))
                        icon: root.state === "running" ? "hourglass_top" : "palette"
                        enabled_: root.state !== "running"
                        onClicked: confirmDialog.open = true
                    }
                    MaterialButton {
                        visible: root.state === "running"
                        text: Lang.t("wall.btn.cancel")
                        style: "outlined"
                        onClicked: { scanProcess.running = false; root.state = "cancelled"; root.statusMessage = Lang.t("wall.msg.cancelled") }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    visible: root.state === "running" || root.state === "done" || root.state === "error" || root.state === "cancelled"
                    radius: Theme.shape.card
                    color: Theme.color.surfaceContainerHigh
                    implicitHeight: progressColumn.implicitHeight + Theme.space.lg * 2
                    ColumnLayout {
                        id: progressColumn
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.space.lg }
                        spacing: Theme.space.sm
                        RowLayout {
                            Layout.fillWidth: true
                            ThemedText { Layout.fillWidth: true; text: Lang.t("wall.state." + root.state); style: Theme.type.titleSmall }
                            ThemedText { text: root.total > 0 ? root.current + " / " + root.total : ""; style: Theme.type.labelMedium; color: Theme.color.fgSurfaceVariant }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: Theme.components.dp(8)
                            radius: Theme.shape.radius("full", height)
                            color: Theme.color.surfaceContainerHighest
                            Rectangle { width: parent.width * (root.state === "done" ? 1 : root.percent / 100); height: parent.height; radius: parent.radius; color: Theme.color.primary; Behavior on width { NumberAnimation { duration: 180 } } }
                        }
                        ThemedText { Layout.fillWidth: true; text: root.statusMessage; style: Theme.type.bodySmall; color: Theme.color.fgSurfaceVariant; wrapMode: Text.Wrap; elide: Text.ElideMiddle }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Theme.space.xs
                            visible: root.state === "done"
                            Repeater {
                                model: Object.keys(root.categoryCounts)
                                Rectangle {
                                    required property string modelData
                                    radius: Theme.shape.radius("full", height)
                                    height: Theme.components.buttonS
                                    width: chipLabel.implicitWidth + Theme.space.md * 2
                                    color: Theme.color.secondaryContainer
                                    ThemedText { id: chipLabel; anchors.centerIn: parent; text: Lang.t("wall.cat." + modelData) + "  " + root.categoryCounts[modelData]; style: Theme.type.labelSmall; color: Theme.color.fgSecondaryContainer }
                                }
                            }
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }

    MaterialDialog {
        id: confirmDialog
        open: false
        title: Lang.t("wall.dlg.title")
        supporting: Lang.t("wall.dlg.supporting")
        MaterialButton { text: Lang.t("wall.btn.cancel"); style: "text"; onClicked: confirmDialog.open = false }
        MaterialButton { text: Lang.t("wall.dlg.start"); onClicked: { confirmDialog.open = false; root.state = "running"; root.current = 0; root.total = 0; root.statusMessage = Lang.t("wall.msg.starting"); scanProcess.running = true } }
    }
}
