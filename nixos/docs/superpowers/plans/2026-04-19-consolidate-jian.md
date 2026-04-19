# Consolidate jian's configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merge the configurations for the `jian` user (NixOS, nix-darwin, and standalone) into a single, flexible configuration that toggles desktop features based on the target platform.

**Architecture:** We will use a `homeModules` array of strings passed from `flake.nix` to `users/user.nix`, which will dynamically import the requested modules. Individual user files will be stripped of imports and focus only on user-specific preferences.

**Tech Stack:** Nix, NixOS, nix-darwin, Home Manager.

---

### Task 1: Update `flake.nix` to support `homeModules`

**Files:**
- Modify: `flake.nix`

- [ ] **Step 1: Update `mkSystem` to accept and pass `homeModules`**

```nix
      # Helper to create a unified system configuration
      mkSystem =
        {
          builder,
          hmModule,
        }:
        {
          hostname,
          username,
          system,
          homeModules ? [ "console" ], # Default to console
        }:
        builder {
          inherit system;

          # Pass args to modules
          specialArgs = {
            inherit inputs hostname username;
          };

          modules = [
            ./hosts/${hostname}/nixos.nix
            ./users/${username}/nixos.nix

            hmModule
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.extraSpecialArgs = { inherit username inputs homeModules; };
              home-manager.users.${username} = import ./users/user.nix;
            }
          ];
        };
```

- [ ] **Step 2: Update host configurations with `homeModules`**

```nix
      nixosConfigurations = {
        "AT-L-PF5S785B" = mkNixOS {
          hostname = "AT-L-PF5S785B";
          username = "atjiluo";
          system = "x86_64-linux";
          homeModules = [ "console" ];
        };
        scopio = mkNixOS {
          hostname = "scopio";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [ "console" "desktop" ];
        };
        rhino = mkNixOS {
          hostname = "rhino";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [ "console" "desktop" ];
        };
        soyo = mkNixOS {
          hostname = "soyo";
          username = "jian";
          system = "x86_64-linux";
          homeModules = [ "console" "desktop" ];
        };
        windy = mkNixOS {
          hostname = "windy";
          username = "jianl";
          system = "x86_64-linux";
          homeModules = [ "console" ];
        };
      };
      darwinConfigurations = {
        "MacStudio-von-jian" = mkNixDarwin {
          hostname = "MacStudio-von-jian";
          username = "jian";
          system = "aarch64-darwin";
          homeModules = [ "console" ];
        };
      };
```

- [ ] **Step 3: Update standalone `homeConfigurations`**

```nix
        homeConfig =
          { username, homeModules ? [ "console" ] }:
          home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./users/user.nix
              ./home/standalone.nix
            ];
            extraSpecialArgs = { inherit username inputs homeModules; };
          };
      in
      {
        legacyPackages = {
          homeConfigurations = {
            "jian@linux" = homeConfig { username = "jian"; homeModules = [ "console" "desktop" ]; };
            "jian@wsl" = homeConfig { username = "jian"; homeModules = [ "console" ]; };
            "jian@darwin" = homeConfig { username = "jian"; homeModules = [ "console" ]; };
            "atjiluo" = homeConfig { username = "atjiluo"; homeModules = [ "console" ]; };
            "jianl" = homeConfig { username = "jianl"; homeModules = [ "console" ]; };
          };
        };
```

- [ ] **Step 4: Commit**

```bash
git add flake.nix
git commit -m "refactor: update flake.nix to use homeModules array"
```

### Task 2: Update `users/user.nix` for dynamic imports

**Files:**
- Modify: `users/user.nix`

- [ ] **Step 1: Update `users/user.nix` to handle `homeModules`**

```nix
{ username, homeModules ? [ "console" ], ... }:
{
  imports = [
    ./${username}/home.nix
  ] ++ builtins.map (m: ./modules/${m}/home.nix) homeModules;
}
```

- [ ] **Step 2: Commit**

```bash
git add users/user.nix
git commit -m "refactor: dynamic module imports in user.nix"
```

### Task 3: Clean up user files and set `homeDirectory`

**Files:**
- Modify: `users/jian/home.nix`
- Modify: `users/jianl/home.nix`
- Modify: `users/atjiluo/home.nix`

- [ ] **Step 1: Update `users/jian/home.nix`**

```nix
{ pkgs, username, ... }:
{
  home.username = "jian";
  home.homeDirectory = if pkgs.stdenv.isDarwin then "/Users/jian" else "/home/jian";

  # Git account
  programs.git = {
    settings = {
      user = {
        name = "Jian Luo";
        email = "jian.luo.cn@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  home.stateVersion = "25.11";
}
```

- [ ] **Step 2: Update `users/jianl/home.nix`**

```nix
{ pkgs, username, ... }:
{
  home.username = "jianl";
  home.homeDirectory = "/home/jianl";

  # Git account
  programs.git = {
    settings = {
      user = {
        name = "Jian Luo";
        email = "jian.luo.cn@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  home.stateVersion = "25.11";
}
```

- [ ] **Step 3: Update `users/atjiluo/home.nix`**

```nix
{ pkgs, username, ... }:
{
  home.username = "atjiluo";
  home.homeDirectory = "/home/atjiluo";

  # Git account
  programs.git.settings = {
    user = {
      name = "Jian Luo";
      email = "jian.luo@at.abb.com";
    };
    init.defaultBranch = "main";
  };

  home.stateVersion = "25.11";
}
```

- [ ] **Step 4: Commit**

```bash
git add users/jian/home.nix users/jianl/home.nix users/atjiluo/home.nix
git commit -m "refactor: strip imports and set homeDirectory in user configs"
```

### Task 4: Merge Darwin and LazyVim configurations

**Files:**
- Modify: `users/modules/console/home.nix`
- Delete: `users/jian@darwin`

- [ ] **Step 1: Incorporate Darwin-specific settings into `console` module**

Review `users/jian@darwin/home.nix` and merge useful parts (like `lazyvim` extras) into `users/modules/console/home.nix`. Ensure they are used conditionally if they are darwin-specific, or keep them if they are generally useful.

```nix
  programs.lazyvim = {
    enable = true;
    installCoreDependencies = true;
    extras = {
      lang.nix.enable = true;
      lang.python = {
        enable = true;
        installDependencies = true;
        installRuntimeDependencies = true;
      };
      lang.go = {
        enable = true;
        installDependencies = true;
        installRuntimeDependencies = true;
      };
    };
    extraPackages = with pkgs; [
      nixd
      alejandra
    ];
  };
```

- [ ] **Step 2: Delete `users/jian@darwin`**

```bash
rm -rf users/jian@darwin
```

- [ ] **Step 3: Commit**

```bash
git add users/modules/console/home.nix
git commit -m "feat: merge darwin and lazyvim settings into console module"
```

### Task 5: Final Validation

- [ ] **Step 1: Run sanity check**

Run: `nix flake check` or `nix run .#checks.x86_64-linux.sanity`
