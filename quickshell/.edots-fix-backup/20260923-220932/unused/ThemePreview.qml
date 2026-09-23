import "root:/theme"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Stage 1 — перевірка design system:
//   qs -p ~/.config/quickshell/bar/ThemePreview.qml
// Керування вгорі змінює theme.json наживо (Mode / Dynamic / Corner style / Motion).
ShellRoot {
    FloatingWindow {
        id: win
        visible: true
        implicitWidth: 1040
        implicitHeight: 860
        color: Theme.color.surface

        component Seg: Rectangle {
            id: seg
            property string label: ""
            property bool active: false
            signal clicked()
            implicitHeight: Theme.components.buttonS
            implicitWidth: lbl.implicitWidth + Theme.space.xl * 2
            radius: active ? Theme.shape.button : Theme.shape.md
            color: active ? Theme.color.primary
                          : ma.pressed ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.statePressed)
                          : ma.containsMouse ? Theme.stateLayer(Theme.color.surfaceContainerHigh, Theme.color.fgSurface, Theme.components.stateHover)
                          : Theme.color.surfaceContainerHigh
            Behavior on color { MotionColorAnimation { role: "hover" } }
            Behavior on radius { MotionAnimation { role: "morph" } }
            ThemedText {
                id: lbl
                anchors.centerIn: parent
                text: seg.label
                style: Theme.type.labelLarge
                color: seg.active ? Theme.color.fgPrimary : Theme.color.fgSurface
            }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: seg.clicked() }
        }

        component Row1: RowLayout {
            property string title: ""
            spacing: Theme.space.sm
            ThemedText { text: parent.title; style: Theme.type.labelMedium; color: Theme.color.fgSurfaceVariant
                         Layout.preferredWidth: 120 }
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.space.xl
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true

            ColumnLayout {
                id: col
                width: parent.width
                spacing: Theme.space.xl

                ThemedText {
                    text: "Theme · " + Theme.color.source + " · " + (Theme.dark ? "dark" : "light") + " · fg " + Theme.color.fgSurface
                    style: Theme.type.headlineSmall
                }

                // ---------- controls ----------
                ColumnLayout {
                    spacing: Theme.space.sm
                    Row1 { title: "Mode"
                        Repeater { model: ["system", "light", "dark"]
                            Seg { required property string modelData; label: modelData
                                  active: Theme.settings.mode === modelData; onClicked: Theme.set("mode", modelData) } } }
                    Row1 { title: "Dynamic color"
                        Seg { label: "On";  active: Theme.settings.dynamicColor;  onClicked: Theme.set("dynamicColor", true) }
                        Seg { label: "Off"; active: !Theme.settings.dynamicColor; onClicked: Theme.set("dynamicColor", false) } }
                    Row1 { title: "Accent (custom)"
                        Repeater { model: ["#6750A4", "#0B6BCB", "#C2185B", "#2E7D32", "#E65100"]
                            Rectangle { required property string modelData
                                width: Theme.components.buttonS; height: width; radius: Theme.shape.button; color: modelData
                                border.width: Theme.settings.accent === modelData && !Theme.settings.dynamicColor ? 3 : 0
                                border.color: Theme.color.fgSurface
                                MouseArea { anchors.fill: parent; onClicked: { Theme.set("accent", parent.modelData); Theme.set("dynamicColor", false) } } } } }
                    Row1 { title: "Corner style"
                        Repeater { model: ["material", "expressive", "rounded"]
                            Seg { required property string modelData; label: modelData
                                  active: Theme.settings.cornerStyle === modelData; onClicked: Theme.set("cornerStyle", modelData) } } }
                    Row1 { title: "Motion"
                        Seg { label: "Animations"; active: Theme.settings.animations; onClicked: Theme.set("animations", !Theme.settings.animations) }
                        Seg { label: "Expressive"; active: Theme.settings.expressiveMotion; onClicked: Theme.set("expressiveMotion", !Theme.settings.expressiveMotion) }
                        Seg { label: "Reduce"; active: Theme.settings.reduceMotion; onClicked: Theme.set("reduceMotion", !Theme.settings.reduceMotion) }
                        Seg { label: "Speed ×" + Theme.settings.animationSpeed.toFixed(1)
                              onClicked: Theme.set("animationSpeed", Theme.settings.animationSpeed >= 2 ? 0.5 : Theme.settings.animationSpeed + 0.5) } }
                }

                // ---------- morph demo ----------
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 240
                    Rectangle {
                        id: morph
                        property bool open: false
                        x: 0; y: 0
                        width: open ? 460 : 170
                        height: open ? 220 : Theme.components.islandExpressive
                        radius: open ? Theme.shape.islandExpanded : Theme.shape.island
                        color: open ? Theme.color.surfaceContainerHigh : Theme.color.surfaceContainer
                        Behavior on width { MotionAnimation { role: "morph" } }
                        Behavior on height { MotionAnimation { role: "morph" } }
                        Behavior on radius { MotionAnimation { role: "morph" } }
                        Behavior on color { MotionColorAnimation { role: "stateChange" } }
                        ThemedText { anchors.centerIn: parent; text: morph.open ? "Expanded surface" : "12:42"
                                     style: morph.open ? Theme.type.titleLarge : Theme.type.monoLarge; emphasized: true }
                        MouseArea { anchors.fill: parent; onClicked: morph.open = !morph.open }
                    }
                }

                // ---------- color roles ----------
                GridLayout {
                    columns: 5
                    columnSpacing: Theme.space.sm
                    rowSpacing: Theme.space.sm
                    Layout.fillWidth: true
                    Repeater {
                        model: [
                            ["primary", "fgPrimary"], ["primaryContainer", "fgPrimaryContainer"],
                            ["secondary", "fgSecondary"], ["secondaryContainer", "fgSecondaryContainer"],
                            ["tertiary", "fgTertiary"], ["tertiaryContainer", "fgTertiaryContainer"],
                            ["error", "fgError"], ["errorContainer", "fgErrorContainer"],
                            ["success", "fgSuccess"], ["warning", "fgWarning"],
                            ["surface", "fgSurface"], ["surfaceContainerLow", "fgSurface"],
                            ["surfaceContainer", "fgSurface"], ["surfaceContainerHigh", "fgSurface"],
                            ["surfaceContainerHighest", "fgSurface"], ["surfaceVariant", "fgSurfaceVariant"],
                            ["inverseSurface", "inverseOnSurface"], ["outline", "surface"],
                            ["outlineVariant", "fgSurface"], ["inversePrimary", "fgSurface"]
                        ]
                        Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 56
                            radius: Theme.shape.sm
                            color: Theme.color[modelData[0]]
                            border.width: 1
                            border.color: Theme.color.outlineVariant
                            ThemedText { anchors.centerIn: parent; text: parent.modelData[0]
                                         style: Theme.type.labelSmall; color: Theme.color[parent.modelData[1]] }
                        }
                    }
                }

                // ---------- typography ----------
                ColumnLayout {
                    spacing: 0
                    Repeater {
                        model: ["displaySmall", "headlineMedium", "titleLarge", "titleMedium", "bodyLarge", "bodyMedium", "labelLarge", "labelSmall", "monoLarge"]
                        ThemedText { required property string modelData
                                     text: modelData + " — Quickshell 12:42 Ще один рядок"; style: Theme.type[modelData] }
                    }
                }

                // ---------- shapes + elevation ----------
                RowLayout {
                    spacing: Theme.space.lg
                    Repeater {
                        model: ["xs", "sm", "md", "lg", "xl", "xxl"]
                        Rectangle { required property string modelData
                            width: 96; height: 72; radius: Theme.shape.radius(modelData, height)
                            color: Theme.color.primaryContainer
                            ThemedText { anchors.centerIn: parent; text: modelData; style: Theme.type.labelMedium; color: Theme.color.fgPrimaryContainer } }
                    }
                }
                RowLayout {
                    spacing: Theme.space.xl
                    Layout.bottomMargin: Theme.space.xl
                    Repeater {
                        model: 6
                        ElevationShadow { required property int index
                            level: index; radius: Theme.shape.card
                            Layout.preferredWidth: 100; Layout.preferredHeight: 72
                            ThemedText { anchors.centerIn: parent; text: "L" + parent.level; style: Theme.type.labelLarge } }
                    }
                }
            }
        }
    }
}
