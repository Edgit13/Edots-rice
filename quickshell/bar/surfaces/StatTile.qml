import "root:/theme"
import QtQuick
import QtQuick.Layouts

// Плитка зі значком і значенням для connected-групи.
Rectangle {
    id: st

    property string icon: ""
    property string label: ""
    property string value: ""
    property real bar: -1
    property color accent: Theme.color.primary
    property real rLeft: Theme.shape.listInner
    property real rRight: Theme.shape.listInner

    implicitHeight: Theme.components.dp(76)
    // Nothing: прозора плитка з тонким контуром замість тональної заливки
    color: Theme.settings.nothing ? "transparent" : Theme.color.surfaceContainer
    border.width: Theme.settings.nothing ? 1 : 0
    border.color: Qt.rgba(Theme.color.fgSurface.r, Theme.color.fgSurface.g, Theme.color.fgSurface.b, 0.16)
    topLeftRadius: rLeft
    bottomLeftRadius: rLeft
    topRightRadius: rRight
    bottomRightRadius: rRight

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.space.md
        spacing: Theme.space.xs

        RowLayout {
            spacing: Theme.space.xs
            Text {
                text: st.icon
                color: st.accent
                font { family: Theme.type.icons; pixelSize: Theme.type.iconS }
            }
            ThemedText {
                Layout.fillWidth: true
                text: st.label
                style: Theme.type.labelSmall
                color: Theme.color.fgSurfaceVariant
                elide: Text.ElideRight
            }
        }

        ThemedText {
            Layout.fillWidth: true
            text: st.value
            style: Theme.type.titleSmall
            emphasized: true
            elide: Text.ElideRight
        }

        UsageBar {
            visible: st.bar >= 0
            Layout.fillWidth: true
            value: Math.max(0, st.bar) / 100
            active: st.accent
            thickness: Theme.components.dp(5)
        }
        Item { visible: st.bar < 0; Layout.fillHeight: true }
    }
}
