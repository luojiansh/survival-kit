# Adjusting the Configuration

How to add hosts, users, modules, update inputs, and maintain the repo.

> [!NOTE]
> **For agents**: this document is the primary reference for structural changes. Follow the patterns described here; they match the existing codebase conventions in `AGENTS.md`.

---

## Adding a New NixOS Host

### 1. Create the host directory

```
nixos/hosts/<hostname>/
├── nixos.nix               # profile imports
├── configuration.nix        # host-specific settings
└── hardware-configuration.nix  # (bare-metal only, from nixos-generate-config)
```

**`nixos.nix`** — compose the profiles this host needs:

```nix
# <hostname> — brief description.
# Composes: <list profiles>.
{
  imports = [
    ./configuration.nix
    ../profiles/common/configuration.nix
    ../profiles/linux/configuration.nix     # or wsl, or omit for Darwin
    # ../profiles/virtualization/configuration.nix  # optional
  ];
}
```

**`configuration.nix`** — host-specific overrides:

```nix
# <hostname> host-specific configuration.
{
  imports = [
    ./hardware-configuration.nix  # bare-metal only
  ];

  system.stateVersion = "26.05";  # pin to current NixOS release
}
```

### 2. Register in `flake.nix`

Add an entry under `nixosConfigurations`:

```nix
<hostname> = mkNixOS {
  hostname = "<hostname>";
  username = "<user>";
  system = "x86_64-linux";
  homeModules = [ "console" ];  # add "desktop" for GUI hosts
};
```

### 3. Build and test

```bash
sudo nixos-rebuild test --flake nixos#<hostname>
```

> [!AGENT]
> **Checklist for adding a NixOS host**:
> 1. Create `nixos/hosts/<hostname>/nixos.nix` (imports)
> 2. Create `nixos/hosts/<hostname>/configuration.nix` (host config)
> 3. Copy `hardware-configuration.nix` from target machine (if bare-metal)
> 4. Add entry in `flake.nix` under `nixosConfigurations`
> 5. Build: `nix build nixos#nixosConfigurations.<hostname>.config.system.build.toplevel`

---

## Adding a New Darwin Host

Same pattern, but use `mkNixDarwin` and place the entry under `darwinConfigurations`:

```nix
"<hostname>" = mkNixDarwin {
  hostname = "<hostname>";
  username = "<user>";
  system = "aarch64-darwin";
  homeModules = [ "console" ];
};
```

Create `nixos/hosts/<hostname>/nixos.nix` and `configuration.nix` following the `MacStudio-von-jian` pattern.

---

## Adding a New User

### 1. Create the user directory

```
nixos/users/<username>/
├── home.nix    # per-user Home Manager settings
└── nixos.nix   # per-user NixOS settings (can be empty: { })
```

**`home.nix`** — minimum required:

```nix
# Per-user config: <username>.
{
  home.username = "<username>";
  home.homeDirectory = "/home/<username>";

  programs.git.settings = {
    user.name = "<Full Name>";
    user.email = "<email>";
    init.defaultBranch = "main";
  };

  home.stateVersion = "25.11";
}
```

**`nixos.nix`** — typically empty unless you need system-level user settings:

```nix
{ }
```

### 2. Wire into `flake.nix`

- For NixOS/Darwin hosts: set `username = "<username>"` in the host's `mkNixOS` / `mkNixDarwin` call.
- For standalone HM: add an entry under `homeConfigurations`:

```nix
"<username>" = homeConfig {
  username = "<username>";
  homeModules = [ "console" ];
};
```

> [!AGENT]
> **Checklist for adding a user**:
> 1. Create `nixos/users/<username>/home.nix`
> 2. Create `nixos/users/<username>/nixos.nix` (usually `{ }`)
> 3. Add `homeConfigurations` entry or reference in host config
> 4. Build and activate

---

## Adding a New Home Manager Module

Modules live under `nixos/users/modules/<name>/home.nix`. They are selected per-host via the `homeModules` list in `flake.nix`.

### 1. Create the module

```
nixos/users/modules/<name>/home.nix
```

Standard module pattern:

```nix
# <Name> module — brief description.
{
  pkgs,
  inputs,
  ...
}: {
  # your config here
}
```

### 2. Reference it

In `flake.nix`, add `"<name>"` to the host's `homeModules` list:

```nix
homeModules = [ "console" "<name>" ];
```

The dynamic import in `users/user.nix` will automatically pick it up.

> [!AGENT]
> Module resolution: `users/user.nix` maps `homeModules` strings to `./modules/<name>/home.nix` via `builtins.map`.

---

## Updating Flake Inputs

```bash
# Update all inputs
(cd nixos && nix flake update)

# Update a single input
(cd nixos && nix flake update nixpkgs)
```

After updating, rebuild the target host to pick up changes.

---

## Formatting and Linting

### Nix files

```bash
# Format the entire tree
nixfmt nixos

# Format a single file
nixfmt nixos/users/modules/console/home.nix
```

A pre-commit hook is available at `.githooks/pre-commit`. Enable it with:

```bash
git config core.hooksPath .githooks
```

### Evaluation checks

```bash
# Run all checks
nix build nixos#checks.x86_64-linux

# Run a single check
nix build nixos#checks.x86_64-linux.sanity
```

> [!AGENT]
> **Formatting commands**:
> - Format all: `nixfmt nixos`
> - Check formatting: `git diff --exit-code -- . ':!result'`
> - Run checks: `nix build nixos#checks.x86_64-linux`

---

## Certificate Management

Corporate networks with TLS-intercepting proxies need a CA bundle. This repo handles it two ways:

| Scenario | Tool | Details |
|---|---|---|
| NixOS-WSL (corporate) | `scripts/Windows_to_WSL_Certs.ps1` | Exports Windows Root+CA certs to a PEM bundle in WSL |
| Ubuntu/Debian WSL | `scripts/get-all-certs.sh` | Same but uses the system trust store (`update-ca-certificates`) |
| First NixOS build | `NIX_SSL_CERT_FILE` env var | Override for the initial `nixos-rebuild` before system certs are configured |

The AT-L-PF5S785B host stores its CA bundle at `nixos/hosts/AT-L-PF5S785B/ca-certificates.crt` and injects it via `security.pki.certificateFiles`.

> [!CAUTION]
> Never commit private keys or secrets to this repository. Only public CA certificates belong here.
