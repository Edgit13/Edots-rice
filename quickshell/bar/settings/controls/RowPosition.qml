pragma ComponentBehavior: Bound
import "root:/theme"
import ".."
import "../material"
import QtQuick
import QtQuick.Layouts

// RowPosition — вибір позиції на екрані: міні-монітор 3×3, вибрана позиція — primary-пігулка,
// що їде між клітинками і міняє форму (горизонтальна / вертикальна / кут / центр).
RowLayout {
    id: r
    required property string cat
    required property string key
    required property var field

    Layout.fillWidth: true
    spacing: Theme.space.md
    visible: SettingsSearch.matches(Lang.searchText(r.cat, r.key, r.field))

    readonly property string value: String(Settings.get(r.cat, r.key))
    readonly property var grid: [
        ["top-left", "top", "top-right"],
        ["left", "center", "right"],
        ["bottom-left", "bottom", "bottom-right"]
    ]
    function rcOf(p) {
        for (let i = 0; i < 3; i++)
            for (let j = 0; j < 3; j++)
                if (r.grid[i][j] === p) return { r: i, c: j }
        return { r: 2, c: 1 }
    }
    readonly property var rc: rcOf(value)

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        ThemedText {
            Layout.fillWidth: true
            text: Lang.label(r.cat, r.key, r.field)
            style: Theme.type.bodyLarge
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

    ResetDot { cat: r.cat; key: r.key }

    Rectangle {
        id: frame
        Layout.preferredWidth: Theme.components.dp(168)
        Layout.preferredHeight: Theme.components.dp(104)
        radius: Theme.shape.md
        color: Theme.color.surfaceContainerHighest
        border.width: 1
        border.color: Theme.color.outlineVariant

        Item {
            id: area
            anchors.fill: parent
            anchors.margins: Theme.space.sm
            readonly property real cw: width / 3
            readonly property real ch: height / 3

            Repeater {
                model: 9
                Item {
                    id: cell
                    required property int index
                    readonly property int row: Math.floor(index / 3)
                    readonly property int col: index % 3
                    x: col * area.cw
                    y: row * area.ch
                    width: area.cw
                    height: area.ch

                    Rectangle {                       // крапка клітинки
                        anchors.centerIn: parent
                        width: ma.containsMouse ? Theme.components.dp(10) : Theme.components.dp(6)
                        height: width
                        radius: width / 2
                        color: Theme.color.outline
                        opacity: ma.containsMouse ? 0.9 : 0.5
                        Behavior on width { MotionAnimation { role: "press" } }
                        Behavior on opacity { MotionAnimation { role: "hover" } }
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.set(r.cat, r.key, r.grid[cell.row][cell.col])
                    }
                }
            }

            // вибір
            Rectangle {
                id: pill
                readonly property bool horiz: r.rc.c === 1 && r.rc.r !== 1
                readonly property bool vert: r.rc.r === 1 && r.rc.c !== 1
                readonly property bool corner: r.rc.r !== 1 && r.rc.c !== 1
                width: horiz ? Theme.components.dp(40) : vert ? Theme.components.dp(12)
                     : corner ? Theme.components.dp(22) : Theme.components.dp(26)
                height: horiz ? Theme.components.dp(12) : vert ? Theme.components.dp(36)
                      : corner ? Theme.components.dp(22) : Theme.components.dp(26)
                radius: corner ? Theme.shape.radius("lg", height) : Math.min(width, height) / 2
                color: Theme.color.primary
                x: (r.rc.c + 0.5) * area.cw - width / 2
                y: (r.rc.r + 0.5) * area.ch - height / 2
                Behavior on x { MotionAnimation { role: "move" } }
                Behavior on y { MotionAnimation { role: "move" } }
                Behavior on width { MotionAnimation { role: "morph" } }
                Behavior on height { MotionAnimation { role: "morph" } }
                Behavior on radius { MotionAnimation { role: "morph" } }
            }
        }
    }
}
