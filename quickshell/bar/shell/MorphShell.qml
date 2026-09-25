import "root:/theme"
import Quickshell
import QtQuick
import QtQuick.Layouts

// MorphShell — ОДНА поверхня на бар/монітор (п.4, п.20). Обгортає MorphSurface й керується
// зовні через MorphShellState (idle/peek/module/dialog), а не власним внутрішнім станом:
//   MorphShell {
//       shellState: MorphShellState {}
//       modules: [
//           { key: "clock", glimpse: clockGlimpse, panel: null },
//           { key: "wifi", glimpse: wifiGlimpse, panel: wifiPanel, panelWidth: 320, panelHeight: 360 }
//       ]
//   }
// Модуль каже лише shellState.openModule("wifi") — MorphShell сам рахує розмір/контент (п.19).
Item {
    id: root

    required property MorphShellState shellState
    property var modules: []                 // [{key, icon, glimpse, panel, dialogPanel, panelWidth, panelHeight, dialogWidth, dialogHeight}]
    property bool vertical: false
    property real originX: 0.5
    property real originY: 0

    readonly property var activeDescriptor: modules.find(m => m.key === shellState.activeModule) || null

    // ---------- розміри ----------
    readonly property real peekWidth: Math.max(160, glimpseRow.implicitWidth + Theme.space.lg * 2)
    readonly property real peekHeight: Theme.components.islandExpressive
    readonly property real defaultModuleW: 320
    readonly property real defaultModuleH: 320
    readonly property real defaultDialogW: 480
    readonly property real defaultDialogH: 420

    implicitWidth: morph.implicitWidth
    implicitHeight: morph.implicitHeight

    // Хост (BarWindow) читає це так само, як для окремих MorphSurface-модулів раніше
    readonly property alias overflowTop: morph.overflowTop
    readonly property alias overflowBottom: morph.overflowBottom
    readonly property alias overflowLeft: morph.overflowLeft
    readonly property alias overflowRight: morph.overflowRight
    readonly property alias hitArea: morph.bodyItem

    MorphSurface {
        id: morph
        originX: root.originX
        originY: root.originY
        closeOnEscape: false   // Esc керується тут, через shellState.back() — не власним collapse()

        hoverWidth: root.peekWidth
        hoverHeight: root.peekHeight
        expandedWidth: root.shellState.state === root.shellState.module && root.activeDescriptor
                       ? (root.activeDescriptor.panelWidth || root.defaultModuleW) : root.peekWidth
        expandedHeight: root.shellState.state === root.shellState.module && root.activeDescriptor
                       ? (root.activeDescriptor.panelHeight || root.defaultModuleH) : root.peekHeight
        dialogWidth: root.activeDescriptor ? (root.activeDescriptor.dialogWidth || root.defaultDialogW) : root.defaultDialogW
        dialogHeight: root.activeDescriptor ? (root.activeDescriptor.dialogHeight || root.defaultDialogH) : root.defaultDialogH

        // MorphShellState → MorphSurface.surfaceState (одностороння прив'язка; MorphSurface
        // ніколи сама не пише в свій surfaceState, бо closeOnEscape:false й onClicked нижче
        // ходить через shellState, а не через open()/collapse())
        surfaceState: {
            switch (root.shellState.state) {
            case root.shellState.idle: return "compact"
            case root.shellState.peek: return "expanded"    // те саме "expanded", контент — ряд глімпсів
            case root.shellState.module: return "expanded"  // той самий тір розміру, контент — панель модуля
            case root.shellState.dialog: return "dialog"
            default: return "compact"
            }
        }

        // idle: перший модуль зазвичай "clock" — показуємо його glimpse і як compact-вміст
        compact: [
            Loader {
                sourceComponent: root.modules.length > 0 ? root.modules[0].glimpse : null
            }
        ]

        // peek: ряд глімпсів усіх модулів; клік по глімпсу відкриває його модуль
        hover: [
            Row {
                id: glimpseRow
                anchors.centerIn: parent
                spacing: Theme.space.md
                Repeater {
                    model: root.modules
                    Item {
                        required property var modelData
                        implicitWidth: gl.implicitWidth
                        implicitHeight: gl.implicitHeight
                        Loader { id: gl; sourceComponent: modelData.glimpse }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -Theme.space.xs
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.shellState.openModule(modelData.key)
                        }
                    }
                }
            }
        ]

        // module: повна панель активного модуля
        expanded: [
            Loader {
                anchors.fill: parent
                active: root.shellState.state === root.shellState.module
                sourceComponent: root.activeDescriptor ? root.activeDescriptor.panel : null
            }
        ]

        // dialog: великий стан (Launcher/Settings) — окремий панел, з фолбеком на module panel
        dialog: [
            Loader {
                anchors.fill: parent
                active: root.shellState.state === root.shellState.dialog
                sourceComponent: root.activeDescriptor
                                 ? (root.activeDescriptor.dialogPanel || root.activeDescriptor.panel) : null
            }
        ]

        onClicked: root.shellState.reveal()
    }

    // Слухаємо hover ТОЇ Ж поверхні, що анімується (morph.hovered — над живим body, а не над
    // статичним зовнішнім Item) — HoverHandler з target: morph відстежував би не ту область.
    Connections {
        target: morph
        function onHoveredChanged() {
            if (morph.hovered) root.shellState.hoverEnter()
            else root.shellState.hoverExit()
        }
    }

    // Esc: morph.closeOnEscape=false → подія не accepted → бабблиться сюди природним чином
    // (Qt Quick key-bubbling), forceActiveFocus() усередині MorphSurface лишається без змін.
    Keys.onEscapePressed: root.shellState.back()
}
