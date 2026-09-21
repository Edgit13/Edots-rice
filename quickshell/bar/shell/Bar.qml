import "root:/shell"
import Quickshell
import Quickshell.Io

// Bar — Scope: бар на кожному моніторі + IPC для перемикання позиції/режиму.
//   qs -p ~/.config/quickshell/bar/ShellNext.qml ipc call bar setPosition left
Scope {
    Variants {
        model: Quickshell.screens
        BarWindow {}
    }

    IpcHandler {
        target: "bar"

        function setPosition(position: string): void { BarConfig.set("position", position) }
        function setMode(mode: string): void { BarConfig.set("mode", mode) }
        function setElevation(level: int): void { BarConfig.set("elevation", level) }
        // monitor = імена з monitors(); position = top|bottom|left|right, "" → скинути override
        function setMonitorPosition(monitor: string, position: string): void { BarConfig.setMonitor(monitor, "position", position) }
        function setMonitorMode(monitor: string, mode: string): void { BarConfig.setMonitor(monitor, "mode", mode) }
        function monitors(): string {
            const names = []
            for (let i = 0; i < Quickshell.screens.length; i++) names.push(Quickshell.screens[i].name)
            return names.join(",")
        }
    }
}
