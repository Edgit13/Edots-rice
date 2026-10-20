import "root:/theme"
import "root:/dashboard"
import "root:/services"
import "root:/shell"
import "root:/settings"
import Quickshell
import QtQuick
import QtQuick.Layouts

// DashboardSurface — M3 Expressive dashboard overlay.
//
// Layout: identity + environment → control → time → media.
// Animation: surface slides from bar direction + fades + scales;
// cards cascade in with per-index delay; tabs crossfade with slide.
Item {
    id: root

    property string hostMonitor: ""
    property real maxHeight: 100000
    property bool occupies: false
    property string revealDirection: "top"   // top|bottom|left|right

    readonly property real desiredHeight: 760
    readonly property real effectiveHeight: Math.min(desiredHeight, maxHeight)

    implicitWidth: 920
    implicitHeight: occupies ? effectiveHeight : 0

    // ---- Interface consumed by BarWindow.morphModules ----
    readonly property real overflowBottom: occupies ? effectiveHeight : 0
    readonly property real overflowTop:    occupies ? effectiveHeight : 0
    readonly property real overflowLeft:   occupies ? implicitWidth  : 0
    readonly property real overflowRight:  occupies ? implicitWidth  : 0

    visible: occupies || opacity > 0.01

    Connections {
        target: ShellState
        function onOpenDashboardRequested(monitor) {
            if (monitor === "" || monitor === root.hostMonitor) root.occupies = true
        }
        function onToggleDashboardRequested(monitor) {
            if (monitor === "" || monitor === root.hostMonitor) root.occupies = !root.occupies
        }
        function onCloseDashboardRequested() { root.occupies = false }
    }

    property int currentTab: 0

    readonly property int contentHeight: Math.max(300, Math.round(effectiveHeight) - 152)

    readonly property var tabs: [
        { glyph: "\ue871", label: Lang.t("ui.tab.overview") },
        { glyph: "\ue405", label: Lang.t("ui.tab.media") },
        { glyph: "\ue85c", label: Lang.t("ui.tab.performance") },
        { glyph: "\uef4c", label: Lang.t("ui.tab.workspaces") },
        { glyph: "\ue935", label: Lang.t("ui.tab.planner") }
    ]

    // Slide offset when hidden — depends on bar side.
    readonly property real _offsetX: {
        if (occupies) return 0
        if (revealDirection === "left")  return -32
        if (revealDirection === "right") return  32
        return 0
    }
    readonly property real _offsetY: {
        if (occupies) return 0
        if (revealDirection === "top")    return -32
        if (revealDirection === "bottom") return  32
        return 0
    }
    readonly property int _origin: {
        if (revealDirection === "left")   return Item.Left
        if (revealDirection === "right")  return Item.Right
        if (revealDirection === "bottom") return Item.Bottom
        return Item.Top
    }

    // ── Animated stage: slides + fades + scales as one unit ──────
    Item {
        id: stage
        anchors.fill: parent
        x: root._offsetX
        y: root._offsetY
        opacity: root.occupies ? 1 : 0
        scale:   root.occupies ? 1 : 0.96
        transformOrigin: root._origin

        Behavior on x       { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }
        Behavior on y       { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on scale   { NumberAnimation { duration: 440; easing.type: Easing.OutCubic } }

        ElevationShadow {
            anchors.fill: parent
            level: Theme.elevation.resting
            radius: Theme.shape.cardLarge
            color: Theme.color.surfaceContainer
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.space.lg
            spacing: Theme.space.md

            // ── Header ───────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.sm

                Text {
                    text: root.tabs[root.currentTab].glyph
                    font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                    color: Theme.color.primary
                }
                ThemedText {
                    text: root.tabs[root.currentTab].label
                    style: Theme.type.titleMedium
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 16
                    color: closeMa.pressed
                        ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
                        : closeMa.containsMouse
                            ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
                            : "transparent"
                    Behavior on color { MotionColorAnimation { role: "hover" } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ue5cd"
                        font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
                        color: Theme.color.fgSurface
                    }
                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.closeDashboard()
                    }
                }
            }

            // ── Tabs ─────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space.xs

                Repeater {
                    model: root.tabs
                    Rectangle {
                        id: tabRect
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 20
                        color: tabRect.index === root.currentTab
                            ? Theme.color.secondaryContainer
                            : tabMa.pressed
                                ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.statePressed)
                                : tabMa.containsMouse
                                    ? Theme.stateLayer(Theme.color.surfaceContainerHighest, Theme.color.fgSurface, Theme.components.stateHover)
                                    : "transparent"
                        Behavior on color { MotionColorAnimation { role: "hover" } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Theme.space.xs

                            Text {
                                text: tabRect.modelData.glyph
                                font { family: Theme.type.icons; pixelSize: Theme.type.iconXS }
                                color: tabRect.index === root.currentTab
                                    ? Theme.color.fgSecondaryContainer
                                    : Theme.color.fgSurfaceVariant
                            }
                            ThemedText {
                                text: tabRect.modelData.label
                                style: Theme.type.labelLarge
                                color: tabRect.index === root.currentTab
                                    ? Theme.color.fgSecondaryContainer
                                    : Theme.color.fgSurfaceVariant
                            }
                        }
                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = tabRect.index
                        }
                    }
                }
            }

            // ── Page stack with crossfade + slide ────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: root.contentHeight
                clip: true

                Repeater {
                    model: root.tabs.length
                    Item {
                        id: pageWrap
                        required property int index
                        anchors.fill: parent
                        readonly property bool isCurrent: index === root.currentTab
                        visible: opacity > 0.01
                        opacity: isCurrent ? 1 : 0
                        x: isCurrent ? 0 : (index < root.currentTab ? -28 : 28)
                        scale: isCurrent ? 1 : 0.97
                        transformOrigin: Item.Center

                        Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        Behavior on x       { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        Behavior on scale   { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                        Loader {
                            anchors.fill: parent
                            active: pageWrap.isCurrent || pageWrap.opacity > 0.01
                            sourceComponent: [
                                pageOverview,
                                pageMedia,
                                pagePerformance,
                                pageWorkspaces,
                                pagePlanner
                            ][pageWrap.index]
                        }
                    }
                }
            }
        }
    }

    // ── Page components ─────────────────────────────────────

    Component {
        id: pageOverview
        Flickable {
            id: flick
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentWidth: width
            contentHeight: grid.implicitHeight

            GridLayout {
                id: grid
                width: flick.width
                columns: 2
                columnSpacing: Theme.space.md
                rowSpacing: Theme.space.md

                // Row 1 — identity + environment
                Reveal {
                    index: 0
                    shown: root.occupies
                    Layout.fillWidth: true
                    Layout.preferredHeight: 172
                    SystemCard { anchors.fill: parent }
                }
                Reveal {
                    index: 1
                    shown: root.occupies
                    Layout.fillWidth: true
                    Layout.preferredHeight: 172
                    WeatherCard { anchors.fill: parent }
                }

                // Row 2 — brightness control (full width)
                Reveal {
                    index: 2
                    shown: root.occupies
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    Layout.preferredHeight: 136
                    BrightnessCard { anchors.fill: parent }
                }

                // Row 3 — time tools
                Reveal {
                    index: 3
                    shown: root.occupies
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    CalendarCard { anchors.fill: parent }
                }
                Reveal {
                    index: 4
                    shown: root.occupies
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    TimerCard { anchors.fill: parent }
                }

                // Row 4 — media strip (full width)
                Reveal {
                    index: 5
                    shown: root.occupies
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    Layout.preferredHeight: 240
                    MiniMediaCard { anchors.fill: parent }
                }
            }
        }
    }

    Component { id: pageMedia;       MediaTab       { } }
    Component { id: pagePerformance; PerformanceTab { } }
    Component { id: pageWorkspaces;  WorkspacesTab  { } }
    Component { id: pagePlanner;     PlannerTab     { } }

    // ── Reveal helper: staggered fade + scale-in ────────────
    component Reveal: Item {
        id: reveal
        property int index: 0
        property bool shown: false
        property int startDelay: 140
        property int stagger: 55
        property int enterDuration: 460
        property int exitDuration: 200

        default property alias content: holder.data

        readonly property int _delay: reveal.shown
            ? (reveal.startDelay + reveal.index * reveal.stagger)
            : 0

        opacity: shown ? 1 : 0
        scale:   shown ? 1 : 0.95
        transformOrigin: Item.Center

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: reveal._delay }
                NumberAnimation {
                    duration: reveal.shown ? reveal.enterDuration : reveal.exitDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation { duration: reveal._delay }
                NumberAnimation {
                    duration: reveal.shown ? reveal.enterDuration : reveal.exitDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: holder
            anchors.fill: parent
        }
    }
}
