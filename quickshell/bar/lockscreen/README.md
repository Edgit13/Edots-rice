# Quickshell Lock Screen (MangoWC / EndeavourOS)

A session-lock screen for Quickshell using `ext-session-lock-v1`, styled from
`~/.config/quickshell/colors.json` (auto-reloads when the file changes).

## What you get
- Big monospace clock + date
- User avatar + name, PAM password field (Enter to unlock, Esc to clear)
- Show/hide password toggle, attempt counter, per-attempt error state
- Suspend / reboot / poweroff with confirmation overlay
- IPC hooks (only when run via the ~/.config/ilock symlink below): `qs -c ilock ipc call ilock relock` / `quit`

## Install
Run the self-extracting installer:

    sh ./install-quickshell-lock.run

It will:
1. Extract `lockscreen/` into `~/.config/quickshell/lockscreen/`
2. Compile `pam-auth.c` -> `~/.config/quickshell/lockscreen/pam-auth`
   (needs `base-devel` + `pam`; EndeavourOS ships base-devel by default)
3. Install the PAM service to `/etc/pam.d/quickshell-lock` (via sudo)
4. Verify everything works and print next steps

## Use

Start the lock (locks immediately, quits on unlock):

    qs -p ~/.config/quickshell/lockscreen

MangoWC keybind (`~/.config/mangowc/config.conf`):

    bind=SUPER,escape,exec,qs -p ~/.config/quickshell/lockscreen

Auto-lock on idle / before sleep (add to MangoWC `autostart` or a systemd user unit):

    swayidle -w \
        timeout 600 'qs -p ~/.config/quickshell/lockscreen' \
        before-sleep 'qs -p ~/.config/quickshell/lockscreen'

## Notes
- Requires MangoWC built with `ext-session-lock-v1` support (standard in recent builds).
- Auth runs as your own user against PAM `system-auth` — no sudo needed.
- Colors are read from `../colors.json` relative to the shell; delete that file
  and it falls back to the embedded palette.

## IPC (optional)
If you want instance control (e.g. relock from a script), symlink the shell:
    ln -s ~/.config/quickshell/lockscreen ~/.config/ilock
    qs -c ilock        # instead of -p
