# Installing NixOS Hosts

This guide covers first-time NixOS installation — both bare-metal Linux and NixOS-WSL.

> [!NOTE]
> **For agents**: commands in this doc assume you are at the repository root. The flake lives in `nixos/`, so use `--flake nixos#...`. Known hosts: `AT-L-PF5S785B`, `rhino`, `scopio`, `soyo`, `windy`.

---

## Prerequisites

| Requirement | Why |
|---|---|
| Nix with flakes | The repo is a flake; `nix-command` and `flakes` experimental features must be enabled |
| Git | To clone the repo |
| `sudo` access | `nixos-rebuild` needs root |

On a fresh NixOS install, flakes are already enabled by the common profile. On other systems, add `experimental-features = nix-command flakes` to `/etc/nix/nix.conf`.

---

## Bare-metal Linux

### 1. Install NixOS

Follow the [official NixOS installer](https://nixos.org/download) to get a minimal system booted. The installer will generate `/etc/nixos/hardware-configuration.nix` — keep it, you'll move it into the repo.

### 2. Clone the repo

```bash
git clone https://github.com/<org>/survival-kit.git
cd survival-kit
```

### 3. Add your host

If your hostname isn't already listed under `nixos/hosts/`, see [ADJUSTING.md](ADJUSTING.md#adding-a-new-nixos-host) for how to add one.

### 4. Build and switch

```bash
# Test first (applies config without touching the bootloader)
sudo nixos-rebuild test --flake nixos#<hostname>

# If everything works, switch for real
sudo nixos-rebuild switch --flake nixos#<hostname>
```

> [!TIP]
> Use `boot` instead of `switch` if you want the config to take effect only on the next reboot:
> ```bash
> sudo nixos-rebuild boot --flake nixos#<hostname>
> ```

---

## NixOS-WSL

WSL installs are automated by the PowerShell provisioning script. You can also do it manually.

### Automated (recommended)

Run from an **elevated PowerShell** on the Windows host:

```powershell
# From the repo's scripts/ directory
.\Provision-NixOSWSL.ps1 -Image "$env:USERPROFILE\Downloads\nixos.wsl" -DistroName "NixOS"
```

The script handles:
1. Registering the WSL distro
2. Exporting Windows certificates (for corporate proxies)
3. Writing a minimal `/etc/nixos/configuration.nix` with cert and flake support
4. Running `nixos-rebuild switch` and then `nixos-rebuild boot --flake`
5. Building and activating the Home Manager configuration

See `scripts/Provision-NixOSWSL.ps1` header for all parameters.

### Manual

```bash
# 1. Register the distro
wsl --install --from-file ./Downloads/nixos.wsl

# 2. (Corporate proxy only) Copy certs into WSL
sudo cp /mnt/c/workspace/ca-certificates.crt /etc/nixos/

# 3. Append cert + flake config to /etc/nixos/configuration.nix
cat <<'EOF' >> /etc/nixos/configuration.nix
//
{
  security.pki.certificateFiles = [ ./ca-certificates.crt ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [ git neovim ];
}
EOF

# 4. Initial rebuild (with cert override if behind proxy)
NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt nixos-rebuild switch

# 5. Terminate and restart WSL to pick up systemd
wsl -t NixOS

# 6. Clone the repo and switch to the flake
git clone https://github.com/<org>/survival-kit.git
cd survival-kit
NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt \
  sudo nixos-rebuild boot --flake nixos#AT-L-PF5S785B
```

> [!AGENT]
> **Agent command reference** (WSL NixOS):
> - Build only: `nix build nixos#nixosConfigurations.<host>.config.system.build.toplevel`
> - Dry-run test: `sudo nixos-rebuild test --flake nixos#<host>`
> - Switch: `sudo nixos-rebuild switch --flake nixos#<host>`
> - Boot: `sudo nixos-rebuild boot --flake nixos#<host>`
> - With cert override: prefix with `NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt`

---

## After Installation

Once a host is built, day-to-day changes follow the same cycle:

```bash
# Edit Nix files...
nixfmt nixos                        # format
sudo nixos-rebuild switch --flake nixos#<hostname>  # apply
```

See [ADJUSTING.md](ADJUSTING.md) for how to add hosts, users, modules, and update inputs.
