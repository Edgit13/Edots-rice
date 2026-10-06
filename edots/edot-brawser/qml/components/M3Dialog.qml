import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Модальний діалог M3 (радіус 28, scrim)
Popup {
    id: dlg
    readonly property var c: theme.c
    property string title: ""
    property string body: ""
    property string confirmText: "Гаразд"
    property string cancelText: "Скасувати"
    property bool danger: false
    property bool confirmEnabled: true
    default property alias extra: extraCol.data
    signal confirmed()

    parent: Overlay.overlay
    anchors.centerIn: parent
    modal: true
    dim: true
    focus: true
    padding: 24
    width: Math.min(400, (parent ? parent.width : 400) - 48)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.32) }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: theme.animations ? 150 : 0 }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: theme.animations ? 100 : 0 }
    }
    background: Rectangle {
        radius: 28
        color: c.surface_container_high
        border.width: 1
        border.color: c.outline_variant
    }
    contentItem: ColumnLayout {
        spacing: 16
        Text {
            Layout.fillWidth: true
            text: dlg.title
            color: c.on_surface
            font.pixelSize: 24
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            visible: dlg.body !== ""
            text: dlg.body
            color: c.on_surface_variant
            font.pixelSize: 14
            wrapMode: Text.WordWrap
        }
        ColumnLayout { id: extraCol; Layout.fillWidth: true; spacing: 8 }
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Item { Layout.fillWidth: true }
            M3Button { text: dlg.cancelText; kind: "text"; onClicked: dlg.close() }
            M3Button {
                text: dlg.confirmText
                kind: dlg.danger ? "dangerText" : "text"
                enabled: dlg.confirmEnabled
                onClicked: { dlg.close(); dlg.confirmed() }
            }
        }
    }
}
