//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import "root:/shell"
import "root:/theme"
import "root:/services"
import "root:/osd"
import "root:/notifications"
import "root:/dock"
import "root:/settings"
import "root:/windows"
import "root:/screentool"
import "root:/lockscreen"
import Quickshell
import Quickshell.Io
import QtQuick

ShellRoot {
    Component.onCompleted: LayoutService.ensure()

    id: root

    TaskManagerWindow { id: taskManagerWindow }
    SettingsWindow    { id: settingsWindow }
    ScreenTool        { id: screenTool }
    LockScreen        { id: lockScreen }

    Connections {
        target: ShellState

        function onOpenSettingsRequested()   { settingsWindow.open() }
        function onToggleSettingsRequested() { settingsWindow.toggle() }
        function onCloseSettingsRequested()  { settingsWindow.close() }

        function onOpenTasksRequested()   { taskManagerWindow.open() }
        function onToggleTasksRequested() { taskManagerWindow.toggle() }
        function onCloseTasksRequested()  { taskManagerWindow.close() }
    }

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

    IpcHandler {
        target: "settingsapp"
        function open(): void   { settingsWindow.open() }
        function toggle(): void { settingsWindow.toggle() }
        function close(): void  { settingsWindow.close() }
    }

    IpcHandler {
        target: "screentool"
        function open(): void   { screenTool.start() }
        function close(): void  { screenTool.dismiss() }
        function toggle(): void { screenTool.toggle() }
    }

    Variants {
        model: Quickshell.screens
        SurfaceOverlay {}
    }

    // власний демон сповіщень: спливаючі вікна + центр (swaync більше не потрібен)
    Variants {
        model: Quickshell.screens
        NotificationPopups {}
    }
    Variants {
        model: Quickshell.screens
        NotificationCenter {}
    }
    IpcHandler {
        target: "notifications"
        function toggle(): void { NotificationService.toggleCenter() }
        function open(): void   { NotificationService.openCenter() }
        function close(): void  { NotificationService.closeCenter() }
        function clear(): void  { NotificationService.clearAll() }
        function dnd(): void    { NotificationService.setDnd(!NotificationService.dnd) }
    }

    // M3 OSD (гучність / яскравість)
    Variants {
        model: Quickshell.screens
        OsdWindow {}
    }

    // клавіші: qs -c <cfg> ipc call osd volumeUp  (не обов'язково — OSD і так реагує на зміни)
    IpcHandler {
        target: "osd"
        function volumeUp(): void         { OsdService.volumeStep(0.05) }
        function volumeDown(): void       { OsdService.volumeStep(-0.05) }
        function volumeMute(): void       { OsdService.volumeMute() }
        function brightnessUp(): void     { OsdService.brightnessStep(5) }
        function brightnessDown(): void   { OsdService.brightnessStep(-5) }
    }

    Bar {}
    DockLoader {}
}
