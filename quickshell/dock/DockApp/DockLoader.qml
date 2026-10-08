import Quickshell
import Quickshell.Io
import QtQml.Models
import qs.DockApp

// Owns the dock's lifecycle, the "dock" IPC target, and the visibility state
// file. One dock window and one click-catcher are created per monitor.
//
// NOTE: Instantiator (not Repeater) is used to create the windows — Repeater
// parents its delegates into the item tree, and a PanelWindow cannot be a
// visual child, so with a Repeater no windows ever appear and nothing errors
// out loudly.
Scope {
    id: root

    // --- VISIBILITY STATE FILE ---
    // ~/Dotfiles/quickshell/dock/state: "0" hides the dock, "1" (or anything
    // but "0", including a missing file) shows it. Hiding only destroys the
    // dock windows — the quickshell process stays alive and keeps watching
    // the file, so toggle-dock.sh can show/hide the dock instantly without
    // a restart.
    readonly property string stateFile: Quickshell.env("HOME")
        + "/Dotfiles/quickshell/dock/state"
    property bool stateVisible: true

    function applyState(text): void {
        root.stateVisible = `${text ?? ""}`.trim() !== "0"
        console.log("Dock: stateVisible =", root.stateVisible,
            "ready =", DockSettings.ready, "enabled =", DockSettings.enabled)
    }

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
        function toggle(): void { DockSettings.setEnabled(!DockSettings.enabled) }
        function enable(): void { DockSettings.setEnabled(true) }
        function disable(): void { DockSettings.setEnabled(false) }
        function autohideOn(): void { DockSettings.setAutohide(true) }
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

    // Invisible full-screen surfaces stacked *behind* the docks (same layer,
    // created first). While a context menu is open one of them swallows any
    // click outside the dock, dismissing the menu — the portable replacement
    // for a compositor focus grab, so menu dismissal works on MangoWM and
    // Sway too. One per monitor.
    Instantiator {
        model: Quickshell.screens
        delegate: DockClickCatcher { screen: modelData }
    }

    // Waits for the settings files before building the windows, so each dock
    // is created once with the values from disk. See DockSettings.ready. The
    // instanciator is torn down when the dock is disabled or the state file
    // hides it; the settings dialog below keeps working either way.
    LazyLoader {
        active: DockSettings.ready && DockSettings.enabled && root.stateVisible
        Instantiator {
            model: Quickshell.screens
            delegate: DockWindow { screen: modelData }
        }
    }

    // The settings dialog, built only while it is open. Separate from the
    // dock windows so it also opens while the dock is hidden or disabled.
    LazyLoader {
        active: DockSettings.dialogOpen
        DockSettingsWindow {}
    }
}
