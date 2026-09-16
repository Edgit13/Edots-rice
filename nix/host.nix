# host.nix — імпортує НАЯВНУ конфігурацію машини (/etc/nixos).
# install.sh використовує це, щоб додати rice ПОВЕРХ вашої системи,
# нічого в ній не змінюючи. Для pure-eval усім імпортам — pathExists-гарди.
{ ... }:

{
  imports =
    (if builtins.pathExists /etc/nixos/hardware-configuration.nix
     then [ /etc/nixos/hardware-configuration.nix ] else [])
    ++
    (if builtins.pathExists /etc/nixos/configuration.nix
     then [ /etc/nixos/configuration.nix ] else []);
}
