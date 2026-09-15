# Edots — Nix adaptation

Адаптація rice **MangoWM + Quickshell** для NixOS/home-manager.
База — Arch-система користувача ( EndeavourOS ), повний список пакетів
див. у `../docs` або у вихідному інвентарі; тут — тільки rice-ядро.

## Структура

| Файл | Призначення |
|---|---|
| `flake.nix` | inputs (nixpkgs-unstable, home-manager, офіційний `github:mangowm/mango`) + модулі |
| `rice.nix` | пакетне ядро rice (shell/capture/barDeps/cli/terms/fonts) |
| `module.nix` | NixOS: пакети, шрифти, pipewire/bluetooth/NetworkManager, портали |
| `home.nix` | home-manager: symlink-конфіги з репо + user-пакети + session vars |
| `mango.nix` | опційний повністю декларативний MangoWM (HM `wayland.windowManager.mango.settings`) |

## Підключення

```nix
# flake.nix користувача
{
  inputs.edots.url = "github:Edgit13/Edots-rice";   # або path:./Edots-rice
  inputs.edots.inputs.nixpkgs.follows = "nixpkgs";
  inputs.mango.url = "github:mangowm/mango";
  inputs.mango.inputs.nixpkgs.follows = "nixpkgs";

  outputs = inputs@{ self, nixpkgs, home-manager, edots, mango, ... }: {
    nixosConfigurations.HOST = nixpkgs.lib.nixosSystem {
      modules = [
        ./hardware-configuration.nix
        home-manager.nixosModules.home-manager
        mango.nixosModules.mango          # programs.mango.enable = true
        edots.nixosModules.edots          # edots.enable = true
        { programs.mango.enable = true;
          services.displayManager.defaultSession = "mango"; }
      ];
    };
  };
}
```

```nix
# home.nix користувача
{ inputs, ... }: {
  imports = [ inputs.edots.homeManagerModules.edots ];
  edots.home.enable = true;
}
```

## Відомі прогалини (чесно)

1. **AUR-only пакети** — у nixpkgs немає або лише сторонні flake:
   `anydesk-bin`, `viber`, `curseforge`, `handy-bin`, `quicksnip-git`,
   `virtualbox-bin` (→ `pkgs.virtualbox`), `zed` (→ `pkgs.zed-editor`).
   Flatpak-застосунки залишаються flatpak: `services.flatpak.enable = true`.
   `snapd` на NixOS — не існує; що було через snap — встановлювати інакше.
2. **Шрифти Apple**: SF Pro Display / SF Mono — вручну у `~/.local/share/fonts/`
   (ліцензійно не поширюються nixpkgs). Без них бар впаде на fallback —
   у Defaults зміни `appearance.uiFont/monoFont`.
3. **Runtime-файли** `quickshell/{colors.json,settings.json,tasks.json,active-preset,presets/}`
   свідомо НЕ в store: їх пишуть matugen/Config/TasksStore. Вони з'являться самі.
   У репо їх варто додати в `.gitignore`.
4. **CompositorFx** дописує `blur_layer` рядки в `mango/config.conf` — symlink
   пропускає запис у робочу копію репо (git diff після зміни blur — норма;
   альтернатива: тримати mango-config окремою копією, не symlink).
5. **Сесія MangoWM**: з `mango.nixosModules.mango` — `programs.mango.enable` +
   `services.displayManager.defaultSession = "mango"`. Без flake: nixpkgs
   `pkgs.mangowc` + власний `share/wayland-sessions/mango.desktop`.
6. **Драйвери/GPU, hostname, luks, swap** — machine-specific, поза scope rice.

## Перевірка

```sh
nix flake check          # у теці nix/ репо (потребує flake-репо як git)
nix eval .#nixosModules.edots --apply 'x: x ? config'   # швидкий sanity
```
