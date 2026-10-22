pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings"
import "root:/settings/material"
import "root:/surfaces"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// ResourcesSurface — M3 Expressive монітор ресурсів.
Item {
    id: root

    signal requestClose()

    Component.onCompleted: PerformanceService.subscribe()
    Component.onDestruction: PerformanceService.unsubscribe()

    property var cpuHist: []
    property var ramHist: []
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            const c = root.cpuHist.concat([PerformanceService.cpuPercent])
            const r = root.ramHist.concat([PerformanceService.ramPercent])
            root.cpuHist = c.length > 40 ? c.slice(c.length - 40) : c
            root.ramHist = r.length > 40 ? r.slice(r.length - 40) : r
        }
    }

    function launchBtop() {
        const term = Settings.get("general", "terminalCommand") || "ghostty"
        Quickshell.execDetached([term, "-e", "btop"])
        root.requestClose()
    }

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

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.sm

                HeroTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "\ue322"
                    title: Lang.t("ui.res.cpu")
                    percent: PerformanceService.cpuPercent
                    sub: PerformanceService.cpuTemp > 0 ? PerformanceService.cpuTemp + "°C" : ""
                    hist: root.cpuHist
                    base: Theme.color.primaryContainer
                    fgBase: Theme.color.fgPrimaryContainer
                }
                HeroTile {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "\ue1db"
                    title: Lang.t("ui.res.ram")
                    percent: PerformanceService.ramPercent
                    sub: PerformanceService.ramUsedGiB.toFixed(1) + " / " + PerformanceService.ramTotalGiB.toFixed(1) + " GB"
                    hist: root.ramHist
                    base: Theme.color.tertiaryContainer
                    fgBase: Theme.color.fgTertiaryContainer
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.listGap

                StatTile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    rLeft: Theme.shape.md
                    icon: "\ue1ff"
                    label: Lang.t("ui.res.temp")
                    value: PerformanceService.cpuTemp > 0 ? PerformanceService.cpuTemp + "°C" : "—"
                    accent: PerformanceService.cpuTemp > 80 ? Theme.color.error : Theme.color.tertiary
                }
                StatTile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\ue8b5"
                    label: Lang.t("ui.res.uptime")
                    value: PerformanceService.uptime.length > 0 ? PerformanceService.uptime : "—"
                    accent: Theme.color.primary
                }
                StatTile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    icon: "\ue1db"
                    label: Lang.t("ui.res.disk")
                    value: PerformanceService.diskUsedGiB.toFixed(0) + " / " + PerformanceService.diskTotalGiB.toFixed(0) + " GB"
                    bar: PerformanceService.diskPercent
                    accent: PerformanceService.diskPercent > 90 ? Theme.color.error : Theme.color.secondary
                }
                StatTile {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    rRight: Theme.shape.md
                    icon: "\ue8d4"
                    label: Lang.t("ui.res.swap")
                    value: PerformanceService.swapTotalGiB > 0
                           ? PerformanceService.swapUsedGiB.toFixed(1) + " / " + PerformanceService.swapTotalGiB.toFixed(1) + " GB"
                           : "0 GB"
                    bar: PerformanceService.swapTotalGiB > 0 ? PerformanceService.swapPercent : -1
                    accent: Theme.color.outline
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space.xs
                ThemedText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space.sm
                    text: Lang.t("ui.res.procs").toUpperCase()
                    style: Theme.type.labelMedium
                    emphasized: true
                    color: Theme.color.primary
                    font.letterSpacing: 1.2 * Theme.space.k
                }
                MaterialButton {
                    text: Lang.t("ui.res.btop")
                    icon: "open_in_new"
                    style: "tonal"
                    onClicked: root.launchBtop()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.space.listGap

                Repeater {
                    model: PerformanceService.topProcesses

                    Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool isFirst: index === 0
                        readonly property bool isLast: index === PerformanceService.topProcesses.length - 1
                        readonly property real cpu: parseFloat(modelData.cpu) || 0
                        readonly property real mem: parseFloat(modelData.mem) || 0

                        Layout.fillWidth: true
                        implicitHeight: Theme.components.dp(46)
                        color: Theme.color.surfaceContainer
                        topLeftRadius: isFirst ? Theme.shape.md : Theme.shape.listInner
                        topRightRadius: isFirst ? Theme.shape.md : Theme.shape.listInner
                        bottomLeftRadius: isLast ? Theme.shape.md : Theme.shape.listInner
                        bottomRightRadius: isLast ? Theme.shape.md : Theme.shape.listInner
                        Behavior on topLeftRadius { MotionAnimation { role: "morph" } }
                        Behavior on bottomLeftRadius { MotionAnimation { role: "morph" } }

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
                            anchors {
                                left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter
                                leftMargin: Theme.space.md; rightMargin: Theme.space.md
                            }
                            spacing: Theme.space.md

                            Rectangle {
                                implicitWidth: Theme.components.dp(30)
                                implicitHeight: implicitWidth
                                radius: row.cpu > 50 ? height / 2 : Theme.shape.radius("md", height)
                                color: row.cpu > 50 ? Theme.color.errorContainer : Theme.color.secondaryContainer
                                Behavior on radius { MotionAnimation { role: "morph" } }
                                Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                ThemedText {
                                    anchors.centerIn: parent
                                    text: (row.modelData.name || "?").charAt(0).toUpperCase()
                                    style: Theme.type.labelLarge
                                    emphasized: true
                                    color: row.cpu > 50 ? Theme.color.fgErrorContainer : Theme.color.fgSecondaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                ThemedText {
                                    Layout.fillWidth: true
                                    text: row.modelData.name
                                    style: Theme.type.bodyMedium
                                    emphasized: true
                                    elide: Text.ElideRight
                                }
                                ThemedText {
                                    text: "PID " + row.modelData.pid
                                    style: Theme.type.labelSmall
                                    color: Theme.color.fgSurfaceVariant
                                }
                            }

                            Rectangle {
                                implicitWidth: Theme.components.dp(64)
                                implicitHeight: Theme.components.dp(26)
                                radius: height / 2
                                color: row.cpu > 10 ? Theme.color.primaryContainer : Theme.color.surfaceContainerHighest
                                Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                ThemedText {
                                    anchors.centerIn: parent
                                    text: "CPU " + Math.round(row.cpu) + "%"
                                    style: Theme.type.labelSmall
                                    emphasized: row.cpu > 10
                                    color: row.cpu > 10 ? Theme.color.fgPrimaryContainer : Theme.color.fgSurfaceVariant
                                }
                            }
                            Rectangle {
                                implicitWidth: Theme.components.dp(64)
                                implicitHeight: Theme.components.dp(26)
                                radius: height / 2
                                color: row.mem > 10 ? Theme.color.tertiaryContainer : Theme.color.surfaceContainerHighest
                                Behavior on color { MotionColorAnimation { role: "stateChange" } }
                                ThemedText {
                                    anchors.centerIn: parent
                                    text: "MEM " + Math.round(row.mem) + "%"
                                    style: Theme.type.labelSmall
                                    emphasized: row.mem > 10
                                    color: row.mem > 10 ? Theme.color.fgTertiaryContainer : Theme.color.fgSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
