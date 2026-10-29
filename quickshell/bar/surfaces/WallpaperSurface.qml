import "root:/theme"
import "root:/settings"
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel

// ==========================================================================
// WallpaperSurface.qml — вміст (без вікна) для Pill-режиму. Логіка й
// команда застосування 1:1 взяті з Wallpaper/Panel.qml (той файл
// НЕ чіпався) — тут тільки перевикористання, без нових залежностей.
// ==========================================================================

Item {
    id: root

    property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property bool nothing: Theme.settings.nothing
    property string selectedCategory: "All"
    property var colorIndex: ({})
    property var availableCategories: ["All", "Blue", "Purple", "Pink", "Red", "Orange", "Yellow", "Green", "Cyan", "Monochrome", "Other"]

    function refreshVisibleFiles() {
        visibleFiles.clear()
        for (let i = 0; i < staticModel.count; i++) {
            // FolderListModel.get(index, roleName) returns ONE role value, not an object.
            const pathValue = staticModel.get(i, "filePath") || ""
            if (!pathValue) continue
            const nameValue = staticModel.get(i, "fileName") || pathValue.split("/").pop()
            const category = colorIndex[pathValue] || colorIndex[decodeURIComponentSafe(pathValue)] || "Other"
            if (root.selectedCategory !== "All" && category !== root.selectedCategory) continue
            visibleFiles.append({ filePath: pathValue, fileName: nameValue, category: category })
        }
    }

    function decodeURIComponentSafe(value) {
        try { return decodeURIComponent(value) } catch (e) { return value }
    }

    ListModel { id: visibleFiles }

    FileView {
        id: colorIndexFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-colors.json"
        watchChanges: true
        printErrors: false
        onTextChanged: {
            try {
                const data = JSON.parse(text())
                root.colorIndex = data.items || ({})
            } catch (e) {
                console.warn("Wallpaper picker: cannot read color index:", e)
                root.colorIndex = ({})
            }
            root.refreshVisibleFiles()
        }
        Component.onCompleted: reload()
    }

    Process {
        id: applyProc

        function apply(path) {
            if (running) {
                running = false
            }

            command = ["sh", "-c",
                "awww img -t wave '" + path + "' && python3 " +
                Quickshell.env("HOME") + "/.config/mango/scripts/wallcolors.py '" + path + "'"
            ]
            running = true
        }
    }

    FolderListModel {
        id: staticModel
        folder: "file://" + root.wallpaperDir
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        showDirs: false
        sortField: FolderListModel.Name
        onCountChanged: root.refreshVisibleFiles()
        onStatusChanged: root.refreshVisibleFiles()
    }

    FolderListModel {
        id: animatedModel
        folder: "file://" + root.wallpaperDir
        nameFilters: ["*.gif", "*.GIF"]
        showDirs: false
        sortField: FolderListModel.Name
    }

    Text {
        anchors.centerIn: parent
        visible: staticModel.count === 0 && animatedModel.count === 0
        text: Lang.t("wall.empty").replace("{dir}", root.wallpaperDir)
        color: Colors.grey1
        font { family: Colors.uiFont; pixelSize: 11 }
    }

    Text {
        anchors.centerIn: parent
        visible: staticModel.count > 0 && visibleFiles.count === 0 && root.selectedCategory !== "All"
        text: Lang.t("wall.emptyFilter")
        color: Colors.grey1
        font { family: Colors.uiFont; pixelSize: 11 }
    }

    Component {
        id: wallpaperGridDelegate
        ClippingRectangle {
            id: thumb
            required property string filePath
            required property string fileName

            width: GridView.view.cellWidth - 6
            height: GridView.view.cellHeight - 6
            radius: root.nothing ? ThemeNothing.corners.md - 4 : 10
            color: Colors.bg2

            property bool hovered: gridHoverArea.containsMouse

            // Material: акцентна рамка 2px і пружинний zoom. Nothing: тонка світла рамка, спокійний zoom.
            border.width: hovered ? (root.nothing ? 1 : 2) : 0
            border.color: root.nothing ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.85) : Colors.accent

            Behavior on border.width {
                NumberAnimation { duration: 120 }
            }
            Behavior on scale {
                SpringAnimation { spring: root.nothing ? 6 : 4; damping: root.nothing ? 0.6 : 0.35 }
            }
            scale: hovered ? (root.nothing ? 1.03 : 1.05) : 1.0

            Image {
                anchors.fill: parent
                source: "file://" + thumb.filePath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 160
                sourceSize.height: 100
                mipmap: true
            }

            MouseArea {
                id: gridHoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: applyProc.apply(thumb.filePath)
            }
        }
    }

    Component.onCompleted: refreshVisibleFiles()

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Flow {
            id: categoryFlow
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            spacing: 4
            Repeater {
                model: root.availableCategories
                Rectangle {
                    required property string modelData
                    readonly property bool active: root.selectedCategory === modelData
                    width: chipRow.implicitWidth + 22
                    height: 28
                    radius: 14
                    // Material: активна — суцільний акцент. Nothing: контурна «пігулка» з червоною крапкою.
                    color: root.nothing
                        ? (active ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.10) : "transparent")
                        : (active ? Colors.accent : Colors.bg2)
                    border.width: root.nothing ? 1 : (active ? 0 : 1)
                    border.color: root.nothing
                        ? (active ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.70) : Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.20))
                        : Colors.bg4
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 5
                        Rectangle {
                            visible: root.nothing
                            width: parent.parent.active ? 4 : 0
                            height: 4; radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: ThemeNothing.red
                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            id: categoryLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.nothing ? Lang.t("wall.cat." + modelData).toUpperCase() : Lang.t("wall.cat." + modelData)
                            color: root.nothing ? (parent.parent.active ? Colors.fg : Colors.grey1)
                                               : (parent.parent.active ? Colors.onAccent : Colors.fg)
                            font {
                                family: root.nothing ? Theme.type.mono : Colors.uiFont
                                pixelSize: root.nothing ? 9 : 10
                                letterSpacing: root.nothing ? 1.5 : 0
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.selectedCategory = modelData; root.refreshVisibleFiles() }
                    }
                }
            }
        }

        GridView {
            id: staticGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.62
            model: visibleFiles
            delegate: wallpaperGridDelegate
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.bg4
            visible: animatedModel.count > 0 && root.selectedCategory === "All"
        }

        GridView {
            id: animatedGrid
            Layout.fillWidth: true
            Layout.preferredHeight: (animatedModel.count > 0 && root.selectedCategory === "All") ? (parent.height * 0.32) : 0
            visible: animatedModel.count > 0 && root.selectedCategory === "All"
            clip: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.62
            model: animatedModel
            delegate: wallpaperGridDelegate
        }
    }
}
