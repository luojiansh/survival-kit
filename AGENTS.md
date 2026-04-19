# AGENTS.md

Nix flake defining NixOS hosts, nix-darwin hosts, and Home Manager user environments. Follow these conventions when editing files under this tree.

## Scope

- This file applies to the entire repository. Nested `AGENTS.md` files take precedence in their subtree.

## Repository Layout

| Path | Purpose |
|---|---|
| `nixos/flake.nix` | Primary flake with all outputs |
| `nixos/hosts/<host>/` | Host-specific NixOS/Darwin modules and hardware configs |
| `nixos/hosts/profiles/` | Shared profiles: `common`, `linux`, `wsl`, `virtualization` |
| `nixos/users/<user>/` | Per-user NixOS + Home Manager settings |
| `nixos/users/user.nix` | Dynamic HM entrypoint — imports user + selected modules |
| `nixos/users/modules/` | Reusable HM modules: `console`, `desktop` |
| `nixos/home/standalone.nix` | Standalone HM defaults (flakes + unfree) |
| `scripts/` | WSL provisioning and certificate utilities |
| `docs/` | Installation and adjustment guides |

## Hosts and Users

| Host | Type | User | Home Modules |
|---|---|---|---|
| `AT-L-PF5S785B` | NixOS-WSL | `atjiluo` | console |
| `scopio` | NixOS | `jian` | console, desktop |
| `rhino` | NixOS | `jian` | console, desktop |
| `soyo` | NixOS | `jian` | console, desktop |
| `windy` | NixOS-WSL | `jianl` | console |
| `MacStudio-von-jian` | nix-darwin | `jian` | console |

Standalone HM users: `jian`, `atjiluo`, `jianl`.

## Quick Commands

All commands run from the **repo root**. The flake is in `nixos/`.

```bash
# Inspect
nix flake show nixos

# NixOS
sudo nixos-rebuild test  --flake nixos#<host>   # dry-run
sudo nixos-rebuild switch --flake nixos#<host>   # apply now
sudo nixos-rebuild boot   --flake nixos#<host>   # apply on next boot

# Darwin
darwin-rebuild switch --flake nixos#MacStudio-von-jian

# Standalone Home Manager
nix build nixos#legacyPackages.$(nix eval --raw --expr builtins.currentSystem).homeConfigurations.<user>.activationPackage
./result/activate

# Update inputs
(cd nixos && nix flake update)

# Format
nixfmt nixos

# Checks
nix build nixos#checks.x86_64-linux.sanity
```

For detailed installation and adjustment procedures, see the guides in `docs/`:
- [docs/INSTALL.md](docs/INSTALL.md) — NixOS (bare-metal + WSL)
- [docs/INSTALL-DARWIN.md](docs/INSTALL-DARWIN.md) — macOS / nix-darwin
- [docs/INSTALL-STANDALONE.md](docs/INSTALL-STANDALONE.md) — Standalone Home Manager
- [docs/ADJUSTING.md](docs/ADJUSTING.md) — Adding hosts, users, modules, updating inputs

## Coding Conventions

- **Formatter**: `nixfmt` (RFC-style). Run `nixfmt nixos` before committing.
- **Module args**: `{ config, lib, pkgs, ... }:`; add `inputs` via `specialArgs`.
- **Layout**: one attribute per line; group related options; use `inherit`.
- **Booleans**: use `mkEnableOption`; name with `enable`.
- **Conditionals**: use `mkIf`, not ad-hoc `if-else`.
- **Naming**: files lowercase-hyphenated; attributes lowerCamelCase.
- **Imports**: prefer small modules via `imports = [ ./path.nix ]`.
- **Inputs**: use flake inputs only; never `fetchFromGitHub` ad hoc.
- **Comments**: document non-obvious choices; keep comments current.
- **Secrets**: never commit private keys; only public CA certs belong in the repo.

## Agent Guidelines

- Keep changes minimal and targeted; prefer local edits over renames.
- Follow existing style in nearby files; when in doubt, run `nixfmt`.
- Pre-commit hook: `.githooks/pre-commit` — formats `.nix`, lints `.ps1`.
- When adding tests, use `outputs.checks` or `outputs.nixosTests` and document here.
