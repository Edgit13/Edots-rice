//@ pragma UseQApplication

import Quickshell
import qs.DockApp

// Entry point of the M3 Dock. Start it with:
//
//   qs -p ~/Dotfiles/quickshell/dock
//
// and control it over IPC (qs ipc show lists the functions):
//
//   qs -p ~/Dotfiles/quickshell/dock ipc call dock toggle
ShellRoot {
    // Creates the dock window only while the dock is enabled in its config.json.
    DockLoader {}
}
