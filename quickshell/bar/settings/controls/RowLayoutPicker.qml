pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

// RowLayoutPicker — вибір розкладки вікон: плитки з міні-схемою; вибрана плитка морфиться (primaryContainer).
ColumnLayout {
    id: r
    required property string cat
    required property string key
    required property var field

    Layout.fillWidth: true
    spacing: Theme.space.sm
    visible: SettingsSearch.matches(Lang.searchText(r.cat, r.key, r.field))

    readonly property string value: String(Settings.get(r.cat, r.key))

    // [x, y, w, h, (opacity)] у частках плитки
    readonly property var shapes: ({
        "tile":              [[0, 0, .55, 1], [.55, 0, .45, .5], [.55, .5, .45, .5]],
        "right_tile":        [[.45, 0, .55, 1], [0, 0, .45, .5], [0, .5, .45, .5]],
        "vertical_tile":     [[0, 0, 1, .55], [0, .55, .5, .45], [.5, .55, .5, .45]],
        "center_tile":       [[.27, 0, .46, 1], [0, 0, .27, 1], [.73, 0, .27, 1]],
        "grid":              [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, .5, .5], [.5, .5, .5, .5]],
        "vertical_grid":     [[0, 0, .5, .33], [.5, 0, .5, .33], [0, .33, .5, .33], [.5, .33, .5, .33], [0, .66, .5, .34], [.5, .66, .5, .34]],
        "fair":              [[0, 0, .5, .5], [.5, 0, .5, .5], [0, .5, 1, .5]],
        "vertical_fair":     [[0, 0, .5, .5], [0, .5, .5, .5], [.5, 0, .5, 1]],
        "monocle":           [[0, 0, 1, 1, .45], [.12, .14, .76, .72]],
        "deck":              [[0, 0, .55, 1], [.55, 0, .45, 1, .35], [.62, .1, .38, .8]],
        "vertical_deck":     [[0, 0, 1, .55], [0, .55, 1, .45, .35], [.1, .62, .8, .38]],
        "scroller":          [[-.2, .1, .46, .8, .45], [.3, .1, .46, .8], [.8, .1, .46, .8, .45]],
        "vertical_scroller": [[.1, -.2, .8, .46, .45], [.1, .3, .8, .46], [.1, .8, .8, .46, .45]],
        "dwindle":           [[0, 0, .5, 1], [.5, 0, .5, .5], [.5, .5, .25, .5], [.75, .5, .25, .5]]
    })

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        RowLayout {
            Layout.fillWidth: true
            ThemedText {
                Layout.fillWidth: true
                text: Lang.label(r.cat, r.key, r.field)
                style: Theme.type.bodyLarge
            }
            ResetDot { cat: r.cat; key: r.key }
        }
        ThemedText {
            Layout.fillWidth: true
            visible: Lang.desc(r.cat, r.key, r.field).length > 0
            text: Lang.desc(r.cat, r.key, r.field)
            style: Theme.type.bodySmall
            color: Theme.color.fgSurfaceVariant
            wrapMode: Text.Wrap
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: Theme.space.sm

        Repeater {
            model: r.field.options || []

            Rectangle {
                id: tile
                required property string modelData
                readonly property bool sel: r.value === modelData
                readonly property color fg: sel ? Theme.color.fgPrimaryContainer : Theme.color.fgSurfaceVariant

                width: Theme.components.dp(96)
                height: Theme.components.dp(80)
                radius: ma.pressed ? Theme.shape.sm : (sel ? Theme.shape.radius("lg", height) : Theme.shape.md)
                color: sel ? Theme.color.primaryContainer : Theme.color.surfaceContainerHighest
                Behavior on radius { MotionAnimation { role: "morph" } }
                Behavior on color { MotionColorAnimation { role: "stateChange" } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: tile.fg
                    opacity: ma.pressed ? Theme.components.statePressed : (ma.containsMouse ? Theme.components.stateHover : 0)
                    Behavior on opacity { MotionAnimation { role: "hover" } }
                }

                // міні-схема
                Item {
                    id: diagram
                    anchors.top: parent.top
                    anchors.topMargin: Theme.space.sm
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Theme.components.dp(68)
                    height: Theme.components.dp(40)
                    clip: true

                    Repeater {
                        model: r.shapes[tile.modelData] || []
                        Rectangle {
                            required property var modelData
                            x: modelData[0] * diagram.width + 1
                            y: modelData[1] * diagram.height + 1
                            width: Math.max(2, modelData[2] * diagram.width - 2)
                            height: Math.max(2, modelData[3] * diagram.height - 2)
                            radius: 2
                            color: tile.fg
                            opacity: modelData.length > 4 ? modelData[4] : 0.9
                            Behavior on color { MotionColorAnimation { role: "stateChange" } }
                        }
                    }
                }

                ThemedText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.space.sm
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - Theme.space.sm
                    horizontalAlignment: Text.AlignHCenter
                    text: Lang.t("ui.layout." + tile.modelData)
                    style: Theme.type.labelSmall
                    emphasized: tile.sel
                    color: tile.fg
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.set(r.cat, r.key, tile.modelData)
                }
            }
        }
    }
}
