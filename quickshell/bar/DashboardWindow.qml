import "root:/theme"
import "root:/dashboard"
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

// DashboardWindow — M3 Expressive правий сайдбар: вкладки Dashboard/Media/Performance/
// Workspaces, заокруглені картки. Архітектура (вкладки, заокруглення, розташування карток)
// орієнтована на референс користувача; аватар/OS/WM/погода/CPU-RAM-диск/теги — наші реальні дані.
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
        anchors { top: true; bottom: true; right: true }
        implicitWidth: 440

        function open() { win.visible = true }
        function close() { win.visible = false }
        function toggle() { win.visible ? win.close() : win.open() }

        readonly property var tabs: [
            { key: "dashboard", label: "Огляд", icon: "\ue871" },
            { key: "media", label: "Медіа", icon: "\ue405" },
            { key: "performance", label: "Продуктивність", icon: "\ue9e4" },
            { key: "workspaces", label: "Робочі місця", icon: "\ue8f9" }
        ]
        property int activeTab: 0

        // клік по прозорій частині (лівіше картки) — закриває
        MouseArea { anchors.fill: parent; onClicked: win.close() }

        Item {
            id: card
            anchors.fill: parent
            anchors.margins: Theme.space.md
            focus: win.visible
            Keys.onEscapePressed: win.close()

            // сама картка перехоплює клік, щоб не закривалось при взаємодії з вмістом
            MouseArea { anchors.fill: parent; onClicked: {} }

            ElevationShadow {
                anchors.fill: parent
                level: Theme.elevation.overlay
                radius: Theme.shape.islandDialog
                color: Theme.color.surfaceContainerLow
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.space.md
                spacing: Theme.space.md

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

                // ---- вміст вкладки (Loader — щоб не тримати опитування неактивних вкладок) ----
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
        }
    }

    Component {
        id: overviewComp
        Flickable {
            clip: true
            contentWidth: width
            contentHeight: col.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: col
                width: parent.width
                spacing: Theme.space.md
                SystemCard { Layout.fillWidth: true }
                WeatherCard { Layout.fillWidth: true }
                CalendarCard { Layout.fillWidth: true }
            }
        }
    }
    Component { id: mediaComp; MediaTab {} }
    Component { id: perfComp; PerformanceTab {} }
    Component { id: wsComp; WorkspacesTab {} }
}
