# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

with pkgs;
let
  python-packages = (ps:
    with ps; [
      z3
      # scientific

      # Cirq fails a test. Build without testing.
      # cirq.overridePythonAttrs
      # (oldattrs: { checkPhase = ""; })

      ipython
      jupyter
      matplotlib
      numpy
      pint
      # pytorch
      # Currently broken on NixOS 21.05
      # qiskit
      scipy
      # # Currently broken: some wrong version of numpy
      # (callPackage ./python/qutip/default.nix { }) # until my PR is merged
      # # (callPackage ./python/pycavy/default.nix { })
      # (callPackage ./python/pylatex/default.nix { })
      h5py

      # utility
      appdirs
      daemonize
      dbus-python
      pyyaml
      requests
      termcolor
      pygments

      # python development
      mypy
      # pyls-isort
      # pyls-mypy
      pytest
      # python-language-server
      yapf

      # go fast
      numba

      # # web
      # django
    ]);
  # ghcWithPackages = haskellPackages.ghcWithPackages (ps:
  #   with ps; [
  #     lens

  #     # haskell development
  #     haskell-language-server
  #     hlint
  #     hoogle
  #     stack
  #   ]);

  emacsWithPackages =
    (emacsPackagesGen emacsGcc).emacsWithPackages (epkgs: ([ epkgs.vterm ]));

  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in {
  imports = [
    ./cachix.nix
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    # Now in NixOS 21.05?
    # ./zsa/default.nix
    ./power-management.nix
    ./networks.nix
    ./services.nix
    # <nixos-unstable/nixos/modules/services/databases/influxdb2.nix>

  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url =
        "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
    }))
    (import "${
        fetchTarball
        "https://github.com/nix-community/fenix/archive/master.tar.gz"
      }/overlay.nix")
  ];

  hardware.cpu.intel.updateMicrocode = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  # Otherwise, the boot partition will run out of space and you won't be able to
  # rebuind you won't be able to rebuild.
  boot.loader.systemd-boot.configurationLimit = 100;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices.luksroot = {
    device = "/dev/disk/by-uuid/c5c44b85-7584-4665-a81e-9d0b554e8ae0";
    preLVM = true;
    allowDiscards = true;
  };

  # # Kernel settings to use rr
  # boot.kernel.sysctl = {
  #   "kernel.perf_event_paranoid" = mkOverride 50 1;
  # };

  networking = {
    hostName = "nixtamal"; # Define your hostname.
    wireless.enable = true; # Enables wireless support via wpa_supplicant.
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  # networking.interfaces.enp0s31f6.useDHCP = true;
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
  services.xserver.xkbOptions = "caps:swapescape";
  services.xserver.autoRepeatDelay = 170;
  services.xserver.autoRepeatInterval = 70;

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.hplipWithPlugin ];

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
  };

  hardware.opengl.driSupport32Bit = true;

  # Enable hardware.
  hardware.bluetooth.enable = true;

  # Bluetooth GUI
  services.blueman.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Emacs daemon
  systemd.user.services.emacs.enable = true;

  # zsa keyboard udev rules
  hardware.keyboard.zsa.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mcncm = {
    isNormalUser = true;
    extraGroups = [ "wheel" "plugdev" "libvirtd" ];
  };

  # Define extra user groups.
  users.groups.external-ssd = {
    # NOTE Is this guaranteed not to collide with anything?
    gid = 500;
    members = [ "mcncm" ];
  };

  # Another user account for testing certain applications where we need an
  # unprivileged user
  users.users.untrusted = {
    isNormalUser = true;
    uid = 600;
  };

  # QEMU virtualization
  # virtualisation.libvirtd = { enable = true; };

  # VirtualBox virtualization
  virtualisation.virtualbox.host = { enable = true; };

  # Some builds fail when they run out of space in /run/user/1000
  services.logind.extraConfig = "RuntimeDirectorySize=4G";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # with pkgs;
  environment.systemPackages = with pkgs; [
    # # Utilities
    wget
    vim
    # neovim-nightly
    git
    bfg-repo-cleaner
    # gnupg
    binutils
    whois
    htop
    gotop
    jq
    fd
    ripgrep
    hyperfine
    cloc
    zip
    unzip
    unrar
    sqlite
    alacritty
    aspell
    wordnet
    rofi
    grim
    slurp
    mu
    offlineimap
    imagemagick
    feh
    vlc
    mosh
    nmap
    brightnessctl
    strace
    wally-cli
    texlive.combined.scheme-full
    direnv
    nix-direnv
    # pinentry-curses
    pinentry-gnome
    pinentry-emacs

    ### Aesthetic things
    neofetch
    pywal
    powerline

    ### Development
    ## Languages/compilers
    gcc
    # clang
    libtool
    (python38.withPackages python-packages)
    # ghcWithPackages
    # lean
    # mathlibtools
    coq
    # agda
    # idris2
    # fstar
    jdk11

    ## Build tools, static analysis tools, etc.
    sccache
    gnumake
    nixfmt
    cmake
    cachix
    (fenix.latest.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer-nightly

    # Some libraries/tools needed for building Rust applications with openssl
    libiconv
    openssl
    pkgconfig

    # Applications
    zotero
    firefox-wayland
    spotify
    signal-desktop
    slack
    discord
    inkscape

    emacsWithPackages

    # Data
    aspellDicts.en
    aspellDicts.en-computers
    aspellDicts.en-science

    # swaywm
    (pkgs.writeTextFile {
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
    })
  ];

  environment.pathsToLink = [ "/share/nix-direnv" ];

  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [ swaylock xwayland waybar mako ];
  };

  # Firefox on Wayland
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "-1";
    XDG_CURRENT_DESKTOP = "sway";
  };

  systemd.user.targets.sway-session = {
    description = "Sway compositor session";
    documentation = [ "man:systemd.special(7)" ];
    bindsTo = [ "graphical-session.target" ];
    wants = [ "graphical-session-pre.target" ];
    after = [ "graphical-session-pre.target" ];
  };

  systemd.user.services.sway = {
    description = "Sway - Wayland window manager";
    documentation = [ "man:sway(5)" ];
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
  programs.gnupg.agent = {
    enable = true;
    # pinentryFlavor = "curses";
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # X windowing things
  services.xserver = {
    enable = false;

    desktopManager = { xterm.enable = false; };

    displayManager = { defaultSession = "none+i3"; };

    windowManager.i3 = {
      enable = false;
      extraPackages = with pkgs; [ dmenu i3status i3lock ];
    };
  };

  fonts.fonts = with pkgs; [
    corefonts
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    twitter-color-emoji
    liberation_ttf
    fantasque-sans-mono
    roboto-mono
    symbola
    lmodern # latin modern
    vistafonts # Calibri, etc.

    # serif
    eb-garamond
    bakoma_ttf

    (nerdfonts.override { fonts = [ "FiraCode" ]; })
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

  ### Databases

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_14;
    settings = { shared_preload_libraries = "timescaledb"; };
    extraPlugins = [ pkgs.postgresql14Packages.timescaledb ];
  };

  services.redis.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Speed up direnv
  services.lorri.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

}
