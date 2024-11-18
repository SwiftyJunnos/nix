{
  description = "Junnos nix-darwin system flake";

  inputs = {
    # ⓘ defines the repository for nixpkgs and nix-darwin
    # ! temporary fix for nixpkgs & nix-darwin build fail on :
    #  error: builder for '/nix/store/86459mqpi8i02zf182y96964yajz9v4d-darwin-manual-html.drv' failed with exit code 1;
    # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # ✏️ This error is caused by the new redirects system that got added to nixos-render-docs yesterday in this commit to nixpkgs. Running the installer with the commit pinned to the commit before the redirects system was introduced, I was able to install nix-darwin successfully. then updated the nixpkgs url before installation.
    # 🌐 https://github.com/LnL7/nix-darwin/issues/1176#issuecomment-2480752009
    nixpkgs.url = "github:NixOS/nixpkgs/8809585e6937d0b07fc066792c8c9abf9c3fe5c4";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs =
    inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, ... }:
    let
      configuration =
        { pkgs, config, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.chezmoi
            pkgs.curl
            pkgs.discord
            pkgs.fastfetch
            pkgs.gh
            pkgs.gifski
            pkgs.git
            pkgs.git-lfs
            pkgs.gitkraken
            pkgs.gitmoji-cli
            pkgs.home-assistant-cli
            pkgs.iterm2
            pkgs.kubectl
            pkgs.mas
            pkgs.mkalias
            pkgs.mos
            pkgs.neovim
            pkgs.nixpkgs-fmt
            pkgs.obsidian
            pkgs.postman
            pkgs.pre-commit
            pkgs.raycast
            pkgs.slack
            pkgs.tableplus
            pkgs.vscode
            pkgs.watch
            pkgs.zoom-us
          ];

          homebrew = {
            enable = true;
            taps = [

            ];
            brews = [

            ];
            casks = [
                "1password"
                "1password-cli"
                "aldente"
                "betterdisplay"
                "cursor"
                "figma"
                "huly"
                "iina"
                "notchnook"
                "notion"
                "nvidia-geforce-now"
                "orbstack"
                "proton-mail"
                "warp"
                "zed"
            ];
            masApps = {
                "Commander One" = 1035236694;
                "KakaoTalk" = 869223134;
                "LINE" = 539883307;
                "Microsoft Outlook" = 985367838;
                "Microsoft Word" = 462054704;
                "Microsoft Excel" = 462058435;
                "Microsoft PowerPoint" = 462062816;
                "PiPer" = 1421915518;
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };

          environment.variables = {
            EDITOR = "nvim";
            LANG = "en_KR.UTF-8";
          };

          system.defaults = {
            dock.persistent-apps = [
                "/Applications/Zen Browser.app"
                "/Applications/Proton Mail.app"
                "/System/Applications/Messages.app"
                "${pkgs.discord}/Applications/Discord.app"
                "/Applications/Warp.app"
                "${pkgs.vscode}/Applications/Visual Studio Code.app"
                "/Applications/Xcode.app"
                "${pkgs.obsidian}/Applications/Obsidian.app"
            ];
            finder.FXPreferredViewStyle = "clmv";
            NSGlobalDomain.AppleICUForce24HourTime = true;
          };

          fonts.packages = [
            (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
          ];

          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                  app_name=$(basename "$src")
                  echo "copying $src" >&2
                  ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';

          # Auto upgrade nix package and the daemon service.
          services.nix-daemon.enable = true;
          # nix.package = pkgs.nix;

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Create /etc/zshrc that loads the nix-darwin environment.
          programs.zsh.enable = true; # default shell
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 5;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#simple
      darwinConfigurations."junnos-pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "junnos";

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."junnos-pro".pkgs;
    };
}
