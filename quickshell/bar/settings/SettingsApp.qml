pragma ComponentBehavior: Bound
import "."
import "material"
import "controls"
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: app
    property int currentIndex: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: M3.s16
                spacing: M3.s4

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: M3.s12
                    text: Lang.t("settings.title")
                    color: M3.m3OnSurface
                    font: M3.titleLarge
                }

                Repeater {
                    model: Schema.pages
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 40
                        radius: M3.rFull
                        color: app.currentIndex === index
                            ? M3.secondaryContainer
                            : (sideMa.containsMouse ? M3.hoverOf(M3.m3OnSurface) : "transparent")
                        Behavior on color { ColorAnimation { duration: M3.durFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: M3.s12
                            anchors.rightMargin: M3.s12
                            spacing: M3.s8
                            Text {
                                text: modelData.icon
                                color: app.currentIndex === index ? M3.m3OnSecondaryContainer : M3.m3OnSurfaceVariant
                                font { family: "Material Symbols Rounded"; pixelSize: 18 }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: Lang.t(modelData.name)
                                color: app.currentIndex === index ? M3.m3OnSecondaryContainer : M3.m3OnSurface
                                font: app.currentIndex === index ? M3.labelLarge : M3.bodyMedium
                            }
                        }
                        MouseArea {
                            id: sideMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: app.currentIndex = index
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: M3.outlineVariant
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: M3.s16
                Layout.leftMargin: M3.s16
                Layout.rightMargin: M3.s16
                Layout.bottomMargin: M3.s8
                implicitHeight: 40
                radius: M3.rFull
                color: M3.surfaceContainer
                border.width: search.activeFocus ? 2 : 1
                border.color: search.activeFocus ? M3.primary : M3.outline

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: M3.s16
                    anchors.rightMargin: M3.s16
                    spacing: M3.s8
                    Text {
                        text: "search"
                        color: M3.m3OnSurfaceVariant
                        font { family: "Material Symbols Rounded"; pixelSize: 18 }
                    }
                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        color: M3.m3OnSurface
                        font: M3.bodyMedium
                        clip: true
                        onTextChanged: SettingsSearch.query = text
                        Keys.onEscapePressed: { text = ""; SettingsSearch.clear() }
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: search.text.length === 0
                            text: Lang.t("search.placeholder")
                            color: M3.m3OnSurfaceVariant
                            font: M3.bodyMedium
                        }
                    }
                }
            }

            Flickable {
                id: flick
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: pageCol.implicitHeight + M3.s24 * 2
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: pageCol
                    width: flick.width - M3.s32
                    x: M3.s16
                    y: M3.s8
                    spacing: M3.s12

                    Repeater {
                        model: Settings.sectionsForPage(app.currentIndex)

                        ColumnLayout {
                            id: sectionWrap
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: M3.s8

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: M3.s16
                                text: Lang.t(sectionWrap.modelData.label).toUpperCase()
                                color: M3.primary
                                font {
                                    family: M3.labelMedium.family
                                    pixelSize: M3.labelMedium.pixelSize
                                    weight: 700
                                    letterSpacing: 1.5
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: bodyCol.implicitHeight + M3.s24 * 2
                                radius: M3.rL
                                color: M3.surfaceContainer

                                ColumnLayout {
                                    id: bodyCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: M3.s16
                                    }
                                    spacing: M3.s12

                                    Repeater {
                                        model: sectionWrap.modelData.fields
                                        SchemaRow {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            cat: modelData.cat
                                            key: modelData.key
                                            field: modelData.field
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: app.currentIndex === Schema.pages.length - 1
                        spacing: M3.s8

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: M3.s16
                            text: Lang.t("page.about").toUpperCase()
                            color: M3.primary
                            font {
                                family: M3.labelMedium.family
                                pixelSize: M3.labelMedium.pixelSize
                                weight: 700
                                letterSpacing: 1.5
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: aboutCol.implicitHeight + M3.s24 * 2
                            radius: M3.rL
                            color: M3.surfaceContainer

                            ColumnLayout {
                                id: aboutCol
                                anchors {
                                    left: parent.left; right: parent.right; top: parent.top
                                    margins: M3.s16
                                }
                                spacing: M3.s8
                                Text { Layout.fillWidth: true; text: Lang.t("about.title"); color: M3.m3OnSurface; font: M3.titleMedium }
                                Text {
                                    Layout.fillWidth: true
                                    text: Lang.t("about.body")
                                    color: M3.m3OnSurfaceVariant
                                    font: M3.bodyMedium
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
