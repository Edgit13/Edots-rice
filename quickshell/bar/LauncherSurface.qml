import "root:/"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// LauncherSurface — Material 3 + LauncherService (ДжЕРЕЛО ДАНИХ: appIndex
// python-сканер .desktop). Поведінка: фокус у пошуку одразу, фільтрація через
// LauncherService.query, навігація ↑↓/Enter, клік — запуск.
Item {
    id: root

    signal appLaunched

    onVisibleChanged: {
        if (visible) {
            LauncherService.reset()
            Qt.callLater(() => searchInput.forceActiveFocus())
        }
    }
    Component.onCompleted: {
        Qt.callLater(() => searchInput.forceActiveFocus())
    }

    Item {
        anchors.fill: parent

        // ---- M3 search field ----
        Rectangle {
            id: searchBox
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 40
            radius: 20
            color: Colors.bg1
            border.width: searchInput.activeFocus ? 2 : 1
            border.color: searchInput.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.25)

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.fg
                font { family: "SF Pro Display"; pixelSize: 12 }
                focus: true
                selectByMouse: true
                clip: true
                text: LauncherService.query
                onTextChanged: if (LauncherService.query !== text) LauncherService.query = text

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    verticalAlignment: Text.AlignVCenter
                    text: "Type to search"
                    color: Colors.grey2
                    visible: searchInput.text.length === 0
                    font: searchInput.font
                }

                Keys.onDownPressed: {
                    LauncherService.moveSelection(1)
                    event.accepted = true
                }
                Keys.onUpPressed: {
                    LauncherService.moveSelection(-1)
                    event.accepted = true
                }
                Keys.onReturnPressed: {
                    LauncherService.launchSelected()
                    root.appLaunched()
                }
            }
        }

        // ---- results ----
        ListView {
            id: appList
            anchors.top: searchBox.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            clip: true
            spacing: 4
            highlightMoveDuration: 0
            focus: false

            model: LauncherService.results
            currentIndex: LauncherService.selectedIndex
            onCurrentIndexChanged: if (LauncherService.selectedIndex !== currentIndex)
                LauncherService.selectedIndex = currentIndex

            delegate: Rectangle {
                id: appRow
                width: appList.width
                height: 48
                radius: 8
                readonly property bool current: LauncherService.selectedIndex === index
                color: current ? Colors.accent
                    : (rowMouse.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.08) : "transparent")
                border.width: current ? 1 : 0
                border.color: Colors.accent
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 6
                        color: appRow.current ? Colors.bg0 : Colors.bg2
                        Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            source: modelData.icon
                                ? Quickshell.iconPath(modelData.icon) : Quickshell.iconPath("application-x-executable")
                            smooth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: modelData.name
                            color: appRow.current ? Colors.bg0 : Colors.fg
                            font { family: "SF Pro Display"; pixelSize: 12; weight: 500 }
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: (modelData.genericName || "") !== ""
                            text: modelData.genericName
                            color: appRow.current ? Colors.bg0 : Colors.grey2
                            opacity: appRow.current ? 0.85 : 1.0
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font { family: "SF Pro Display"; pixelSize: 10 }
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: LauncherService.selectedIndex = index
                    onClicked: {
                        LauncherService.launch(modelData)
                        root.appLaunched()
                    }
                }
            }
        }
    }
}
