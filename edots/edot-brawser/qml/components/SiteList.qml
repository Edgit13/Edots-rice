import QtQuick
import QtQuick.Layouts

// Список доменів одного типу (довірені / заблоковані) з додаванням і видаленням
ColumnLayout {
    id: root
    readonly property var c: theme.c
    property string mode: "trusted"
    property string title: ""
    property var sites: []
    spacing: 6

    function add() {
        var h = field.text.trim()
        if (h.length === 0) return
        browser.setSitePermission(h, root.mode)
        field.text = ""
    }

    Text {
        text: root.title
        color: c.on_surface
        font.pixelSize: 14
        font.weight: Font.Medium
        leftPadding: 4
    }
    Repeater {
        model: root.sites
        delegate: Rectangle {
            required property string modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 12
            color: c.surface_container_high
            RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 4 }
                Text {
                    Layout.fillWidth: true
                    text: modelData
                    color: c.on_surface
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
                IconButton {
                    icon: "close"
                    size: 32
                    iconSize: 18
                    tip: "Прибрати"
                    onClicked: browser.removeSitePermission(modelData)
                }
            }
        }
    }
    Text {
        visible: root.sites.length === 0
        text: "Список порожній"
        color: c.on_surface_variant
        font.pixelSize: 13
        leftPadding: 4
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        M3Field {
            id: field
            Layout.fillWidth: true
            implicitWidth: 120
            placeholder: "example.com"
            onAccepted: root.add()
        }
        M3Button { text: "Додати"; kind: "tonal"; onClicked: root.add() }
    }
}
