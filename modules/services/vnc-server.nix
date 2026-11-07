{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.vncServer;
  user = config.modules.user.name;
  group = config.users.users.${user}.group;

  jsonFormat = pkgs.formats.json { };
  settingsFormat = pkgs.formats.keyValue { };
  wayvncConf = settingsFormat.generate "wayvnc.conf" cfg.settings;

  # ---------------------------------------------------------------- wayvnc

  wayvncCmd =
    (optionalString (cfg.inputWrapper != null) "${getExe cfg.inputWrapper} ")
    + concatStringsSep " " (
      [
        "${cfg.package}/bin/wayvnc"
        "-C ${wayvncConf}"
      ]
      ++ optional cfg.renderCursor "-r"
      ++ [ "-f ${toString cfg.maxFps}" ]
      ++ optional (cfg.output != null) "-o ${escapeShellArg cfg.output}"
      ++ [
        cfg.bindAddr
        (toString cfg.port)
      ]
    );

  # niri creates its socket only after login
  wayvncStart = pkgs.writeShellScript "wayvnc-start" ''
    set -eu
    export XDG_RUNTIME_DIR="/run/user/$(${pkgs.coreutils}/bin/id -u ${user})"

    while :; do
      for s in "$XDG_RUNTIME_DIR"/wayland-*; do
        if [ -S "$s" ]; then
          export WAYLAND_DISPLAY="''${s##*/}"
          exec ${wayvncCmd}
        fi
      done
      ${pkgs.coreutils}/bin/sleep 2
    done
  '';

  # ---------------------------------------------------------- cockpit viewer

  viewerDefaults = {
    scale = "local";
    viewOnly = false;
    shared = true;
    clipViewport = false;
    dragViewport = false;
    showDotCursor = false;
    qualityLevel = 5;
    compressionLevel = 1;
    autoconnect = true;
    reconnect = true;
    reconnectDelay = 2000;
    lockKeyboard = true;
  };

  viewerConfig =
    viewerDefaults
    // cfg.cockpit.viewer
    // {
      address = cfg.cockpit.address;
      port = cfg.cockpit.port;
    };

  manifest = recursiveUpdate {
    version = 0;
    menu.index = {
      label = cfg.cockpit.label;
      order = cfg.cockpit.order;
    };
  } cfg.cockpit.manifest;

  indexHtml = pkgs.writeText "vnc-index.html" ''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>${cfg.cockpit.label}</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <script src="../base1/cockpit.js"></script>
      <link rel="stylesheet" href="vnc.css">
      <script type="module" src="vnc.js"></script>
    </head>
    <body>
      <main id="page">
        <section id="viewer">
          <div id="hotzone"></div>
          <header id="bar">
            <button id="toggle" class="btn primary" type="button">Connect</button>

            <span class="sep"></span>

            <label class="field">
              <span>Scaling</span>
              <select id="scale">
                <option value="off">None</option>
                <option value="local">Fit to window</option>
                <option value="remote">Resize remote</option>
              </select>
            </label>

            <label class="switch">
              <input type="checkbox" id="viewonly">
              <span class="track"></span>
              <span>View only</span>
            </label>

            <input type="password" id="password" class="text" placeholder="VNC password" autocomplete="off" hidden>

            <span class="grow"></span>

            <span id="status" class="label"><i></i><b id="statustext">Disconnected</b></span>

            <button id="cad" class="btn secondary" type="button">Ctrl+Alt+Del</button>
            <button id="fullscreen" class="btn plain icon" type="button" title="Fullscreen" aria-label="Fullscreen">
              <svg id="icon-enter" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/></svg>
              <svg id="icon-exit" viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" hidden><path d="M9 4v5H4M15 4v5h5M9 20v-5H4M15 20v-5h5"/></svg>
            </button>
          </header>
          <div id="screen"></div>
        </section>
      </main>
    </body>
    </html>
  '';

  viewerCss = pkgs.writeText "vnc.css" ''
    :root {
      color-scheme: light;
      --bg-page: #f0f0f0;
      --bg-card: #ffffff;
      --bg-control: #ffffff;
      --bg-hover: #f2f2f2;
      --border: #d2d2d2;
      --border-strong: #8a8d90;
      --text: #151515;
      --text-muted: #6a6e73;
      --primary: #0066cc;
      --primary-hover: #004080;
      --primary-text: #ffffff;
      --ok: #3e8635;
      --warn: #f0ab00;
      --err: #c9190b;
      --radius: 3px;
      --shadow: 0 0.0625rem 0.125rem 0 rgba(3, 3, 3, 0.12), 0 0 0.125rem 0 rgba(3, 3, 3, 0.06);
    }
    :root.dark {
      color-scheme: dark;
      --bg-page: #1b1d21;
      --bg-card: #212427;
      --bg-control: #151515;
      --bg-hover: #2b2e33;
      --border: #4f5255;
      --border-strong: #8a8d90;
      --text: #ffffff;
      --text-muted: #b8bbbe;
      --primary: #4394e5;
      --primary-hover: #92c5f9;
      --primary-text: #151515;
      --ok: #5ba352;
      --warn: #f4c145;
      --err: #ff7468;
      --shadow: none;
    }

    [hidden] { display: none !important; }
    * { box-sizing: border-box; }
    html, body {
      margin: 0; height: 100%;
      background: var(--bg-page); color: var(--text);
      font-family: "RedHatText", "Red Hat Text", system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      font-size: 14px; line-height: 1.5;
    }

    #page { height: 100%; padding: 1rem; }
    #viewer {
      position: relative; height: 100%;
      display: flex; flex-direction: column;
      background: var(--bg-card); border-radius: var(--radius);
      box-shadow: var(--shadow); overflow: hidden;
    }
    :root.dark #viewer { border: 1px solid var(--border); }

    #bar {
      display: flex; align-items: center; gap: 0.75rem; flex-wrap: wrap;
      min-height: 3.5rem; padding: 0.5rem 1rem;
      background: var(--bg-card); border-bottom: 1px solid var(--border);
      z-index: 2;
    }
    .grow { flex: 1; }
    .sep { width: 1px; align-self: stretch; margin: 0.25rem 0; background: var(--border); }

    .btn {
      font: inherit; line-height: 1.5; cursor: pointer;
      padding: 0.375rem 1rem; border: 1px solid transparent; border-radius: var(--radius);
      display: inline-flex; align-items: center; justify-content: center; gap: 0.5rem;
      background: transparent; color: var(--text); white-space: nowrap;
    }
    .btn:focus-visible, select:focus-visible, .text:focus-visible,
    .switch input:focus-visible + .track { outline: 2px solid var(--primary); outline-offset: 2px; }
    .btn.primary { background: var(--primary); color: var(--primary-text); }
    .btn.primary:hover { background: var(--primary-hover); }
    .btn.secondary { border-color: var(--primary); color: var(--primary); }
    .btn.secondary:hover { border-color: var(--primary-hover); color: var(--primary-hover); }
    .btn.plain { color: var(--text-muted); padding: 0.375rem 0.5rem; }
    .btn.plain:hover { color: var(--text); background: var(--bg-hover); }
    .btn:disabled { opacity: 0.5; cursor: default; }

    .field { display: inline-flex; align-items: center; gap: 0.5rem; color: var(--text-muted); }
    select, .text {
      font: inherit; color: var(--text); background: var(--bg-control);
      border: 1px solid var(--border); border-bottom-color: var(--border-strong);
      border-radius: var(--radius); padding: 0.3rem 0.75rem; min-width: 8rem;
    }
    select { padding-right: 0.5rem; cursor: pointer; }

    .switch { display: inline-flex; align-items: center; gap: 0.5rem; cursor: pointer; user-select: none; }
    .switch input { position: absolute; opacity: 0; width: 0; height: 0; }
    .switch .track {
      position: relative; width: 2rem; height: 1.125rem; border-radius: 1rem;
      background: var(--border-strong); transition: background 0.15s;
    }
    .switch .track::after {
      content: ""; position: absolute; top: 0.125rem; left: 0.125rem;
      width: 0.875rem; height: 0.875rem; border-radius: 50%;
      background: #fff; transition: transform 0.15s;
    }
    .switch input:checked + .track { background: var(--primary); }
    .switch input:checked + .track::after { transform: translateX(0.875rem); }

    .label {
      display: inline-flex; align-items: center; gap: 0.5rem;
      padding: 0.125rem 0.75rem; border-radius: 1rem;
      background: var(--bg-hover); border: 1px solid var(--border);
      font-size: 0.8125rem; color: var(--text);
    }
    .label i { width: 0.5rem; height: 0.5rem; border-radius: 50%; background: var(--text-muted); }
    .label.ok i { background: var(--ok); }
    .label.warn i { background: var(--warn); }
    .label.err i { background: var(--err); }

    #screen { position: relative; flex: 1; min-height: 0; background: #000; }

    /* fullscreen: the toolbar floats over the screen and slides in when the pointer hits the top edge */
    #hotzone { display: none; }
    #viewer:fullscreen { border-radius: 0; border: 0; }
    #viewer:fullscreen #screen { position: absolute; inset: 0; }
    #viewer:fullscreen #bar {
      position: absolute; top: 0; left: 0; right: 0;
      transform: translateY(-100%); transition: transform 0.18s ease-out;
      box-shadow: 0 0.25rem 0.5rem rgba(3, 3, 3, 0.3);
    }
    #viewer:fullscreen.bar-visible #bar { transform: none; }
    #viewer:fullscreen #hotzone { display: block; position: absolute; top: 0; left: 0; right: 0; height: 6px; z-index: 3; }

    @media (max-width: 40rem) {
      #page { padding: 0; }
      #viewer { border-radius: 0; }
    }
    ${cfg.cockpit.css}
  '';

  viewerJs = pkgs.writeText "vnc.js" ''
    import RFB from "./novnc/core/rfb.js";

    const $ = (id) => document.getElementById(id);
    const cfg = await fetch("config.json").then((r) => r.json());

    let rfb = null;
    let wanted = cfg.autoconnect;
    let timer = null;

    function applyTheme() {
      let style = "auto";
      try {
        style = localStorage.getItem("shell:style") || "auto";
      } catch (e) {}
      const dark = style === "dark" || (style === "auto" && matchMedia("(prefers-color-scheme: dark)").matches);
      document.documentElement.classList.toggle("dark", dark);
      document.documentElement.classList.toggle("pf-v5-theme-dark", dark);
    }
    applyTheme();
    addEventListener("storage", applyTheme);
    matchMedia("(prefers-color-scheme: dark)").addEventListener("change", applyTheme);

    function status(text, kind) {
      $("statustext").textContent = text;
      $("status").className = "label" + (kind ? " " + kind : "");
    }
    status("Disconnected");

    $("scale").value = cfg.scale;
    $("viewonly").checked = cfg.viewOnly;

    function channelUrl() {
      const prefix = new URL(cockpit.transport.uri("channel/" + cockpit.transport.csrf_token)).pathname;
      const query = JSON.stringify({
        payload: "stream",
        binary: "raw",
        address: cfg.address,
        port: cfg.port,
        host: cockpit.transport.host,
      });
      const proto = location.protocol === "https:" ? "wss" : "ws";
      return proto + "://" + location.host + prefix + "?" + btoa(query);
    }

    function applyView() {
      if (!rfb) return;
      const mode = $("scale").value;
      rfb.scaleViewport = mode === "local";
      rfb.resizeSession = mode === "remote";
      rfb.clipViewport = cfg.clipViewport;
      rfb.dragViewport = cfg.dragViewport;
      rfb.showDotCursor = cfg.showDotCursor;
      rfb.qualityLevel = cfg.qualityLevel;
      rfb.compressionLevel = cfg.compressionLevel;
      rfb.viewOnly = $("viewonly").checked;
    }

    async function connect() {
      clearTimeout(timer);
      if (rfb) return;
      await new Promise((resolve) => cockpit.transport.wait(resolve));
      status("Connecting...", "warn");
      rfb = new RFB($("screen"), channelUrl(), { shared: cfg.shared });
      applyView();

      rfb.addEventListener("connect", () => {
        status("Connected", "ok");
        $("toggle").textContent = "Disconnect";
        rfb.focus();
      });

      rfb.addEventListener("disconnect", (e) => {
        rfb = null;
        $("toggle").textContent = "Connect";
        $("password").hidden = true;
        if (e.detail.clean) {
          status("Disconnected");
        } else {
          status("Connection lost", "err");
        }
        if (wanted && cfg.reconnect) timer = setTimeout(connect, cfg.reconnectDelay);
      });

      rfb.addEventListener("credentialsrequired", () => {
        $("password").hidden = false;
        $("password").value = "";
        $("password").focus();
        status("Password required", "warn");
      });

      rfb.addEventListener("securityfailure", (e) => {
        status("Auth failed: " + (e.detail.reason || "unknown"), "err");
      });
    }

    $("toggle").addEventListener("click", () => {
      if (rfb) {
        wanted = false;
        rfb.disconnect();
      } else {
        wanted = true;
        connect();
      }
    });

    $("password").addEventListener("keydown", (e) => {
      if (e.key !== "Enter" || !rfb) return;
      rfb.sendCredentials({ password: e.target.value });
      e.target.hidden = true;
    });

    $("cad").addEventListener("click", () => rfb && rfb.sendCtrlAltDel());
    $("scale").addEventListener("change", applyView);
    $("viewonly").addEventListener("change", applyView);

    // -------------------------------------------------------- fullscreen
    const viewer = $("viewer");
    let hideTimer = null;

    function inFullscreen() {
      return document.fullscreenElement === viewer;
    }

    function showBar() {
      viewer.classList.add("bar-visible");
      clearTimeout(hideTimer);
    }

    function hideBarSoon() {
      clearTimeout(hideTimer);
      hideTimer = setTimeout(() => {
        // keep the bar while a control inside it has focus (open dropdown, password entry)
        if (!$("bar").matches(":hover") && !$("bar").contains(document.activeElement)) {
          viewer.classList.remove("bar-visible");
        } else {
          hideBarSoon();
        }
      }, 1200);
    }

    function lockKeys() {
      if (!cfg.lockKeyboard || !inFullscreen()) return;
      if (navigator.keyboard && navigator.keyboard.lock) navigator.keyboard.lock().catch(() => {});
    }

    function unlockKeys() {
      if (navigator.keyboard && navigator.keyboard.unlock) navigator.keyboard.unlock();
    }

    // the lock is dropped when the window loses focus, take it again when it comes back
    addEventListener("focus", lockKeys);

    async function toggleFullscreen() {
      try {
        if (inFullscreen()) {
          await document.exitFullscreen();
        } else {
          await viewer.requestFullscreen({ navigationUI: "hide" });
        }
      } catch (e) {
        status("Fullscreen unavailable", "err");
      }
    }

    document.addEventListener("fullscreenchange", () => {
      const fs = inFullscreen();
      $("icon-enter").hidden = fs;
      $("icon-exit").hidden = !fs;
      $("fullscreen").title = fs ? "Exit fullscreen" : "Fullscreen";
      viewer.classList.remove("bar-visible");
      if (fs) {
        showBar();
        hideBarSoon();
        lockKeys();
      } else {
        unlockKeys();
      }
      if (rfb) rfb.focus();
    });

    $("hotzone").addEventListener("mouseenter", showBar);
    $("bar").addEventListener("mouseleave", () => inFullscreen() && hideBarSoon());
    $("bar").addEventListener("mouseenter", showBar);
    $("fullscreen").addEventListener("click", toggleFullscreen);

    // mouse movement over the canvas never reaches #hotzone once noVNC grabs it, so watch the viewer too
    viewer.addEventListener("mousemove", (e) => {
      if (inFullscreen() && e.clientY <= 6) {
        showBar();
        hideBarSoon();
      }
    });

    if (wanted) connect();
  '';

  viewerPlugin = pkgs.runCommand "cockpit-vnc" { } ''
    d="$out/share/cockpit/${cfg.cockpit.name}"
    mkdir -p "$d/novnc"
    cp -r --no-preserve=mode ${cfg.cockpit.novncPackage}/share/webapps/novnc/core "$d/novnc/core"
    cp -r --no-preserve=mode ${cfg.cockpit.novncPackage}/share/webapps/novnc/vendor "$d/novnc/vendor"
    cp ${jsonFormat.generate "manifest.json" manifest} "$d/manifest.json"
    cp ${jsonFormat.generate "config.json" viewerConfig} "$d/config.json"
    cp ${indexHtml} "$d/index.html"
    cp ${viewerCss} "$d/vnc.css"
    cp ${viewerJs} "$d/vnc.js"
  '';
in
{
  imports = [
    ../firewall/default.nix
    ./cockpit.nix
  ];

  options.modules.vncServer = {
    enable = mkEnableOption "wayvnc VNC server for the niri session";

    package = mkPackageOption pkgs "wayvnc" { };

    bindAddr = mkOption {
      type = types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = ''
        Address wayvnc listens on. The cockpit viewer only needs localhost.
      '';
    };

    port = mkOption {
      type = types.port;
      default = 5900;
      description = "Port wayvnc listens on.";
    };

    output = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "eDP-1";
      description = "Output to capture (see `niri msg outputs`). If null, wayvnc picks one.";
    };

    inputWrapper = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression "pkgs.wl-uinput-proxy";
      description = ''
        Program wayvnc is launched through, e.g. wl-uinput-proxy, which fakes
        virtual keyboard and pointer via /dev/uinput. Use it if mouse or
        keyboard input does not work in niri.
      '';
    };

    maxFps = mkOption {
      type = types.ints.positive;
      default = 60;
      description = "Frame rate limit (`wayvnc -f`, wayvnc's own default is 30).";
    };

    renderCursor = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Draw the pointer into the captured frames (`wayvnc -r`). niri does not
        hand wayvnc a separate cursor image, so without this the cursor is invisible in the viewer.
      '';
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open the wayvnc port in `modules.firewall` (only needed for native VNC clients).";
    };

    settings = mkOption {
      type = settingsFormat.type;
      default = { };
      example = literalExpression ''
        {
          enable_auth = false;
        }
      '';
      description = "Contents of the wayvnc config file, see `man wayvnc.5`.";
    };

    cockpit = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Add a VNC viewer page to Cockpit (requires `modules.cockpit.enable`).";
      };

      name = mkOption {
        type = types.str;
        default = "vnc";
        description = "Cockpit package name, which is also the page URL (`/vnc`).";
      };

      label = mkOption {
        type = types.str;
        default = "Desktop";
        description = "Entry name in the Cockpit sidebar and page title.";
      };

      order = mkOption {
        type = types.int;
        default = 60;
        description = "Position of the entry in the Cockpit sidebar.";
      };

      novncPackage = mkPackageOption pkgs "novnc" { };

      address = mkOption {
        type = types.str;
        default = if cfg.bindAddr == "0.0.0.0" then "127.0.0.1" else cfg.bindAddr;
        defaultText = literalExpression ''"127.0.0.1" (or bindAddr when it is a specific address)'';
        description = "VNC host that cockpit-bridge connects to. Can point at any other VNC server too.";
      };

      port = mkOption {
        type = types.port;
        default = cfg.port;
        defaultText = literalExpression "config.modules.vncServer.port";
        description = "VNC port that cockpit-bridge connects to.";
      };

      viewer = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            scale = "off";          # off | local | remote
            viewOnly = true;
            qualityLevel = 9;       # 0 to 9
            compressionLevel = 0;   # 0 to 9
            autoconnect = false;
            reconnectDelay = 5000;
          }
        '';
        description = ''
          Viewer defaults, merged over the built in ones key by key
        '';
      };

      css = mkOption {
        type = types.lines;
        default = "";
        example = ''
          #bar { height: 2.5rem; }
        '';
        description = "Extra CSS appended to the viewer stylesheet (vnc.css).";
      };

      manifest = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            menu.index.docs = [ { label = "wayvnc"; url = "https://github.com/any1/wayvnc"; } ];
          }
        '';
        description = "Extra Cockpit manifest.json content, merged recursively over the generated one.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = [ cfg.package ];

      finit.services.wayvnc = {
        description = "wayvnc VNC server (niri)";
        runlevel = "34";
        conditions = [
          "service/syslogd/ready"
          "service/seatd/ready"
        ];
        inherit user group;
        command = "${wayvncStart}";
        respawn = true;
        log = true;
      };

      modules.firewall.rules = mkIf cfg.openFirewall {
        wayvnc = {
          proto = "tcp";
          ports = [ cfg.port ];
          comment = "wayvnc";
        };
      };
    }

    (mkIf cfg.cockpit.enable {
      modules.cockpit.plugins = [ viewerPlugin ];
    })
  ]);
}
