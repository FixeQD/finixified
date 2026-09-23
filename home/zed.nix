{ ... }:
{
  programs.zed-editor = {
    enable = true;

    extensions = [
      "catppuccin"
      "material-icon-theme"
      "discord-presence"
      "toml"
      "nix"
      "fish"
      "git-firefly"
    ];

    userSettings = {
      cli_default_open_behavior = "existing_window";

      project_panel.dock      = "left";
      outline_panel.dock      = "left";
      collaboration_panel.dock = "left";
      git_panel.dock          = "left";

      agent = {
        dock = "right";
        tool_permissions.tools = {
          edit_file.default = "allow";
          terminal.always_allow = [
            { pattern = "^grep\\b"; }
            { pattern = "^head\\b"; }
            { pattern = "^tail\\b"; }
            { pattern = "^cat(\\s|$)"; }
            { pattern = "^less\\b"; }
            { pattern = "^more\\b"; }
            { pattern = "^wc\\b"; }
            { pattern = "^file\\b"; }
            { pattern = "^find\\s+\\.(\\s|$)"; }
            { pattern = "^locate\\b"; }
            { pattern = "^rg\\b"; }
            { pattern = "^fd\\b"; }
            { pattern = "^ls(\\s|$)"; }
            { pattern = "^pwd(\\s|$)"; }
            { pattern = "^stat\\b"; }
            { pattern = "^du\\b"; }
            { pattern = "^df\\b"; }
            { pattern = "^tree\\b"; }
            { pattern = "^jq\\b"; }
            { pattern = "^yq\\b"; }
            { pattern = "^cut\\b"; }
            { pattern = "^sort(\\s|$)"; }
            { pattern = "^uniq\\b"; }
            { pattern = "^awk\\b"; }
            { pattern = "^sed\\b"; }
            { pattern = "^cargo\\s+check(\\s|$)"; }
            { pattern = "^cargo\\s+test(\\s|$)"; }
            { pattern = "^cargo\\s+fmt(\\s|$)"; }
            { pattern = "^cargo\\s+clippy(\\s|$)"; }
            { pattern = "^cargo\\s+doc(\\s|$)"; }
            { pattern = "^git\\s+(log|show|diff|status|branch|tag)(\\s|$)"; }
            { pattern = "^git\\s+blame\\b"; }
            { pattern = "^echo(\\s|$)"; }
            { pattern = "^date(\\s|$)"; }
            { pattern = "^uname\\b"; }
            { pattern = "^whoami(\\s|$)"; }
            { pattern = "^which\\b"; }
            { pattern = "^type\\b"; }
            { pattern = "^env(\\s|$)"; }
            { pattern = "^printenv\\b"; }
            { pattern = "^hexdump\\b"; }
            { pattern = "^od\\b"; }
            { pattern = "^strings\\b"; }
          ];
        };
        default_model = {
          provider       = "copilot_chat";
          model          = "claude-haiku-4.5";
          enable_thinking = true;
        };
        favorite_models  = [];
        model_parameters = [];
      };

      language_models.openai_compatible = {
        "llama.cpp" = {
          api_url = "http://127.0.0.1:8080/v1";
          available_models = [
            {
              name = "auto";
              max_tokens = 200000;
              max_output_tokens = 32000;
              max_completion_tokens = 200000;
              capabilities = {
                tools = true; images = true;
                parallel_tool_calls = false; prompt_cache_key = false;
                chat_completions = true; interleaved_reasoning = false;
              };
            }
          ];
        };

      };

      telemetry = {
        diagnostics = true;
        metrics     = false;
      };

      agent_servers = {
        opencode.type        = "registry";
        github-copilot-cli.type = "registry";
      };

      icon_theme      = "Material Icon Theme";
      ui_font_size    = 16;
      buffer_font_size = 15;

      theme = {
        mode  = "dark";
        light = "One Light";
        dark  = "Catppuccin Espresso (Blur) [Light]";
      };

      lsp.discord_presence.initialization_options = {
        state   = "Working on {filename}";
        details = "In {workspace}";
        large_image = "{base_icons_url}/{language:lo}.png";
        large_text  = "{language:u}";
        small_image = "{base_icons_url}/zed.png";
        small_text  = "Zed";
        idle = {
          timeout = 1200;
          action  = "change_activity";
          state   = "Idling";
          details = "In Zed";
          large_image = "{base_icons_url}/zed.png";
          large_text  = "Zed";
          small_image = "{base_icons_url}/idle.png";
          small_text  = "Idle";
        };
        git_integration = true;
      };
    };
  };
}
