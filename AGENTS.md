# AGENTS.md

This repository is a Nix flake that defines NixOS hosts and Home Manager configurations. These notes are for agentic coding assistants working in this repo. Follow them when editing files under this tree.

Scope and precedence
- This file applies to the entire repository.
- If other AGENTS.md files exist in subfolders, the more deeply nested file takes precedence there.
- If Cursor/Copilot rules appear later, mirror key rules here and follow them.

Repository layout
- nixos/flake.nix: Primary flake with all outputs.
- nixos/hosts/<host>/: Host-specific NixOS modules and hardware configs.
- nixos/hosts/profiles/*: Shared host profiles (common, linux, wsl, virtualization).
- nixos/users/<user>/: User-specific NixOS/Home Manager modules.
- nixos/users/user.nix: Shared Home Manager entrypoint for per-user config.
- nixos/users/modules/*: Reusable Home Manager modules (console, desktop).
- nixos/home/standalone.nix: Standalone Home Manager defaults.
- scripts/: WSL provisioning and certificate utilities.

Prerequisites
- Nix with flakes enabled. On managed systems, flakes are enabled via the config already.
- For WSL installs, ensure certificates are in place if required (see scripts/install.txt).

Build, switch, and validate
Notes
- The flake lives in nixos/. Use --flake nixos#... from the repo root, or run commands with workdir=nixos/.
- Known hosts: AT-L-PF5S785B, rhino, soyo, windy.

NixOS host: build only
```
# From repo root
nix build nixos#nixosConfigurations.AT-L-PF5S785B.config.system.build.toplevel
```
NixOS host: dry-run test (no reboot)
```
sudo nixos-rebuild test --flake nixos#AT-L-PF5S785B
```
NixOS host: switch (activate immediately)
```
sudo nixos-rebuild switch --flake nixos#AT-L-PF5S785B
```
NixOS host: build for boot (activate on next boot)
```
sudo nixos-rebuild boot --flake nixos#AT-L-PF5S785B
```
WSL certificate bootstrap (only when needed during first build)
```
# If network/TLS fails, provide CA via env var for first build
NIX_SSL_CERT_FILE=/etc/nixos/ca-certificates.crt \
  sudo nixos-rebuild boot --flake nixos#AT-L-PF5S785B
```
Show flake outputs (quick inventory)
```
nix flake show nixos
```
Update inputs and lock file
```
# Run inside nixos/ or use nix flake update nixos
( cd nixos && nix flake update )
```

Home Manager (standalone)
- This flake exposes per-user Home Manager configurations via legacyPackages.
- Users wired today: jian, luoj.

Build Home activation package
```
# Replace x86_64-linux by your system if different
nix build nixos#legacyPackages.x86_64-linux.homeConfigurations.jian.activationPackage
```
Activate built Home configuration
```
# After a successful build, activate the result
./result/activate
```
Home Manager switch via CLI (if you later add outputs.homeConfigurations)
```
# Not currently wired; shown here for future reference
home-manager switch --flake nixos#jian
```

Lint and formatting
Nix formatting
- Use nixfmt-rfc-style (binary name: nixfmt) to format all .nix files.
- Run formatting at repo root or within nixos/.

Format
```
nixfmt nixos
```
Check formatting (non-destructive)
```
# nixfmt has no built-in --check; emulate via git
git diff --exit-code -- . ':!result' || echo "Formatting changes pending"
```
Optional: run on specific files
```
nixfmt nixos/users/modules/console/home.nix
```
Evaluation checks
- This flake defines a basic check named sanity.
- Run all checks or a single check:
```
nix build nixos#checks.x86_64-linux
nix build nixos#checks.x86_64-linux.sanity
```

Tests and single test guidance
Current status
- No unit or integration tests are defined in this repository.
- No nixosTests are provided at present.

Recommended approach
- Treat per-host builds as validations:
  - Single host "test": sudo nixos-rebuild test --flake nixos#<host>
  - Single home "test": build activation package and run ./result/activate
- If you add Nix checks under outputs.checks.<system>:
  - Run all checks: nix build nixos#checks.x86_64-linux
  - Run a single check: nix build nixos#checks.x86_64-linux.<name>
- If you add nixosTests under outputs.nixosTests.<name>:
  - Run a single test: nix build nixos#nixosTests.<name>

Coding conventions (Nix)
Imports and module structure
- Prefer smaller modules imported via imports = [ ./relative-path.nix ].
- For cross-cutting modules, place them under nixos/users/modules/ and reuse.
- Keep host-specific logic under nixos/hosts/<host>/.

Attribute sets and layout
- One attribute per line; trailing commas allowed and preferred.
- Group related options together; keep environment/systemPackages near other env settings.
- Use inherit, inherit (x) to avoid repeating attribute names or inputs.

Function arguments
- Modules: use { config, lib, pkgs, ... }: and add inputs when needed via specialArgs.
- Prefer passing inputs via specialArgs (see flake.nix) rather than import-from-derivation.

Types and options
- Use lib.types and mkOption in custom modules; name booleans with enable (e.g., programs.foo.enable).
- Use mkEnableOption for flags; provide sensible defaults.
- Compose with mkIf when options are conditional, avoiding ad-hoc if-else blocks.

Naming conventions
- Hosts: lowercase, hyphenated if needed (e.g., AT-L-PF5S785B is fixed due to environment; keep consistent).
- Modules and files: lowercase with hyphens; attributes in lowerCamelCase following Nixpkgs conventions (e.g., home.stateVersion).
- Keep usernames and user directories consistent across nixos/users/ and specialArgs.username.

Error handling and safety
- Validate assumptions with assert where dangerous (e.g., assert pkgs.stdenv.isLinux; ...).
- Prefer mkDefault/mkForce sparingly; use mkBefore/mkAfter for list merges when order matters.
- Avoid network-fetching during evaluation; pin sources via flake inputs only.
- For impure needs (e.g., local certs), wire via options and document clearly.

Dependencies and imports
- Use flake inputs consistently; follow inputs.<name> indirections already in flake.nix.
- Keep versions synchronized via nix flake update; do not fetchFromGitHub ad hoc inside modules.

Comments and documentation
- Document non-obvious choices with short comments above the block.
- Keep comments updated when changing behaviors; remove stale TODOs.

Commit and PR etiquette
- Keep changes focused; avoid sweeping refactors mixed with functional changes.
- Describe the "why" in commit messages; the "what" is visible in diffs.
- Do not commit secrets or machine-local state; prefer options for paths.

Certificates and secrets
- The repo contains a sample CA bundle at nixos/hosts/AT-L-PF5S785B/ca-certificates.crt.
- Do not add private keys or secret material to the repo.
- For first-time WSL builds, pass NIX_SSL_CERT_FILE as needed; remove once system trust is configured.

Cursor/Copilot rules
- No Cursor rules under .cursor/rules/ or .cursorrules were found.
- No Copilot instructions at .github/copilot-instructions.md were found.
- If such rules are added later, mirror the key enforcement points here for discoverability.

Quick commands cheat sheet
- Show outputs: nix flake show nixos
- Update inputs: (cd nixos && nix flake update)
- Build NixOS host: nix build nixos#nixosConfigurations.<host>.config.system.build.toplevel
- Test NixOS host: sudo nixos-rebuild test --flake nixos#<host>
- Switch NixOS host: sudo nixos-rebuild switch --flake nixos#<host>
- Build Home activation: nix build nixos#legacyPackages.$(nix eval --raw --expr builtins.currentSystem).homeConfigurations.<user>.activationPackage
- Activate Home: ./result/activate
- Run checks: nix build nixos#checks.x86_64-linux
- Run sanity check: nix build nixos#checks.x86_64-linux.sanity
- Format Nix: nixfmt nixos

Contributing notes for agents
- Keep changes minimal and targeted; prefer local edits over renames to reduce churn.
- Follow existing style in nearby files; when in doubt, apply nixfmt and the conventions above.
- When introducing tests, add them under outputs.checks or outputs.nixosTests and document how to run them here.
