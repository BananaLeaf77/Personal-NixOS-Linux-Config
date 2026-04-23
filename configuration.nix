{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };
  # ─────────────────────────────────────────────
  # Boot
  # ─────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  # ─────────────────────────────────────────────
  # Wallpaper
  # ─────────────────────────────────────────────
  # Luca Bravo – blue bokeh (Unsplash, free to use)
  # Downloaded at build time, set via dconf for all users.
  environment.etc."wallpaper.jpg" = {
    source = pkgs.fetchurl {
      url    = "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1366&h=768&fit=crop&q=85";
      sha256 = "sha256-ZSLiRNHar2appSE8E7dkVHSQcGDLKlZRC5IlQCc/R/8=";
    };
  };

  # ─────────────────────────────────────────────
  # Networking
  # ─────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # ─────────────────────────────────────────────
  # Locale & Time
  # ─────────────────────────────────────────────
  time.timeZone = "Asia/Makassar";
  i18n.defaultLocale = "en_US.UTF-8";

  # ─────────────────────────────────────────────
  # Desktop — GNOME
  # ─────────────────────────────────────────────
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # ─────────────────────────────────────────────
  # Sound (PipeWire)
  # ─────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ─────────────────────────────────────────────
  # Printing
  # ─────────────────────────────────────────────
  services.printing.enable = true;

  # ─────────────────────────────────────────────
  # Bluetooth
  # ─────────────────────────────────────────────
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # ─────────────────────────────────────────────
  # PostgreSQL
  # ─────────────────────────────────────────────
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    enableTCPIP = true;
    authentication = lib.mkOverride 10 ''
      local all all trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "pg-init" ''
      CREATE USER dev WITH SUPERUSER PASSWORD 'dev';
      CREATE DATABASE dev OWNER dev;
    '';
  };

  # ─────────────────────────────────────────────
  # Redis
  # ─────────────────────────────────────────────
  services.redis.servers."" = {
    enable = true;
    bind = "127.0.0.1";
    port = 6379;
  };

  # ─────────────────────────────────────────────
  # Docker
  # ─────────────────────────────────────────────
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # ─────────────────────────────────────────────
  # GSConnect firewall ports (KDE Connect protocol for GNOME)
  # ─────────────────────────────────────────────
  networking.firewall = {
    enable = true;
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };

  # ─────────────────────────────────────────────
  # User
  # ─────────────────────────────────────────────
  users.users.mira = {
    isNormalUser = true;
    description = "Mira";
    extraGroups = [ "networkmanager" "wheel" "docker" "audio" "video" "wireshark" ];
    shell = pkgs.zsh;
    initialPassword = "nixmir124!";
  };

  # ─────────────────────────────────────────────
  # Shell — Zsh
  # ─────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [ "git" "golang" "docker" "npm" "history" "z" ];
    };
    shellAliases = {
      ll      = "ls -la";
      gs      = "git status";
      gp      = "git push";
      gc      = "git commit";
      gco     = "git checkout";
      dcup    = "docker compose up -d";
      dcdown  = "docker compose down";
      dclogs  = "docker compose logs -f";
      psql-l  = "psql -U dev -d dev";
      redis-c = "redis-cli";
    };
    interactiveShellInit = ''
      export GOPATH="$HOME/go"
      export PATH="$GOPATH/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # ─────────────────────────────────────────────
  # Programs with special NixOS options
  # ─────────────────────────────────────────────
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      core.editor = "nvim";
      pull.rebase = false;
    };
  };

  programs.wireshark = {
    enable = true;
    package = pkgs.wireshark;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
  };

  # ─────────────────────────────────────────────
  # dconf — GNOME settings & keyboard shortcuts
  # ─────────────────────────────────────────────
  # Full nix store paths are used for commands so dconf can
  # find the binaries regardless of the session $PATH.
  programs.dconf = {
    enable = true;
    profiles.user.databases = [{
      settings = {

        # ── Register all custom keybindings ────
        "org/gnome/settings-daemon/plugins/media-keys" = {
          custom-keybindings = [
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6/"
            "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7/"
          ];

        };

        "org/gnome/desktop/background" = {
          picture-uri       = "file:///etc/wallpaper.jpg";
          picture-uri-dark  = "file:///etc/wallpaper.jpg";
          picture-options   = "zoom";
        };

        # ── Ctrl+Alt+T → Terminal (GNOME Console) ──
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          name    = "Terminal";
          command = "${pkgs.gnome-console}/bin/kgx";
          binding = "<Control><Alt>t";
        };

        # ── Win+V → CopyQ ───────────────────────
        # QT_QPA_PLATFORM=xcb forces XWayland so CopyQ renders properly
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          name    = "CopyQ";
          command = "env QT_QPA_PLATFORM=xcb ${pkgs.copyq}/bin/copyq toggle";
          binding = "<Super>v";
        };

        # ── Win+E → Nautilus (Files) ────────────
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
          name    = "Files";
          command = "${pkgs.nautilus}/bin/nautilus";
          binding = "<Super>e";
        };

        # ── Win+F → Firefox ─────────────────────
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
          name    = "Firefox";
          command = "${pkgs.firefox}/bin/firefox";
          binding = "<Super>f";
        };

        # ── Win+Shift+F → Firefox Private ───────
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom4" = {
          name    = "Firefox Private";
          command = "${pkgs.firefox}/bin/firefox --private-window";
          binding = "<Super><Shift>f";
        };

        # ── Win+B → Brave ────────────────────────
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom5" = {
          name    = "Brave";
          command = "${pkgs.brave}/bin/brave";
          binding = "<Super>b";
        };

        # ── Win+D → Show Desktop (minimize all) ─
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom6" = {
          name    = "Show Desktop";
          command = "/etc/show-desktop.sh";
          binding = "<Super>d";
        };

        # ── Win+C → VS Code ──────────────────────
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom7" = {
          name    = "VS Code";
          command = "${pkgs.vscode}/bin/code";
          binding = "<Super>c";
        };

        # ── Win+W → Close window (like Alt+F4) ──
        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Super>w" "<Alt>F4" ];
        };

        # ── Free Win+V from GNOME notification tray ──
        # Default is Super+v; moved to Super+n to free it for CopyQ
        "org/gnome/shell/keybindings" = {
          toggle-message-tray = [ "<Super>n" ];
        };

      };
      locks = [];
    }];
  };

  # ─────────────────────────────────────────────
  # CopyQ — autostart via systemd user service
  # ─────────────────────────────────────────────
  # QT_QPA_PLATFORM=xcb keeps CopyQ on XWayland so it
  # can monitor the clipboard and render its window.
  systemd.user.services.copyq = {
    description = "CopyQ clipboard manager";
    wantedBy    = [ "graphical-session.target" ];
    partOf      = [ "graphical-session.target" ];
    environment = {
      QT_QPA_PLATFORM = "xcb";
    };
    serviceConfig = {
      ExecStart = "${pkgs.copyq}/bin/copyq";
      Restart   = "on-failure";
    };
  };

  # ─────────────────────────────────────────────
  # Packages
  # ─────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [

    # ── Dev: Go ───────────────────────────────
    go
    gopls
    golangci-lint
    delve              # Go debugger
    air                # Live reload for Go

    # ── Dev: Node / Bun ───────────────────────
    nodejs_22
    nodePackages.npm
    bun

    # ── Dev: DB / Cache tools ─────────────────
    dbeaver-bin        # DBeaver
    pgcli              # Postgres CLI with autocomplete
    redis              # includes redis-cli

    # ── Dev: API / Network ────────────────────
    # hoppscotch: web app — flatpak install flathub io.hoppscotch.hoppscotch
    nmap
    wireshark
    curl
    wget
    httpie

    # ── Dev: Containers ───────────────────────
    docker
    docker-compose
    podman
    podman-desktop

    # ── Dev: General ──────────────────────────
    git
    gh                 # GitHub CLI
    neovim
    gnumake
    gcc
    pkg-config
    openssl
    jq
    yq-go
    ripgrep
    fd
    fzf
    bat
    eza                # modern ls
    tmux
    htop
    btop

    # ── Editors / IDEs ────────────────────────
    vscode             # VS Code (unfree)
    antigravity        # Agentic IDE (unfree)
    # cursor: not in nixpkgs — grab .AppImage from cursor.sh

    # ── Browsers ──────────────────────────────
    brave
    firefox

    # ── Communication ─────────────────────────
    discord
    # whatsapp: flatpak install flathub io.github.mimbrero.WhatsAppDesktop
    telegram-desktop
    thunderbird

    # ── Productivity / Office ─────────────────
    libreoffice-fresh
    copyq              # clipboard manager — autostarted via systemd (see above)

    # ── Media ─────────────────────────────────
    vlc
    obs-studio

    # ── Game / Creative Dev ───────────────────
    godot_4

    # ── System / Disk Tools ───────────────────
    gparted
    # balena-etcher: not in nixpkgs — flatpak install flathub io.balena.etcher

    # ── GNOME Connect (KDE Connect protocol) ──
    gnomeExtensions.gsconnect

    # ── Fonts ─────────────────────────────────
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    font-awesome

    # ── Misc ──────────────────────────────────
    unzip
    p7zip
    xclip
    wl-clipboard       # Wayland clipboard

  ];

  # ─────────────────────────────────────────────
  # Flatpak (for apps not in nixpkgs)
  # ─────────────────────────────────────────────
  services.flatpak.enable = true;
  # After rebuild, run:
  #   flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  #   flatpak install flathub io.hoppscotch.hoppscotch
  #   flatpak install flathub io.balena.etcher
  #   flatpak install flathub io.github.mimbrero.WhatsAppDesktop

  # ─────────────────────────────────────────────
  # Fonts
  # ─────────────────────────────────────────────
  fonts.enableDefaultPackages = true;

  # ─────────────────────────────────────────────
  # XDG portals (needed for Flatpak + Wayland)
  # ─────────────────────────────────────────────
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # ─────────────────────────────────────────────
  # Security
  # ─────────────────────────────────────────────
  security.sudo.wheelNeedsPassword = true;

  # ─────────────────────────────────────────────
  # NixOS state version — do not change after install
  # ─────────────────────────────────────────────
  system.stateVersion = "24.11";
}
