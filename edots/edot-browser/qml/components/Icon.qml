import QtQuick

// Material-іконка з image://icon (малює C++ з SVG-контурів)
Item {
    id: root
    property string name: ""
    property real size: 24
    property color color: "white"

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        smooth: true
        asynchronous: false
        source: root.name ? "image://icon/" + root.name + "/" + String(root.color).replace("#", "") : ""
    }
}
