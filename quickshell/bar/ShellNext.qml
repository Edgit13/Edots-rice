//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import "root:/shell"
import "root:/theme"
import Quickshell
import Quickshell.Io
import QtQuick

// ShellNext — Material 3 Expressive shell for MangoWM.
// Dashboard lives inside BarWindow (DashboardSurface); settings runs as a
// separate shell process (../settings/shell.qml), launched on demand.
ShellRoot {
    id: root

    readonly property string settingsShell:
        Quickshell.env("HOME") + "/.config/quickshell/settings/shell.qml"

    TaskManagerWindow { id: taskManagerWindow }

    // Spawn the settings shell if needed, then forward the IPC call to it.
    function _settingsCall(fn) {
        Quickshell.execDetached(["sh", "-c",
            "pgrep -f 'qs -p .*settings/shell.qml' >/dev/null || " +
            "(qs -p " + root.settingsShell + " >/dev/null 2>&1 &); " +
            "sleep 0.5; " +
            "qs -p " + root.settingsShell + " ipc call settingsapp " + fn
        ])
    }

    Connections {
        target: ShellState
        // dashboard is handled per-monitor inside DashboardSurface

        function onOpenSettingsRequested()   { root._settingsCall("open") }
        function onToggleSettingsRequested() { root._settingsCall("toggle") }
        function onCloseSettingsRequested()  { root._settingsCall("close") }

        function onOpenTasksRequested()   { taskManagerWindow.open() }
        function onToggleTasksRequested() { taskManagerWindow.toggle() }
        function onCloseTasksRequested()  { taskManagerWindow.close() }
    }

    // ---- pill (matches mango/binds.conf) ----
    IpcHandler {
        target: "pill"

        function showLauncher(): void   { ShellState.openSurface("launcher") }
        function toggleLauncher(): void { ShellState.toggleSurface("launcher") }
        function showWallpaper(): void   { ShellState.openSurface("wallpaper") }
        function toggleWallpaper(): void { ShellState.toggleSurface("wallpaper") }
        function showClipboard(): void   { ShellState.openSurface("clipboard") }
        function toggleClipboard(): void { ShellState.toggleSurface("clipboard") }
        function showMixer(): void   { ShellState.openSurface("mixer") }
        function toggleMixer(): void { ShellState.toggleSurface("mixer") }
        function showWifi(): void   { ShellState.openSurface("wifi") }
        function toggleWifi(): void { ShellState.toggleSurface("wifi") }
        function showMedia(): void   { ShellState.openSurface("media") }
        function toggleMedia(): void { ShellState.toggleSurface("media") }
        function showPower(): void   { ShellState.openSurface("power") }
        function togglePower(): void { ShellState.toggleSurface("power") }

        function showSettings(): void   { ShellState.toggleSettings() }
        function toggleSettings(): void { ShellState.toggleSettings() }

        function close(): void { ShellState.closeSurfaces() }
    }

    IpcHandler {
        target: "launcher"
        function open(): void { ShellState.openSurface("launcher") }
    }

    IpcHandler {
        target: "dashboard"
        function open(): void   { ShellState.openDashboard() }
        function toggle(): void { ShellState.toggleDashboard() }
        function close(): void  { ShellState.closeDashboard() }
    }

    IpcHandler {
        target: "tasks"
        function open(): void   { taskManagerWindow.open() }
        function toggle(): void { taskManagerWindow.toggle() }
        function close(): void  { taskManagerWindow.close() }
    }

    // Launcher IPC. Distinct target name ("settings-launch") so it never
    // collides with the settings shell's own `settingsapp` handler, which
    // would otherwise receive the same `qs ipc call` and double-toggle.
    IpcHandler {
        target: "settings-launch"
        function open(): void   { root._settingsCall("open") }
        function toggle(): void { root._settingsCall("toggle") }
        function close(): void  { root._settingsCall("close") }
    }

    Variants {
        model: Quickshell.screens
        SurfaceOverlay {}
    }

    Bar {}
}
