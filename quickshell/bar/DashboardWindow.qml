import "root:/theme"
import "root:/shell"
import "root:/dashboard"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// DashboardWindow — картка морфиться з невеликої пігулки (там, де в барі сидить годинник)
// у повний сайдбар, а не просто з'являється. Вкладки: Dashboard/Media/Performance/Workspaces.
//
// Вікно завжди на весь екран (full-screen overlay, exclusionMode: Ignore, тож жодних тайлингів
// не рухає) — росте лише "card" всередині, як MorphSurface. Це навмисно: ресайзити сам
// layer-shell surface щокадру під час анімації — важка операція для композитора (той самий
// глюк, що був із годинником на Stage 5).
//
// Якір пігулки — верх-центр екрана (там, де в тебе зараз стоїть годинник у top-барі). Якщо бар
// не top — це найближче наближення, повної крос-віконної прив'язки до пігулки годинника нема.
Item {
    id: dashRoot

    function open() { win.open() }
    function close() { win.close() }
    function toggle() { win.visible ? win.close() : win.open() }

    PanelWindow {
        id: win

        visible: false
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: win.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        // closed | opening | open | closing — керує напрямком анімації (та ж роль, що й у MorphSurface)
        property string dashState: "closed"
        readonly property bool expanded: dashState === "open" || dashState === "opening"
        readonly property string sizeRole: dashState === "closing" || dashState === "closed" ? "collapse" : "expand"

        function open() {
            win.visible = true
            win.dashState = "opening"
            Qt.callLater(function () { win.dashState = "open" })
        }
        function close() {
            win.dashState = "closing"
            closeTimer.restart()
        }
        function toggle() { win.visible ? win.close() : win.open() }
        Timer { id: closeTimer; interval: Theme.motion.duration("collapse") + 20; onTriggered: { win.visible = false; win.dashState = "closed" } }

        // mask рухається разом з card — коли закрито, вікно взагалі не клікабельне
        mask: Region { item: card }

        readonly property var tabs: [
            { key: "dashboard", label: "Огляд", icon: "\ue871" },
            { key: "media", label: "Медіа", icon: "\ue405" },
            { key: "performance", label: "Продуктивність", icon: "\ue9e4" },
            { key: "workspaces", label: "Робочі місця", icon: "\ue8f9" }
        ]
        property int activeTab: 0

        // ---- ціль форми: pill (закрито) ⇄ сайдбар (відкрито) ----
        // Відступ під бар (top-позиція; для bottom/left/right бару це наближення, не точна
        // прив'язка — BarConfig тут читається глобально, без урахування per-monitor override).
        readonly property real barReserve: BarConfig.thicknessFor("") + Theme.space.screenMargin * 2

        readonly property real pillW: 140
        readonly property real pillH: 40
        readonly property real pillX: (win.width - pillW) / 2       // верх-центр — де сидить годинник
        readonly property real pillY: barReserve + Theme.space.sm    // одразу під баром, не з-під стелі екрана
        readonly property real openW: Math.min(900, win.width - Theme.space.md * 2)
        readonly property real openX: win.width - openW - Theme.space.md
        readonly property real openY: barReserve + Theme.space.sm    // "випадає" з-під бару, а не звідкись з середини екрана
        // Висота — під контент (три картки + вкладки), НЕ на весь екран; клемп про всяк випадок
        readonly property real openH: Math.min(520, win.height - openY - Theme.space.md)

        Item {
            id: card
            x: win.expanded ? win.openX : win.pillX
            y: win.expanded ? win.openY : win.pillY
            width: win.expanded ? win.openW : win.pillW
            height: win.expanded ? win.openH : win.pillH
            clip: true
            focus: win.visible
            Keys.onEscapePressed: win.close()

            Behavior on x { MotionAnimation { role: win.sizeRole } }
            Behavior on y { MotionAnimation { role: win.sizeRole } }
            Behavior on width { MotionAnimation { role: win.sizeRole } }
            Behavior on height { MotionAnimation { role: win.sizeRole } }

            property real radius: win.expanded ? Theme.shape.islandDialog : Theme.shape.radius("full", height)
            Behavior on radius { MotionAnimation { role: win.sizeRole } }

            ElevationShadow {
                anchors.fill: parent
                level: Theme.elevation.overlay
                radius: card.radius
                color: Theme.color.surfaceContainerLow
            }

            // вміст з'являється, коли картка вже майже виросла — без різкого стрибка тексту
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.md
                spacing: Theme.space.md
                opacity: win.dashState === "open" ? 1 : 0
                Behavior on opacity { MotionAnimation { role: win.dashState === "open" ? "enter" : "exit" } }

                // ---- вкладки ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.space.xs

                    Repeater {
                        model: win.tabs
                        Rectangle {
                            id: tabBtn
                            required property var modelData
                            required property int index
                            readonly property bool active: win.activeTab === index
                            Layout.fillWidth: true
                            implicitHeight: Theme.components.buttonS
                            radius: Theme.shape.radius("lg", height)
                            color: active ? Theme.color.secondaryContainer
                                 : tma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerLow, Theme.color.fgSurface, Theme.components.stateHover)
                                 : "transparent"
                            Behavior on color { MotionColorAnimation { role: "stateChange" } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tabBtn.modelData.icon
                                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                                    color: tabBtn.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                                }
                                ThemedText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tabBtn.modelData.label
                                    style: Theme.type.labelSmall
                                    color: tabBtn.active ? Theme.color.fgSecondaryContainer : Theme.color.fgSurfaceVariant
                                }
                            }
                            MouseArea { id: tma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: win.activeTab = tabBtn.index }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.color.outlineVariant }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: win.dashState === "open"
                    sourceComponent: {
                        switch (win.tabs[win.activeTab].key) {
                        case "media": return mediaComp
                        case "performance": return perfComp
                        case "workspaces": return wsComp
                        default: return overviewComp
                        }
                    }
                }
            }

            // Поки картка ще мала (compact-пігулка) — годинник замість вкладок, щоб не було
            // порожнього прямокутника під час росту
            ThemedText {
                anchors.centerIn: parent
                visible: !win.expanded || win.dashState === "opening"
                opacity: win.dashState === "opening" ? 0 : 1
                Behavior on opacity { MotionAnimation { role: "exit" } }
                text: Qt.formatDateTime(new Date(), "HH:mm")
                style: Theme.type.monoMedium
                emphasized: true
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

                // Позиції явні для всіх — GridLayout погано поєднує авто-потік і явні row/column
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
