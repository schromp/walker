inputs: {
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  defaultConfig = builtins.fromJSON (builtins.readFile ../config/config.default.json);
  defaultStyle = builtins.readFile ../ui/themes/style.default.css;
  cfg = config.programs.walker;
in {
  options = {
    programs.walker = with lib; {
      enabled = mkEnableOption "Enable walker";
      runAsService = mkOption {
        type = types.bool;
        default = false;
        description = "Run as service";
      };
      style = mkOption {
        type = types.str;
        default = defaultStyle;
        description = "Theming";
      };
      config = mkOption {
        type = types.attrs;
        default = defaultConfig;
        description = "Configuration";
      };
    };
  };

  config = lib.mkIf cfg.enabled {
    home.packages = [inputs.self.packages.${system}.walker];

    xdg.configFile."walker/config.json".text = builtins.toJSON (defaultConfig // config.programs.walker.config);
    xdg.configFile."walker/style.css".text = config.programs.walker.style;

    systemd.user.services.walker = lib.mkIf cfg.runAsService {
      Unit = {
        Description = "Walker - Application Runner";
      };
      Install = {
        WantedBy = [
          "graphical-session.target"
        ];
      };
      Service = {
        ExecStart = "${inputs.self.packages.${system}.walker}/bin/walker --gapplication-service";
      };
    };
  };
}
