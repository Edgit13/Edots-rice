import "root:/"
import "root:/theme"
import "root:/shell"
import "root:/services"
import "root:/dashboard"
import Quickshell
import QtQuick
import QtQuick.Layouts

// DashboardSurface — дашборд, що морфиться з самої смуги бару (НЕ окреме вікно).
// Хост (BarWindow) кладе цей Item одразу під смугою (top), над нею (bottom)
// або збоку (left/right) і додає його до morphModules.
//
// Стилістика вмісту — як LauncherSurface/MixerSurface/MediaSurface:
//   Colors.* / Md.*, шрифти SF Pro Display + Material Symbols Rounded,
//   radius Md.rM, hover Qt.rgba(fg, 0.08) / Md.hoverOf().
Item {
    id: root

    // ---- API для хоста ----
    property string hostMonitor: ""   // BarWindow встановлює modelData.name
    property real maxHeight: 520      // скільки місця є вздовж осі розгортання

    // наскільки розгорнута картка виходить за межі compact-смуги (читає BarWindow)
    readonly property real expandedHeight: Math.min(520, Math.max(120, maxHeight))
    readonly property real drop: Theme.space.sm + expandedHeight
    readonly property real overflowTop: drop
    readonly property real overflowBottom: drop
    readonly property real overflowLeft: drop
    readonly property real overflowRight: drop

    // true, поки вікно має займати місце під картку (включаючи анімацію згортання) —
    // після closeTimer картка вже згорнута, і вікно повертається до товщини смуги
    readonly property bool occupies: dashState !== "closed"

    // ---- стани (та сама машина станів, що й у колишнього DashboardWindow) ----
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
        Qt.callLater(function () { dashState = "open" })
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
        onTriggered: { root.dashState = "closed"; ShellState.closeSurfaces() }
    }

    // ---- глобальні запити (клік по годиннику, Super+D, IPC) ----
    // відкриваємо лише на поточному моніторі (та сама логіка, що в SurfaceOverlay)
    readonly property bool isCurrentMonitor: {
        const focusedMon = MangoService.focusedClient.monitor
        if (focusedMon && focusedMon.length > 0) return focusedMon === root.hostMonitor
        return Quickshell.screens.length > 0 && Quickshell.screens[0].name === root.hostMonitor
    }

    Connections {
        target: ShellState
        function onOpenDashboardRequested()   { if (root.isCurrentMonitor) root.open(); else root.close() }
        function onToggleDashboardRequested() { if (root.isCurrentMonitor) root.toggle(); else root.close() }
        function onCloseDashboardRequested()  { root.close() }
        // відкрилась інша поверхня (launcher, mixer, wifi...) — згортаємось
        function onActiveSurfaceChanged() {
            if (ShellState.activeSurface !== "dashboard" &&
                (root.dashState === "open" || root.dashState === "opening")) {
                root.dashState = "closing"
                closeTimer.restart()
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

        // та сама тінь, що в SurfaceOverlay
        ElevationShadow {
            anchors.fill: parent
            level: 4
            radius: Theme.shape.dialog
            color: Theme.color.surfaceContainerHigh
        }

        // та сама картка, що в SurfaceOverlay (launcher/mixer/wifi/...)
        Rectangle {
            anchors.fill: parent
            radius: Theme.shape.dialog
            color: Theme.color.surfaceContainerHigh
            border.width: 1
            border.color: Theme.color.outlineVariant
            clip: true

            // кліки по тілу картки не проходять на scrim
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.lg
                spacing: 14

                opacity: root.dashState === "open" ? 1 : 0
                Behavior on opacity { MotionAnimation { role: root.dashState === "open" ? "enter" : "exit" } }

                // ---- заголовок: іконка + назва активної вкладки + ✕ (стиль поверхонь) ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: root.tabs[root.activeTab].icon
                        color: Md.primary
                        font { family: "Material Symbols Rounded"; pixelSize: 16 }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.tabs[root.activeTab].label
                        color: Colors.fg
                        font { family: "SF Pro Display"; pixelSize: 13; weight: 600 }
                    }

                    Rectangle {   // кругла кнопка закриття
                        width: 32; height: 32
                        radius: 16
                        color: closeMa.pressed ? Md.pressedOf(Md.m3OnSurface)
                             : closeMa.containsMouse ? Md.hoverOf(Md.m3OnSurface)
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: Md.durFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "\ue5cd"
                            color: Colors.grey2
                            font { family: "Material Symbols Rounded"; pixelSize: 16 }
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

                // ---- вкладки (як selected-row у LauncherSurface) ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: root.tabs
                        Rectangle {
                            id: tabBtn
                            required property var modelData
                            required property int index
                            readonly property bool active: root.activeTab === index
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Md.rM
                            color: active ? Colors.accent
                                 : tma.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08)
                                 : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: tabBtn.modelData.icon
                                    color: tabBtn.active ? Colors.bg0 : Colors.grey2
                                    font { family: "Material Symbols Rounded"; pixelSize: 14 }
                                }
                                Text {
                                    text: tabBtn.modelData.label
                                    color: tabBtn.active ? Colors.bg0 : Colors.grey2
                                    font { family: "SF Pro Display"; pixelSize: 11; weight: tabBtn.active ? 600 : 500 }
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

                Rectangle { Layout.fillWidth: true; height: 1; color: Md.outlineVariant }

                Loader {
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
                }
            }
        }
    }

    Component {
        id: overviewComp
        Flickable {
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

                WeatherCard { Layout.column: 0; Layout.row: 0; Layout.fillWidth: true }
                SystemCard { Layout.column: 1; Layout.row: 0; Layout.fillWidth: true }
                MiniMediaCard { Layout.column: 2; Layout.row: 0; Layout.rowSpan: 2; Layout.fillWidth: true; Layout.fillHeight: true }
                CalendarCard { Layout.column: 0; Layout.row: 1; Layout.columnSpan: 2; Layout.fillWidth: true }
            }
        }
    }
    Component { id: mediaComp; MediaTab {} }
    Component { id: perfComp; PerformanceTab {} }
    Component { id: wsComp; WorkspacesTab {} }
}
