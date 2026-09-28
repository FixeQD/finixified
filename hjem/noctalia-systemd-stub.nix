{
  lib,
  config,
  ...
}:
{
  options.systemd.services = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    internal = true;
    description = ''
      Stub whose only purpose is to let `noctalia.hjemModules.default` load on the finix backend.
      The `hjem.users.<u>.systemd.*` layer with `restartTriggers` exists only in the NixOS backend.
    '';
  };
  config.assertions = [
    {
      assertion = config.systemd.services == { };
      message = ''
        hjem: `systemd.services` is not supported on the finix backend.
        Start noctalia through niri's `spawn-at-startup` instead of via a systemd unit.
      '';
    }
  ];
}
