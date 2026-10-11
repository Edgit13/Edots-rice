import "root:/shell"
import Quickshell
import Quickshell.Io
import QtQml.Models

// bar/dock/DockLoader.qml — owns the dock lifecycle, the "dock" IPC target,
// and the visibility state file. One dock window on BarConfig.mainMonitor,
// one click-catcher per monitor.
Scope {
    id: root

    readonly property string stateFile: Quickshell.env("HOME")
        + "/Dotfiles/quickshell/dock/state"
    property bool stateVisible: true

    readonly property var dockScreen: {
        const screens = Quickshell.screens
        if (!screens || screens.length === 0) return null
        const main = BarConfig.mainMonitor
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === main) return screens[i]
        return screens[0]
    }

    function applyState(text): void {
        root.stateVisible = `${text ?? ""}`.trim() !== "0"
        console.log("Dock: stateVisible =", root.stateVisible,
            "ready =", DockSettings.ready, "enabled =", DockSettings.enabled)
    }

    // Not exposed over IPC — IpcHandler functions cannot take QVariant,
    // so the public "dock" functions below call this plain helper.
    function _setStateVisible(on) { stateView.setText(on ? "1\n" : "0\n") }

    FileView {
        id: stateView
        path: root.stateFile
        watchChanges: true
        printErrors: false
        onFileChanged: stateView.reload()
        onLoaded: root.applyState(stateView.text())
        onLoadFailed: {
            root.stateVisible = true
            console.log("Dock: state file missing, showing dock")
        }
    }

    IpcHandler {
        target: "dock"

        function toggle(): void {
            const next = !DockSettings.enabled
            DockSettings.setEnabled(next)
            root._setStateVisible(next)
        }
        function enable(): void {
            DockSettings.setEnabled(true)
            root._setStateVisible(true)
        }
        function disable(): void {
            DockSettings.setEnabled(false)
            root._setStateVisible(false)
        }
        function autohideOn(): void  { DockSettings.setAutohide(true) }
        function autohideOff(): void { DockSettings.setAutohide(false) }
        function autohideToggle(): void {
            DockSettings.setAutohide(!DockSettings.autohide)
        }
        function reload(): void {
            DockSettings.reloadSettings()
            DockTheme.reload()
        }
        function settings(): void { DockSettings.dialogOpen = true }
        function edit(): void { DockSettings.editConfig() }
    }

    Instantiator {
        model: Quickshell.screens
        delegate: DockClickCatcher { screen: modelData }
    }

    LazyLoader {
        active: DockSettings.ready && DockSettings.enabled && root.stateVisible
                     && root.dockScreen !== null
        Instantiator {
            model: root.dockScreen ? [root.dockScreen] : []
            delegate: DockWindow { screen: modelData }
        }
    }

    LazyLoader {
        active: DockSettings.dialogOpen
        DockSettingsWindow {}
    }
}
