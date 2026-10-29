import "root:/theme"
import "root:/settings"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

// Дизайн Nothing: контурне (hairline) поле пошуку, червоний каретка, вибраний рядок — легка заливка + контур
// і червона крапка-індикатор замість суцільної акцентної заливки; підзаголовки — моно-капсом.
// LauncherSurface — Material 3 + LauncherService (ДжЕРЕЛО ДАНИХ: appIndex
// python-сканер .desktop). Поведінка: фокус у пошуку одразу, фільтрація через
// LauncherService.query, навігація ↑↓/Enter, клік — запуск.
Item {
    id: root

    signal appLaunched

    readonly property bool nothing: Theme.settings.nothing

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
            height: root.nothing ? 44 : 40
            radius: root.nothing ? ThemeNothing.corners.md - 2 : 20
            color: root.nothing ? "transparent" : Colors.bg1
            border.width: root.nothing ? 1 : (searchInput.activeFocus ? 2 : 1)
            border.color: root.nothing
                ? (searchInput.activeFocus ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.75) : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.22))
                : (searchInput.activeFocus ? Colors.accent : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.25))
            Behavior on border.color { ColorAnimation { duration: 160 } }

            TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.fg
                font { family: Colors.uiFont; pixelSize: 12 }
                selectionColor: root.nothing ? ThemeNothing.red : Colors.accent
                selectedTextColor: root.nothing ? "#FFFFFF" : Colors.onAccent
                cursorDelegate: root.nothing ? nothingCaret : null
                focus: true
                selectByMouse: true
                clip: true
                text: LauncherService.query
                onTextChanged: if (LauncherService.query !== text) LauncherService.query = text

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    verticalAlignment: Text.AlignVCenter
                    text: root.nothing ? Lang.t("ui.launcher.search").toUpperCase() : Lang.t("ui.launcher.search")
                    color: Colors.grey2
                    visible: searchInput.text.length === 0
                    font {
                        family: root.nothing ? Theme.type.mono : searchInput.font.family
                        pixelSize: root.nothing ? 10 : searchInput.font.pixelSize
                        letterSpacing: root.nothing ? 2 : 0
                    }
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

        Component {
            id: nothingCaret
            Rectangle { width: 2; color: ThemeNothing.red }
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
                height: root.nothing ? 52 : 48
                radius: root.nothing ? ThemeNothing.corners.md - 2 : 8
                readonly property bool current: LauncherService.selectedIndex === index
                // Material: суцільний акцент і «on»-текст. Nothing: легка заливка + контур, текст лишається звичайним.
                readonly property bool solid: current && !root.nothing
                readonly property color titleColor: solid ? Colors.onAccent : Colors.fg
                readonly property color subColor: solid ? Colors.onAccent : Colors.grey2
                color: solid ? Colors.accent
                    : current ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.07)
                    : (rowMouse.containsMouse ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.05) : "transparent")
                border.width: current ? 1 : 0
                border.color: root.nothing ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.30) : Colors.accent
                Behavior on color { ColorAnimation { duration: 140 } }

                // індикатор вибору (Nothing): червона крапка, що «вискакує»
                Rectangle {
                    visible: root.nothing
                    x: 9
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6; height: 6; radius: 3
                    color: ThemeNothing.red
                    opacity: appRow.current ? 1 : 0
                    scale: appRow.current ? 1 : 0.2
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: root.nothing ? 24 : 12
                    anchors.rightMargin: 12
                    spacing: 12
                    Behavior on anchors.leftMargin { NumberAnimation { duration: 160 } }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: root.nothing ? 9 : 6
                        color: appRow.solid ? Colors.onAccent : Colors.bg2
                        border.width: root.nothing ? 1 : 0
                        border.color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.14)
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
                            color: appRow.titleColor
                            font { family: Colors.uiFont; pixelSize: 12; weight: 500 }
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: (modelData.genericName || "") !== ""
                            text: root.nothing ? modelData.genericName.toUpperCase() : modelData.genericName
                            color: appRow.subColor
                            opacity: appRow.solid ? 0.85 : 1.0
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            font {
                                family: root.nothing ? Theme.type.mono : Colors.uiFont
                                pixelSize: root.nothing ? 9 : 10
                                letterSpacing: root.nothing ? 1.5 : 0
                            }
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
