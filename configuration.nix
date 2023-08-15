# Edit this configuration file to define what should be installed on
# your system.	Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
	home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-23.05.tar.gz";
  p10kTheme = /home/blackstar/.p10k.zsh;
in
{
	imports =
		[ # Include the results of the hardware scan.
			./hardware-configuration.nix
			(import "${home-manager}/nixos")
      ./nix-alien.nix
		];
		
		home-manager.users.blackstar = {
		/* The home.stateVersion option does not have a default and must be set */
		home.stateVersion = "18.09";
    /* Here goes the rest of your home-manager config, e.g. home.packages = [ pkgs.foo ]; */

    programs.zsh = {
				enable = true;
				shellAliases = {
					ll = "ls -l";
					update = "sudo nixos-rebuild switch";
				};
				history = {
					size = 10000;
					path = "~/.local/share/zsh/history";
        };
        initExtra = ''
          [[ ! -f ${p10kTheme} ]] || source ${p10kTheme}
					if type neofetch > /dev/null; then
   						 neofetch
 				  fi
   		  '';
				zplug = {
					enable = true;
					plugins = [
						{ name = "zsh-users/zsh-autosuggestions"; } # Simple plugin installation
						{ name = "romkatv/powerlevel10k"; tags = [ as:theme depth:1 ]; } # Installations with additional options. For the list of options, please refer to Zplug README.
						{ name = "zdharma/fast-syntax-highlighting"; }
					];
        };

			};

			programs.git = {
				enable = true;
				userName  = "mburuwarui";
				userEmail = "mburuwarui@gmail.com";
			};
	
      # enable prisma dev environment using flakes   
      programs.direnv = {
        enable = true;
        enableZshIntegration = true; # see note on other shells below
        nix-direnv.enable = true;
        };

		};


	# Bootloader.
	boot.loader.systemd-boot.enable = true;
	boot.loader.efi.canTouchEfiVariables = true;

	networking.hostName = "nixos"; # Define your hostname.
	# networking.wireless.enable = true;	# Enables wireless support via wpa_supplicant.

	# Configure network proxy if necessary
	# networking.proxy.default = "http://user:password@proxy:port/";
	# networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

	# Enable networking
	networking.networkmanager.enable = true;

	# Set your time zone.
	time.timeZone = "Africa/Nairobi";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";

	# Enable the X11 windowing system.
	services.xserver.enable = true;

	# Enable the GNOME Desktop Environment.
	services.xserver.displayManager.gdm.enable = true;
	services.xserver.desktopManager.gnome.enable = true;

	# Configure keymap in X11
	services.xserver = {
		layout = "us";
		xkbVariant = "";
	};

	# Enable CUPS to print documents.
	services.printing.enable = true;

	# Enable sound with pipewire.
	sound.enable = true;
	hardware.pulseaudio.enable = false;
	security.rtkit.enable = true;
	services.pipewire = {
		enable = true;
		alsa.enable = true;
		alsa.support32Bit = true;
		pulse.enable = true;
		# If you want to use JACK applications, uncomment this
		#jack.enable = true;

		# use the example session manager (no others are packaged yet so this is enabled by default,
		# no need to redefine it in your config for now)
		#media-session.enable = true;
	};

	# Enable touchpad support (enabled default in most desktopManager).
	# services.xserver.libinput.enable = true;

	# Define a user account. Don't forget to set a password with ‘passwd’.
	users.users.blackstar = {
		isNormalUser = true;
		description = "Blackstar";
		extraGroups = [ "networkmanager" "wheel" "docker" ];
		packages = with pkgs; [
			firefox
		#  thunderbird
		];
	};

	# Allow unfree packages
	nixpkgs.config.allowUnfree = true;

	nixpkgs.config.permittedInsecurePackages = [
                "openssl-1.1.1u"
                "python-2.7.18.6"
              ];

	# List packages installed in system profile. To search, run:
	# $ nix search wget
	environment.systemPackages = (with pkgs; [
		vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
		wget
		curl
		git
    gh
		neovim
		zsh
		zplug
		neofetch
		nodejs_20
		nodePackages_latest.pnpm		
		xclip
		fontconfig
    ntfs3g
    ripgrep
    gcc
    k3s
    k9s
    unzip
    openssl
    direnv
    rustup
    just
    podman-tui
]) ++ (with pkgs.gnomeExtensions; [
    blur-my-shell
    vitals
    openweather
  ]);

	# Some programs need SUID wrappers, can be configured further or are
	# started in user sessions.
	# programs.mtr.enable = true;
	# programs.gnupg.agent = {
	#		enable = true;
	#		enableSSHSupport = true;
	# };

	# List services that you want to enable:
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
	programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;
  environment.variables.EDITOR = "nvim";

  # Kubernetes k3s
  # This is required so that pod can reach the API server (running on port 6443 by default)
  networking.firewall.allowedTCPPorts = [ 6443 ];
  services.k3s.enable = true;
  services.k3s.role = "server";
  services.k3s.extraFlags = toString [
    # "--kubelet-arg=v=4" # Optionally add additional args to k3s
  ];
  # Required by the network policy controller. 
  systemd.services.k3s.path = [ pkgs.ipset ];

  # Export KUBECONFIG for K9s
  environment.etc."profile".text = ''
  export KUBECONFIG=~/.kube/config
  mkdir -p ~/.kube 2> /dev/null
  sudo k3s kubectl config view --raw > "$KUBECONFIG"
  chmod 600 "$KUBECONFIG"
'';

  # Podman Virtualization
  virtualisation = {
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
      # For Nixos version > 22.11
      #defaultNetwork.settings = {
      #  dns_enabled = true;
      #};
    };
  };

  # System Fonts
	fonts = {
	    fonts = with pkgs; [
	      noto-fonts
	      noto-fonts-cjk
	      noto-fonts-emoji
	      font-awesome
	      source-han-sans
	      source-han-sans-japanese
	      source-han-serif-japanese
	      (nerdfonts.override { fonts = [ "Meslo" ]; })
	    ];
	    fontconfig = {
	      enable = true;
	      defaultFonts = {
		      monospace = [ "Meslo LG M Regular Nerd Font Complete Mono" ];
		      serif = [ "Noto Serif" "Source Han Serif" ];
		      sansSerif = [ "Noto Sans" "Source Han Sans" ];
	      };
	    };
	};

	# Enable the OpenSSH daemon.
	# services.openssh.enable = true;

	# Open ports in the firewall.
	# networking.firewall.allowedTCPPorts = [ ... ];
	# networking.firewall.allowedUDPPorts = [ ... ];
	# Or disable the firewall altogether.
	# networking.firewall.enable = false;

  # system auto-upgrade
  system.autoUpgrade.enable = true;  
  system.autoUpgrade.allowReboot = true; 
  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-23.05";

	# This value determines the NixOS release from which the default
	# settings for stateful data, like file locations and database versions
	# on your system were taken. It‘s perfectly fine and recommended to leave
	# this value at the release version of the first install of this system.
	# Before changing this value read the documentation for this option
	# (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
	system.stateVersion = "23.05"; # Did you read the comment?
	
	# config backup 
	system.copySystemConfiguration = true;

}
