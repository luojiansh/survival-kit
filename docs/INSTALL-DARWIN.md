# Installing on macOS (nix-darwin)

This guide covers first-time setup of nix-darwin on a Mac.

> [!NOTE]
> **For agents**: the Darwin host is `MacStudio-von-jian` on `aarch64-darwin`. The flake wires `nix-homebrew` automatically via `mkNixDarwin`.

---

## Prerequisites

| Requirement | How to get it |
|---|---|
| Nix | `curl -L https://nixos.org/nix/install \| sh` |
| Flakes enabled | Add `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf` |
| Git | Comes with Xcode CLI tools: `xcode-select --install` |

---

## First-time Setup

### 1. Clone the repo

```bash
git clone https://github.com/<org>/survival-kit.git
cd survival-kit
```

### 2. Add your host (if needed)

If your Mac's hostname isn't already `MacStudio-von-jian`, see [ADJUSTING.md](ADJUSTING.md#adding-a-new-nixos-host) for how to add a Darwin host. You'll need:

- A directory under `nixos/hosts/<hostname>/`
- An entry in `flake.nix` under `darwinConfigurations`

### 3. Build and switch

```bash
# First run (nix-darwin may not be installed yet)
nix run nix-darwin -- switch --flake nixos#MacStudio-von-jian

# Subsequent runs (darwin-rebuild is now on PATH)
darwin-rebuild switch --flake nixos#MacStudio-von-jian
```

> [!TIP]
> On first run, nix-darwin will ask to create `/etc/nix/nix.conf` symlinks. Say yes.

### 4. Activate Home Manager

Home Manager is wired into nix-darwin via the flake, so `darwin-rebuild switch` activates it automatically. No separate step needed.

> [!AGENT]
> **Agent command reference** (Darwin):
> - Switch: `darwin-rebuild switch --flake nixos#MacStudio-von-jian`
> - Show outputs: `nix flake show nixos`
> - First run (no darwin-rebuild yet): `nix run nix-darwin -- switch --flake nixos#<host>`

---

## What Gets Installed

The Darwin configuration (`nixos/hosts/MacStudio-von-jian/configuration.nix`) provides:
- `nixfmt` system-wide
- Flake support
- `system.primaryUser` for service management

All other tooling (Neovim, git, dev packages) comes from the Home Manager **console** module, shared with Linux hosts.

---

## Updating

```bash
cd survival-kit
(cd nixos && nix flake update)      # update all inputs
darwin-rebuild switch --flake nixos#MacStudio-von-jian
```
