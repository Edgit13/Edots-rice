pragma ComponentBehavior: Bound

import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Phase 5 — Bar/Dashboard: позиція панелі, видимість і порядок модулів.
// Усе реальне: pill читає modules.order / modules.* / bar.position напряму.

Item {
    id: pageBarRoot
    implicitHeight: barCol.implicitHeight


    Process {
        id: gmProc
        command: ["sh", "-c",
            'for f in "$HOME/.config/quickshell/scripts/gamemode.sh" "$HOME/edots/scripts/gamemode.sh"; do [ -f "$f" ] && exec bash "$f"; done']
    }

    function pretty(id) {
        return id.charAt(0).toUpperCase() + id.slice(1)
    }

    function moveModule(id, dir) {
        const order = (Config.get("modules", "order") || []).slice()
        const i = order.indexOf(id)
        const j = i + dir
        if (i < 0 || j < 0 || j >= order.length)
            return
        const t = order[i]
        order[i] = order[j]
        order[j] = t
        Config.set("modules", "order", order)
    }

    ColumnLayout {
        id: barCol
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 10

        SectionLabel { label: "Bar" }

        Card {
            title: "Panel"

            DropdownRow {
                category: "bar"; configKey: "position"
                label: "Panel position"
                options: ["top", "bottom"]
                description: "Anchor the pill and its screen reservation."
            }
        }

        Card {
            title: "Blur"

            SwitchRow {
                category: "blur"; configKey: "enabled"
                label: "Backdrop blur"
                description: "Writes blur_layer to MangoWM config and hot-reloads it. Visible behind translucent surfaces (e.g. Dashboard)."
            }
            SliderRow {
                category: "blur"; configKey: "strength"
                label: "Blur strength"; from: 0; to: 30; suffix: " px"
                description: "MangoWM blur_params_radius."
            }
        }

        Card {
            title: "Game Mode"

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 34
                radius: 9
                color: Colors.bg1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: GameModeState.active ? "Game Mode: ON" : "Game Mode: OFF"
                        color: GameModeState.active ? Colors.accent : Colors.fg
                        font { family: "SF Pro Display"; pixelSize: 12; weight: 600 }
                    }

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 22
                        radius: 11
                        color: GameModeState.active ? Colors.accent : Colors.bg4
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Rectangle {
                            width: 16; height: 16; radius: 8; y: 3
                            x: GameModeState.active ? parent.width - width - 3 : 3
                            color: Colors.bg0
                            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: gmProc.running = true
                        }
                    }
                }
            }


            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                text: "ON: the bar hides completely, animations and blur turn off, notifications go DND, CPU performance governor (via gamemode.sh)."
                color: Colors.grey1
                font { family: "SF Pro Display"; pixelSize: 10 }
            }
        }

        Card {
            title: "Modules"

            Text {
                Layout.fillWidth: true
                text: "Toggle what appears when you hover the pill."
                color: Colors.grey1
                font { family: "SF Pro Display"; pixelSize: 10 }
            }

            Repeater {
                model: Config.get("modules", "order") || []
                SwitchRow {
                    required property var modelData
                    category: "modules"
                    configKey: modelData
                    label: pageBarRoot.pretty(modelData)
                }
            }
        }

        Card {
            title: "Module order"

            Text {
                Layout.fillWidth: true
                text: "Order of items in the hover bar."
                color: Colors.grey1
                font { family: "SF Pro Display"; pixelSize: 10 }
            }

            Repeater {
                model: Config.get("modules", "order") || []
                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 8
                    color: Qt.rgba(Colors.bg2.r, Colors.bg2.g, Colors.bg2.b, 0.72)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: pageBarRoot.pretty(modelData)
                            color: Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
                        }

                        Text {
                            text: "\u2191"
                            color: upHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 13 }
                            HoverHandler { id: upHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pageBarRoot.moveModule(modelData, -1)
                            }
                        }

                        Text {
                            text: "\u2193"
                            color: downHover.hovered ? Colors.accent : Colors.grey1
                            font { family: "SF Pro Display"; pixelSize: 13 }
                            HoverHandler { id: downHover }
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pageBarRoot.moveModule(modelData, 1)
                            }
                        }
                    }
                }
            }
        }

        Card {
            title: "Dashboard"

            InfoRow {
                title: "Popup size and radius"
                detail: "Expanded width/height and surface corner radius live on the Pill page."
            }
            InfoRow {
                title: "Blur"
                detail: "Backdrop blur is compositor-side (MangoWM); not controllable from the shell."
            }
        }
    }
}
