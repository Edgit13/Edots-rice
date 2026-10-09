//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    SettingsWindow { id: win }

    IpcHandler {
        target: "settingsapp"
        function open(): void   { win.open() }
        function toggle(): void { win.toggle() }
        function close(): void  { win.close() }
    }
}
