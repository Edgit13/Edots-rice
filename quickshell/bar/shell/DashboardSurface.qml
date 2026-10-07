import "root:/"
import "root:/theme"
import "root:/shell"
import "root:/services"
import "root:/dashboard"
import Quickshell
import QtQuick
import QtQuick.Layouts

// DashboardSurface — Material 3 Expressive дашборд, що морфиться з смуги бару.
// Хост (BarWindow) розміщує цей Item під або над смугою і розширює вікно
// на freeOverflow без зламу wlroots layer-shell та тайлінгу вікон.
Item {
    id: root

    // ---- API для хоста ----
    property string hostMonitor: ""   // BarWindow встановлює win.monitorName
    property real maxHeight: 520      // доступна висота для розгортання

    readonly property real expandedHeight: Math.min(520, Math.max(120, maxHeight))
    readonly property real drop: Theme.space.sm + expandedHeight
    readonly property real overflowTop: occupies ? drop : 0
    readonly property real overflowBottom: occupies ? drop : 0
    readonly property real overflowLeft: occupies ? drop : 0
    readonly property real overflowRight: occupies ? drop : 0

    // true, поки вікно має виділяти місце під картку (включаючи анімацію закриття)
    readonly property bool occupies: dashState !== "closed"

    // closed | opening | open | closing
    property string dashState: "closed"
    readonly property bool expanded: dashState === "open" || dashState === "opening"
    readonly property string sizeRole: dashState === "closing" || dashState === "closed" ? "collapse" : "expand"

    height: expanded ? expandedHeight : 0
    Behavior on height { MotionAnimation { role: root.sizeRole } }
    clip: true

    function open() {
        if (dashState === "open" || dashState === "opening") return
        closeTimer.stop()
        ShellState.openSurface("dashboard")
        dashState = "opening"
        Qt.callLater(function () {
            dashState = "open"
            card.forceActiveFocus()
        })
    }

    function close() {
        if (dashState === "closed" || dashState === "closing") return
        dashState = "closing"
        closeTimer.restart()
    }

    function toggle() {
        if (dashState === "open" || dashState === "opening") close()
        else open()
    }

    Timer {
        id: closeTimer
        interval: Theme.motion.duration("collapse") + 40
        onTriggered: {
            root.dashState = "closed"
            if (ShellState.activeSurface === "dashboard") {
                ShellState.closeSurfaces()
            }
        }
    }

    // Відкриваємо лише на потрібному/поточному моніторі
    readonly property bool isCurrentMonitor: {
        const focusedMon = MangoService.focusedClient.monitor
        if (focusedMon && focusedMon.length > 0) return focusedMon === root.hostMonitor
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === root.hostMonitor
    }

    function shouldHandleRequest(targetMon) {
        if (targetMon && targetMon.length > 0) return targetMon === root.hostMonitor
        return root.isCurrentMonitor
    }

    Connections {
        target: ShellState
        function onOpenDashboardRequested(targetMon) {
            if (root.shouldHandleRequest(targetMon)) root.open()
            else root.close()
        }
        function onToggleDashboardRequested(targetMon) {
            if (root.shouldHandleRequest(targetMon)) root.toggle()
            else root.close()
        }
        function onCloseDashboardRequested() {
            root.close()
        }
        function onActiveSurfaceChanged() {
            if (ShellState.activeSurface !== "dashboard" &&
                (root.dashState === "open" || root.dashState === "opening")) {
                root.dashState = "closing"
                closeTimer.restart()
            }
        }
    }

    // Закриття при кліку на інше вікно (зміна фокусу)
    Connections {
        target: MangoService
        function onFocusedClientChanged() {
            if (root.dashState === "open" && MangoService.focusedClient && MangoService.focusedClient.id !== null) {
                root.close()
            }
        }
    }

    // ===================== вміст =====================

    readonly property var tabs: [
        { key: "dashboard", label: "Огляд", icon: "\ue871" },
        { key: "media", label: "Медіа", icon: "\ue405" },
        { key: "performance", label: "Продуктивність", icon: "\ue9e4" },
        { key: "workspaces", label: "Робочі місця", icon: "\ue8f9" }
    ]
    property int activeTab: 0

    Item {
        id: card
        width: parent.width
        height: root.expandedHeight
        focus: root.expanded

        Keys.onEscapePressed: function(e) {
            root.close()
            e.accepted = true
        }

        ElevationShadow {
            anchors.fill: parent
            level: 4
            radius: Theme.shape.dialog
            color: Theme.color.surfaceContainerHigh
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.dialog
            color: Theme.color.surfaceContainerHigh
            border.width: 1
            border.color: Theme.color.outlineVariant
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.lg
                spacing: Theme.space.md

                opacity: root.dashState === "open" ? 1 : 0
                Behavior on opacity { MotionAnimation { role: root.dashState === "open" ? "enter" : "exit" } }

                // ---- заголовок: іконка + назва вкладки + кнопка закриття ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.sm

                    Text {
                        text: root.tabs[root.activeTab].icon
                        color: Theme.color.primary
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconM }
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        text: root.tabs[root.activeTab].label
                        style: Theme.type.titleMedium
                        emphasized: true
                        color: Theme.color.fgSurface
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: closeMa.containsMouse ? Theme.color.surfaceContainerHighest : "transparent"
                        Behavior on color { MotionColorAnimation { role: "hover" } }

                        Text {
                            anchors.centerIn: parent
                            text: "\ue5cd"
                            font { family: Theme.type.icons; pixelSize: 18 }
                            color: Theme.color.fgSurfaceVariant
                        }

                        MouseArea {
                            id: closeMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                // ---- панель вкладок ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.xs

                    Repeater {
                        model: root.tabs
                        Rectangle {
                            id: tabBtn
                            required property var modelData
                            required property int index
                            readonly property bool active: root.activeTab === index
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: Theme.shape.button
                            color: active ? Theme.color.secondaryContainer
                                 : tma.containsMouse ? Theme.color.surfaceContainerHighest
                                 : "transparent"
                            Behavior on color { MotionColorAnimation { role: "hover" } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Theme.space.xs

                                Text {
                                    text: tabBtn.modelData.icon
                                    color: tabBtn.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                }
                                ThemedText {
                                    text: tabBtn.modelData.label
                                    color: tabBtn.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                                    style: Theme.type.labelMedium
                                    emphasized: tabBtn.active
                                }
                            }

                            MouseArea {
                                id: tma
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = tabBtn.index
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.color.outlineVariant
                }

                // ---- контейнер контенту активної вкладки ----
                Loader {
                    id: tabLoader
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.dashState === "open"
                    sourceComponent: {
                        switch (root.tabs[root.activeTab].key) {
                        case "media": return mediaComp
                        case "performance": return perfComp
                        case "workspaces": return wsComp
                        default: return overviewComp
                        }
                    }
                    onLoaded: {
                        if (item) {
                            item.anchors.fill = tabLoader
                        }
                    }
                }
            }
        }
    }

    Component {
        id: overviewComp
        Flickable {
            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: grid.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            GridLayout {
                id: grid
                width: parent.width
                columns: 3
                columnSpacing: Theme.space.md
                rowSpacing: Theme.space.md

                WeatherCard {
                    Layout.column: 0
                    Layout.row: 0
                    Layout.fillWidth: true
                }
                SystemCard {
                    Layout.column: 1
                    Layout.row: 0
                    Layout.fillWidth: true
                }
                MiniMediaCard {
                    Layout.column: 2
                    Layout.row: 0
                    Layout.rowSpan: 2
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                CalendarCard {
                    Layout.column: 0
                    Layout.row: 1
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                }
            }
        }
    }

    Component { id: mediaComp; MediaTab { anchors.fill: parent } }
    Component { id: perfComp; PerformanceTab { anchors.fill: parent } }
    Component { id: wsComp; WorkspacesTab { anchors.fill: parent } }
}
