# Linux desktop profile — shared by all bare-metal Linux hosts.
# Provides: bootloader, networking, Niri compositor, KDE/SDDM login,
# Bluetooth, Pipewire audio, printing, and core desktop packages.
{
  config,
  pkgs,
  hostname,
  username,
  ...
}:

{
  # --- System services ---
  services.envfs.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # --- Bluetooth (dual-mode for both classic and BLE devices) ---
  services.blueman.enable = true;
  hardware.bluetooth = {
    enable = true;
    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = "true";
        Experimental = "true"; # enables battery reporting, etc.
      };
      Policy = {
        AutoEnable = "true";
      };
    };
  };

  # --- Desktop packages ---
  environment.systemPackages = with pkgs; [
    niri # tiling Wayland compositor (configured per-user in desktop module)
    google-chrome
  ];

  # Niri compositor (system-level integration)
  programs.niri.enable = true;
  # Force Chromium/Electron apps to use native Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.gpu-screen-recorder = {
    enable = true;
  };

  # --- Boot ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # track latest stable kernel

  # --- Networking ---
  networking.networkmanager.enable = true;

  # --- Time and Locale (Berlin / en_US with German formats) ---
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # --- Display: X11/Wayland + SDDM login manager + KDE Plasma 6 ---
  services.xserver = {
    enable = true; # needed even under Wayland for XWayland support
    xkb = {
      layout = "us";
      variant = "altgr-intl"; # US layout with AltGr for accented characters
    };
  };
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # --- Printing ---
  services.printing.enable = true;

  # --- Audio: Pipewire replaces PulseAudio ---
  services.pulseaudio.enable = false; # explicitly off — Pipewire takes over
  security.rtkit.enable = true; # real-time scheduling for low-latency audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true; # PulseAudio compatibility layer
  };

  # --- User account ---
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.sddm-kcm # SDDM configuration module for KDE System Settings
    ];
  };

  programs.firefox.enable = true;

  # Pin to the NixOS release that first installed these hosts.
  # See: https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      ignoreUserConfig = true;
      addons = with pkgs; [
        rime-data
        fcitx5-rime
        fcitx5-gtk
        qt6Packages.fcitx5-chinese-addons
        fcitx5-nord
      ];
      settings.inputMethod = {
        GroupOrder."0" = "Default";
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "pinyin";
        };
        "Groups/0/Items/0".Name = "keyboard-us";
        "Groups/0/Items/1".Name = "pinyin";

      };
    };
  };
}
