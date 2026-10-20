pragma ComponentBehavior: Bound
import "root:/theme"
import "root:/services"
import "root:/settings"
import "root:/settings/material"
import "root:/shell"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// ResourcesSurface — детальне меню моніторингу навантаження (CPU, RAM, диск, swap, температура, топ процеси)
Item {
    id: root

    Component.onCompleted: PerformanceService.subscribe()
    Component.onDestruction: PerformanceService.unsubscribe()

    Process {
        id: btopProc
        function launch() {
            const term = Settings.get("general", "terminalCommand") || "ghostty"
            command = [term, "-e", "btop"]
            running = false
            running = true
            ShellState.closeSurfaces()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space.md

        // ── 1. Top Bar: Quick Stats (Uptime, Temp) + btop Launch Button ──
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            // Uptime pill
            Rectangle {
                implicitHeight: Theme.components.dp(30)
                implicitWidth: upRow.implicitWidth + Theme.space.md * 2
                radius: Theme.shape.radius("full", height)
                color: Theme.color.surfaceContainer

                RowLayout {
                    id: upRow
                    anchors.centerIn: parent
                    spacing: Theme.space.xs
                    Text {
                        text: "schedule"
                        color: Theme.color.primary
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                    }
                    ThemedText {
                        text: (PerformanceService.uptime.length > 0 ? PerformanceService.uptime : "—")
                        style: Theme.type.labelSmall
                        emphasized: true
                    }
                }
            }

            // Temp pill
            Rectangle {
                implicitHeight: Theme.components.dp(30)
                implicitWidth: tempRow.implicitWidth + Theme.space.md * 2
                radius: Theme.shape.radius("full", height)
                color: Theme.color.surfaceContainer

                RowLayout {
                    id: tempRow
                    anchors.centerIn: parent
                    spacing: Theme.space.xs
                    Text {
                        text: "thermostat"
                        color: PerformanceService.cpuTemp > 80 ? Theme.color.error : Theme.color.tertiary
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                    }
                    ThemedText {
                        text: PerformanceService.cpuTemp > 0 ? (PerformanceService.cpuTemp + "°C") : "—"
                        style: Theme.type.labelSmall
                        emphasized: true
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Launch btop / terminal monitor
            MaterialButton {
                style: "tonal"
                icon: "open_in_new"
                text: Lang.t("ui.res.btop")
                onClicked: btopProc.launch()
            }
        }

        // ── 2. Hero Cards: CPU & RAM ──
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            // CPU Hero Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.components.dp(105)
                radius: Theme.shape.card
                color: Theme.color.surfaceContainer
                border.width: 1
                border.color: Theme.color.outlineVariant

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.md
                    spacing: Theme.space.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        Rectangle {
                            implicitWidth: Theme.components.dp(32)
                            implicitHeight: implicitWidth
                            radius: Theme.shape.radius("md", height)
                            color: Theme.color.primaryContainer
                            Text {
                                anchors.centerIn: parent
                                text: "\ue322"
                                color: Theme.color.fgPrimaryContainer
                                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                            }
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: Lang.t("ui.res.cpu")
                            style: Theme.type.titleSmall
                            emphasized: true
                        }

                        ThemedText {
                            text: Math.round(PerformanceService.cpuPercent) + "%"
                            style: Theme.type.headlineSmall
                            emphasized: true
                            color: PerformanceService.cpuPercent > 85 ? Theme.color.error : Theme.color.primary
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // Progress track
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.components.dp(6)
                        radius: Theme.shape.radius("full", height)
                        color: Theme.color.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, PerformanceService.cpuPercent / 100))
                            height: parent.height
                            radius: parent.radius
                            color: PerformanceService.cpuPercent > 85 ? Theme.color.error : Theme.color.primary
                            Behavior on width { MotionAnimation { role: "move" } }
                        }
                    }
                }
            }

            // RAM Hero Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.components.dp(105)
                radius: Theme.shape.card
                color: Theme.color.surfaceContainer
                border.width: 1
                border.color: Theme.color.outlineVariant

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.md
                    spacing: Theme.space.xs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.space.sm

                        Rectangle {
                            implicitWidth: Theme.components.dp(32)
                            implicitHeight: implicitWidth
                            radius: Theme.shape.radius("md", height)
                            color: Theme.color.tertiaryContainer
                            Text {
                                anchors.centerIn: parent
                                text: "\ue1db"
                                color: Theme.color.fgTertiaryContainer
                                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                            }
                        }

                        ThemedText {
                            Layout.fillWidth: true
                            text: Lang.t("ui.res.ram")
                            style: Theme.type.titleSmall
                            emphasized: true
                        }

                        ThemedText {
                            text: Math.round(PerformanceService.ramPercent) + "%"
                            style: Theme.type.headlineSmall
                            emphasized: true
                            color: PerformanceService.ramPercent > 85 ? Theme.color.error : Theme.color.tertiary
                        }
                    }

                    ThemedText {
                        text: PerformanceService.ramUsedGiB.toFixed(1) + " / " + PerformanceService.ramTotalGiB.toFixed(1) + " GB"
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                    }

                    // Progress track
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.components.dp(6)
                        radius: Theme.shape.radius("full", height)
                        color: Theme.color.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, PerformanceService.ramPercent / 100))
                            height: parent.height
                            radius: parent.radius
                            color: PerformanceService.ramPercent > 85 ? Theme.color.error : Theme.color.tertiary
                            Behavior on width { MotionAnimation { role: "move" } }
                        }
                    }
                }
            }
        }

        // ── 3. Secondary Row: Storage & Swap ──
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space.sm

            // Disk Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.components.dp(78)
                radius: Theme.shape.card
                color: Theme.color.surfaceContainer
                border.width: 1
                border.color: Theme.color.outlineVariant

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.md
                    spacing: Theme.space.xxs

                    RowLayout {
                        Layout.fillWidth: true
                        ThemedText {
                            text: Lang.t("ui.res.disk")
                            style: Theme.type.titleSmall
                            emphasized: true
                        }
                        Item { Layout.fillWidth: true }
                        ThemedText {
                            text: PerformanceService.diskUsedGiB.toFixed(0) + " / " + PerformanceService.diskTotalGiB.toFixed(0) + " GB (" + Math.round(PerformanceService.diskPercent) + "%)"
                            style: Theme.type.labelSmall
                            color: Theme.color.secondary
                            emphasized: true
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.components.dp(5)
                        radius: Theme.shape.radius("full", height)
                        color: Theme.color.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, PerformanceService.diskPercent / 100))
                            height: parent.height
                            radius: parent.radius
                            color: Theme.color.secondary
                            Behavior on width { MotionAnimation { role: "move" } }
                        }
                    }
                }
            }

            // Swap Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Theme.components.dp(78)
                radius: Theme.shape.card
                color: Theme.color.surfaceContainer
                border.width: 1
                border.color: Theme.color.outlineVariant

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.space.md
                    spacing: Theme.space.xxs

                    RowLayout {
                        Layout.fillWidth: true
                        ThemedText {
                            text: Lang.t("ui.res.swap")
                            style: Theme.type.titleSmall
                            emphasized: true
                        }
                        Item { Layout.fillWidth: true }
                        ThemedText {
                            text: PerformanceService.swapTotalGiB > 0
                                ? (PerformanceService.swapUsedGiB.toFixed(1) + " / " + PerformanceService.swapTotalGiB.toFixed(1) + " GB (" + Math.round(PerformanceService.swapPercent) + "%)")
                                : "0 GB"
                            style: Theme.type.labelSmall
                            color: Theme.color.fgSurfaceVariant
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Theme.components.dp(5)
                        radius: Theme.shape.radius("full", height)
                        color: Theme.color.surfaceContainerHighest
                        clip: true

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, PerformanceService.swapPercent / 100))
                            height: parent.height
                            radius: parent.radius
                            color: Theme.color.outline
                            Behavior on width { MotionAnimation { role: "move" } }
                        }
                    }
                }
            }
        }

        // ── 4. Top Processes Table ──
        ThemedText {
            Layout.fillWidth: true
            Layout.topMargin: Theme.space.xs
            text: Lang.t("ui.res.procs").toUpperCase()
            style: Theme.type.labelSmall
            emphasized: true
            color: Theme.color.primary
            font.letterSpacing: 1.2 * Theme.space.k
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.shape.card
            color: Theme.color.surfaceContainer
            border.width: 1
            border.color: Theme.color.outlineVariant
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.sm
                spacing: Theme.space.xxs

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Theme.space.sm
                    Layout.rightMargin: Theme.space.sm
                    Layout.bottomMargin: Theme.space.xxs
                    spacing: Theme.space.sm

                    ThemedText {
                        Layout.fillWidth: true
                        text: "NAME"
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                        emphasized: true
                    }
                    ThemedText {
                        Layout.preferredWidth: Theme.components.dp(55)
                        text: "PID"
                        horizontalAlignment: Text.AlignRight
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                        emphasized: true
                    }
                    ThemedText {
                        Layout.preferredWidth: Theme.components.dp(60)
                        text: "CPU"
                        horizontalAlignment: Text.AlignRight
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                        emphasized: true
                    }
                    ThemedText {
                        Layout.preferredWidth: Theme.components.dp(60)
                        text: "MEM"
                        horizontalAlignment: Text.AlignRight
                        style: Theme.type.labelSmall
                        color: Theme.color.fgSurfaceVariant
                        emphasized: true
                    }
                }

                // Process rows
                Repeater {
                    model: PerformanceService.topProcesses

                    Rectangle {
                        id: procRow
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: Theme.components.dp(34)
                        radius: Theme.shape.radius("xs", height)
                        color: rowMa.containsMouse ? Theme.color.surfaceContainerHigh : "transparent"
                        Behavior on color { MotionColorAnimation { role: "hover" } }

                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.space.sm
                            anchors.rightMargin: Theme.space.sm
                            spacing: Theme.space.sm

                            // Icon + Name
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.space.xs

                                Text {
                                    text: "terminal"
                                    color: Theme.color.fgSurfaceVariant
                                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                }

                                ThemedText {
                                    Layout.fillWidth: true
                                    text: procRow.modelData.name
                                    style: Theme.type.labelMedium
                                    emphasized: true
                                    elide: Text.ElideRight
                                }
                            }

                            // PID
                            ThemedText {
                                Layout.preferredWidth: Theme.components.dp(55)
                                text: procRow.modelData.pid
                                horizontalAlignment: Text.AlignRight
                                style: Theme.type.bodySmall
                                color: Theme.color.fgSurfaceVariant
                                font.family: Theme.type.mono
                            }

                            // CPU %
                            Rectangle {
                                Layout.preferredWidth: Theme.components.dp(60)
                                implicitHeight: Theme.components.dp(24)
                                radius: Theme.shape.radius("full", height)
                                color: parseFloat(procRow.modelData.cpu) > 10 ? Theme.alpha(Theme.color.primary, 0.2) : "transparent"

                                ThemedText {
                                    anchors.centerIn: parent
                                    text: procRow.modelData.cpu + "%"
                                    style: Theme.type.labelSmall
                                    color: parseFloat(procRow.modelData.cpu) > 10 ? Theme.color.primary : Theme.color.fgSurface
                                    font.family: Theme.type.mono
                                    emphasized: parseFloat(procRow.modelData.cpu) > 10
                                }
                            }

                            // MEM %
                            Rectangle {
                                Layout.preferredWidth: Theme.components.dp(60)
                                implicitHeight: Theme.components.dp(24)
                                radius: Theme.shape.radius("full", height)
                                color: parseFloat(procRow.modelData.mem) > 10 ? Theme.alpha(Theme.color.tertiary, 0.2) : "transparent"

                                ThemedText {
                                    anchors.centerIn: parent
                                    text: procRow.modelData.mem + "%"
                                    style: Theme.type.labelSmall
                                    color: parseFloat(procRow.modelData.mem) > 10 ? Theme.color.tertiary : Theme.color.fgSurface
                                    font.family: Theme.type.mono
                                    emphasized: parseFloat(procRow.modelData.mem) > 10
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
