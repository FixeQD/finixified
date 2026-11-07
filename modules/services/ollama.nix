{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.ollama;
in
{
  options.modules.ollama = {
    enable = mkEnableOption "Ollama LLM server";

    package = mkOption {
      type = types.package;
      default = pkgs.ollama-vulkan;
      defaultText = literalExpression "pkgs.ollama-vulkan";
      description = "The Ollama package to use.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address Ollama listens on.";
    };

    port = mkOption {
      type = types.port;
      default = 11434;
      description = "Port Ollama listens on.";
    };

    modelsDir = mkOption {
      type = types.path;
      default = "/var/lib/ollama";
      description = "Directory for Ollama models and state.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          OLLAMA_DEBUG = "1";
        }
      '';
      description = "Extra environment variables passed to the Ollama service.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    users.groups.ollama = { };
    users.users.ollama = {
      isSystemUser = true;
      group = "ollama";
      home = cfg.modelsDir;
      createHome = false;
      description = "Ollama service user";
    };

    finit.tmpfiles.rules = [
      "d ${cfg.modelsDir} 0750 ollama ollama -"
    ];

    finit.services.ollama = {
      description = "Ollama LLM server";
      runlevels = "2345";
      conditions = [ "service/syslogd/ready" ];
      command = "${cfg.package}/bin/ollama serve";
      environment = {
        OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        OLLAMA_MODELS = cfg.modelsDir;
        HOME = cfg.modelsDir;
      }
      // cfg.environment;
      user = "ollama:ollama";
      respawn = true;
      log = true;
      cgroup.user = { };
    };
  };
}
