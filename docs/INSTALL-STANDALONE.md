# Standalone Home Manager Installation

Use this guide when you want to manage your user environment with Home Manager on a machine where you **don't** control the system configuration (e.g. Ubuntu/Debian WSL, a shared server, or a distro you don't want to replace with NixOS).

> [!NOTE]
> **For agents**: standalone HM configs are exposed via `legacyPackages.<system>.homeConfigurations.<user>`. Build with `nix build`, activate with `./result/activate`.

---

## Prerequisites

| Requirement | How to get it |
|---|---|
| Nix | `curl -L https://nixos.org/nix/install \| sh -s -- --daemon` |
| Flakes enabled | `echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf` |
| Git | `sudo apt install git` or equivalent |

---

## Ubuntu / Debian WSL (Automated)

The repo ships a PowerShell provisioning script that handles everything. Run from **elevated PowerShell** on the Windows host:

```powershell
# From the repo's scripts/ directory
.\Provision-UbuntuWSL.ps1 -Image "Ubuntu" -DistroName "Ubuntu"
```

The script:
1. Installs the WSL distro
2. Exports Windows CA certificates (for corporate proxies)
3. Installs Nix with flakes
4. Copies the repo into WSL
5. Builds and activates the Home Manager config
6. Renames `.bashrc` → `.bashrc.dist` so HM can manage the shell without losing distro defaults

See `scripts/Provision-UbuntuWSL.ps1` header for all parameters.

---

## Any Linux (Manual)

### 1. Install Nix

```bash
curl -L https://nixos.org/nix/install | sh -s -- --daemon
# Enable flakes
echo 'experimental-features = nix-command flakes' | sudo tee -a /etc/nix/nix.conf
# Restart the Nix daemon
sudo systemctl restart nix-daemon
```

### 2. Clone the repo

```bash
git clone https://github.com/<org>/survival-kit.git
cd survival-kit
```

### 3. Build the Home Manager activation package

```bash
# Replace "jian" with your username from flake.nix
nix build nixos#legacyPackages.x86_64-linux.homeConfigurations.jian.activationPackage
```

> [!TIP]
> On `aarch64-linux`, replace `x86_64-linux` with `aarch64-linux`.

### 4. Back up existing shell config

Home Manager will try to write `~/.bashrc`, `~/.profile`, etc. If they already exist, back them up so the console module can source them:

```bash
[ -f ~/.bashrc ]  && mv ~/.bashrc  ~/.bashrc.dist
[ -f ~/.profile ] && mv ~/.profile ~/.profile.dist
```

### 5. Activate

```bash
./result/activate
```

You now have the full console environment (Neovim + LazyVim, git, gh, fzf, ripgrep, etc.).

> [!AGENT]
> **Agent command reference** (standalone HM):
> - Build: `nix build nixos#legacyPackages.$(nix eval --raw --expr builtins.currentSystem).homeConfigurations.<user>.activationPackage`
> - Activate: `./result/activate`
> - Available users: `jian`, `atjiluo`, `jianl`

---

## Updating

```bash
cd survival-kit
(cd nixos && nix flake update)
nix build nixos#legacyPackages.x86_64-linux.homeConfigurations.jian.activationPackage
./result/activate
```

---

## Certificate Handling

On corporate networks, Nix may fail to fetch due to TLS interception. Set the cert file before building:

```bash
NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
  nix build nixos#legacyPackages.x86_64-linux.homeConfigurations.jian.activationPackage
```

The `get-all-certs.sh` script can export Windows certs into the Linux trust store when run from inside WSL:

```bash
sudo ./scripts/get-all-certs.sh
```
