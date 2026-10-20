pragma Singleton
import "root:/settings"
import "BindsParser.js" as Parser
import Quickshell
import Quickshell.Io
import QtQuick

// BindsService — читає ~/.config/mango/binds.conf і віддає записи для шпаргалки (Super+/).
// Файл перечитується сам при зміні.
Singleton {
    id: root

    property string path: Quickshell.env("HOME") + "/.config/mango/binds.conf"
    property var entries: []

    function describe(e) {
        return e.descKey && e.descKey.length > 0
            ? Lang.tn("ui.binds." + e.descKey, e.descArg || "")
            : e.cmd
    }
    function groupLabel(g) { return g && g.length > 0 ? g : Lang.t("ui.binds.general") }

    FileView {
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.entries = Parser.parse(text())
    }
}
