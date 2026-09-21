import "root:/theme"
import "root:/shell"
import Quickshell
import QtQuick
import QtQuick.Layouts

// Stage 3 — перевірка MorphSurface:
//   qs -p ~/.config/quickshell/bar/MorphPreview.qml
// Hover по годиннику → hover-pill; клік → expanded; кнопки внизу → усі стани; Esc → згортає.
ShellRoot {
    FloatingWindow {
        id: win
        visible: true
        implicitWidth: 1000
        implicitHeight: 640
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
            ThemedText { id: lbl; anchors.centerIn: parent; text: seg.label; style: Theme.type.labelLarge
                         color: seg.active ? Theme.color.fgPrimary : Theme.color.fgSurface }
            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: seg.clicked() }
        }

        // фон-«бар»
        Rectangle {
            id: strip
            x: 24; y: 24
            width: parent.width - 48
            height: 48
            radius: height / 2
            color: Theme.color.surfaceContainer
        }

        // scrim для dialog (нижче поверхонь)
        Rectangle {
            anchors.fill: parent
            z: 500
            color: Theme.color.scrim
            opacity: clock.scrimOpacity
            visible: opacity > 0.001
            MouseArea { anchors.fill: parent; enabled: parent.visible; onClicked: clock.collapse() }
        }

        // 1) Годинник по центру — росте вниз від центру
        Item {
            x: (strip.width - width) / 2 + strip.x
            y: strip.y + (strip.height - height) / 2
            width: clock.implicitWidth; height: clock.implicitHeight
            z: clock.z
            MorphSurface {
                id: clock
                originX: 0.5; originY: 0
                dialogParent: win.contentItem
                hoverWidth: 300; hoverHeight: 40
                expandedWidth: 360; expandedHeight: 220
                dialogWidth: 440; dialogHeight: 260
                compact: [ ThemedText { text: "12:42"; style: Theme.type.monoMedium; emphasized: true } ]
                hover: [ ThemedText { anchors.centerIn: parent; text: "12:42   ·   Wi-Fi   ·   Vol   ·   82%"; style: Theme.type.labelLarge } ]
                expanded: [
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.space.sm
                        ThemedText { text: "12:42"; style: Theme.type.displaySmall }
                        ThemedText { text: "Понеділок, 21 вересня"; style: Theme.type.bodyLarge; color: Theme.color.fgSurfaceVariant }
                        Item { Layout.fillHeight: true }
                        RowLayout { spacing: Theme.space.sm
                            Seg { label: "Dialog"; onClicked: clock.openDialog() }
                            Seg { label: "Згорнути"; onClicked: clock.collapse() } }
                    }
                ]
                dialog: [
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Theme.space.md
                        ThemedText { text: "Dialog surface"; style: Theme.type.headlineSmall }
                        ThemedText { Layout.fillWidth: true; wrapMode: Text.WordWrap; style: Theme.type.bodyMedium; color: Theme.color.fgSurfaceVariant
                                     text: "Та сама поверхня, що виросла з пігулки в барі й центрується у вікні. Esc або клік по scrim — назад." }
                        Item { Layout.fillHeight: true }
                        RowLayout { Layout.alignment: Qt.AlignRight; spacing: Theme.space.sm
                            Seg { label: "Закрити"; onClicked: clock.collapse() } }
                    }
                ]
                onClicked: if (surfaceState === "compact") open()
            }
        }

        // 2) Лівий край: origin 0 — росте вправо
        Item {
            x: strip.x + 8
            y: strip.y + (strip.height - height) / 2
            width: left.implicitWidth; height: left.implicitHeight
            z: left.z
            MorphSurface {
                id: left
                originX: 0; originY: 0
                expandedWidth: 260; expandedHeight: 160
                compact: [ ThemedText { text: "Edots"; style: Theme.type.labelLarge; emphasized: true } ]
                expanded: [
                    ColumnLayout { anchors.fill: parent
                        ThemedText { text: "Origin: top-left"; style: Theme.type.titleMedium }
                        ThemedText { text: "Ріст вправо-вниз"; style: Theme.type.bodyMedium; color: Theme.color.fgSurfaceVariant } }
                ]
                onClicked: toggle()
            }
        }

        // 3) Правий край: origin 1 — росте вліво
        Item {
            x: strip.x + strip.width - width - 8
            y: strip.y + (strip.height - height) / 2
            width: right.implicitWidth; height: right.implicitHeight
            z: right.z
            MorphSurface {
                id: right
                originX: 1; originY: 0
                expandedWidth: 260; expandedHeight: 160
                compact: [ ThemedText { text: "Vol 40%"; style: Theme.type.labelLarge } ]
                expanded: [
                    ColumnLayout { anchors.fill: parent
                        ThemedText { text: "Origin: top-right"; style: Theme.type.titleMedium }
                        ThemedText { text: "Ріст вліво-вниз"; style: Theme.type.bodyMedium; color: Theme.color.fgSurfaceVariant } }
                ]
                onClicked: toggle()
            }
        }

        // ---------- керування ----------
        ColumnLayout {
            x: 24; y: 300
            spacing: Theme.space.md
            ThemedText { text: "Годинник: " + clock.surfaceState + "   hovered=" + clock.hovered + "   pressed=" + clock.pressed
                                + "   busy=" + clock.busy; style: Theme.type.labelLarge }
            RowLayout { spacing: Theme.space.sm
                Repeater { model: ["closed", "compact", "expanded", "dialog"]
                    Seg { required property string modelData; label: modelData
                          active: clock.surfaceState === modelData; onClicked: clock.surfaceState = modelData } } }
            RowLayout { spacing: Theme.space.sm
                Seg { label: "Expressive motion"; active: Theme.settings.expressiveMotion; onClicked: Theme.set("expressiveMotion", !Theme.settings.expressiveMotion) }
                Seg { label: "Reduce motion"; active: Theme.settings.reduceMotion; onClicked: Theme.set("reduceMotion", !Theme.settings.reduceMotion) }
                Seg { label: "Speed ×" + Theme.settings.animationSpeed.toFixed(1)
                      onClicked: Theme.set("animationSpeed", Theme.settings.animationSpeed >= 2 ? 0.5 : Theme.settings.animationSpeed + 0.5) }
                Seg { label: "Corners: " + Theme.settings.cornerStyle
                      onClicked: Theme.set("cornerStyle", Theme.settings.cornerStyle === "material" ? "expressive" : Theme.settings.cornerStyle === "expressive" ? "rounded" : "material") } }
        }
    }
}
