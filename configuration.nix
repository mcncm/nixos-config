# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

with pkgs;
let
  pythonWithPackages = python38.withPackages (ps: with ps; [
    z3

    # scientific
    numpy scipy matplotlib
    cirq qiskit
    (callPackage ./python-modules/qutip/default.nix { })  # until my PR is merged
    pint

    # utility
    requests
    termcolor
    pyyaml
    dbus-python

    # python development
    mypy pytest yapf
    python-language-server pyls-isort pyls-mypy

    # go fast
    numba
  ]);
  ghcWithPackages = haskellPackages.ghcWithPackages (ps: with ps; [
    lens

    # haskell development
    haskell-language-server hlint hoogle
  ]);
  emacsWithPackages = (emacsPackagesGen emacsPgtkGcc).emacsWithPackages
    (epkgs: ([epkgs.vterm]));
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/vinszent/emacs-overlay/archive/1409c99128fce17835e076b27be550ba04196009.tar.gz;
    }))
  ];

 # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixtamal"; # Define your hostname.
  networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s31f6.useDHCP = true;
  networking.interfaces.wlp2s0.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Configure keymap in X11
  services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable bluetooth.
  hardware.bluetooth.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Emacs daemon
  systemd.user.services.emacs.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mcncm = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # Define extra user groups.
  users.groups.external-ssd = {
    # NOTE Is this guaranteed not to collide with anything?
    gid = 500;
    members = [ "mcncm" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # with pkgs;
  environment.systemPackages = with pkgs; [
    # Utilities
    wget vim git gnupg binutils
    htop gotop
    jq fd ripgrep hyperfine
    zip unzip unrar
    sqlite
    alacritty
    aspell wordnet
    rofi grim slurp
    mu offlineimap
    imagemagick feh
    mosh nmap
    brightnessctl

    # Aesthetic things
    neofetch pywal powerline

    # Development
    gcc clang gnumake cmake libtool sccache
    rustup rust-analyzer
    pythonWithPackages python-language-server
    ghcWithPackages
    nixfmt

    # Applications
    zotero
    firefox
    zoom-us
    spotify
    signal-desktop
    slack
    discord

    emacsWithPackages

    # Data
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science

    # swaywm
    (
      pkgs.writeTextFile {
        name = "startsway";
        destination = "/bin/startsway";
        executable = true;
        text = ''
          #! ${pkgs.bash}/bin/bash

          # first import environment variables from the login manager
          systemctl --user import-environment
          # then start the service
          exec systemctl --user start sway.service
        '';
      }
    )
  ];

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swaylock
      xwayland
      waybar
      mako
    ];
  };

  # environment = {
  #   etc = {
  #     # Put config files in /etc. Note that you can also put them in ~/.config, but then you can't manage them with NixOS anymore!
  #     "sway/config".source = ./dotfiles/sway/config;
  #     "xdg/waybar/config".source = ./dotfiles/waybar/config;
  #     "xdg/waybar/style.css".source = ./dotfiles/waybar/style.css;
  #   };
  # };

  systemd.user.targets.sway-session = {
    description = "Sway compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  systemd.user.services.sway = {
    description = "Sway - Wayland window manager";
    documentation = ["man:sway(5)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
    # We explicitly unset PATH here, as we want it to be set by
    # systemctl --user import-environment in startsway
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.dbus}/bin/dbus-run-session ${pkgs.sway}/bin/sway --debug
      '';
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  programs.waybar.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # X windowing things
  services.xserver = {
    enable = false;

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = false;
      extraPackages = with pkgs; [
        dmenu
        i3status
        i3lock
      ];
    };
  };

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf

    # serif
    eb-garamond
    bakoma_ttf

    (nerdfonts.override {
      fonts = [ "FiraCode" ];
    })
  ];

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Enable cron service
  services.cron = {
    enable = true;
    systemCronJobs = [
      # See https://crontab.guru
      "0 4 * * *      mcncm    { date & /home/mcncm/.scripts/backup --force; } >> /tmp/cron.log"
    ];
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
