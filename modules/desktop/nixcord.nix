{
  nixcord,
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nixcord;

  common = import (nixcord + "/modules/lib/mkCommonConfig.nix") { inherit config lib pkgs; };

  homeDir = lib.attrsets.attrByPath [ cfg.user "home" ] "/home/${cfg.user}" config.users.users;

  install = lib.getExe' pkgs.coreutils "install";

  id = lib.getExe' pkgs.coreutils "id";
  setpriv = lib.getExe' pkgs.util-linux "setpriv";
  activationScripts = common.mkActivationScripts (
    script:
      ''
        uid="$(${id} -u ${lib.escapeShellArg cfg.user})"
        gid="$(${id} -g ${lib.escapeShellArg cfg.user})"
        ${setpriv} --reuid="$uid" --regid="$gid" --init-groups ${pkgs.runtimeShell} -c ${lib.escapeShellArg script}
      ''
  );
in
{
  imports = [ (nixcord + "/modules/common.nix") ];

  programs.nixcord = lib.recursiveUpdate (common.mkConfigDirs cfg cfg.xdgConfigHome) {
    enable = true;
    user = config.modules.user.name;

    homeDirectory = lib.mkDefault homeDir;
    xdgConfigHome = lib.mkDefault "${homeDir}/.config";
    finalPackage = common.packages.final;



    discord.equicord.enable = true;

    config.plugins = {
      accountPanelServerProfile.enable = true;
      advancedPermissions.enable = true;
      alwaysAnimate.enable = true;
      alwaysExpandRoles.enable = true;
      anonymiseFileNames.enable = true;
      betterFolders.enable = true;
      betterRoleContext.enable = true;
      betterRoleDot.enable = true;
      betterSettings = {
        enable = true;
        disableFade = false;
      };
      betterUploadButton.enable = true;
      biggerStreamPreview.enable = true;
      blurNsfw.enable = true;
      callTimer = {
        enable = true;
        format = "human";
        showSeconds = true;
      };
      clearUrls.enable = true;
      clipUpload.enable = true;
      commandPalette = {
        enable = true;
        hotkey = [
          "Control"
          "Shift"
          "P"
        ];
      };
      consoleJanitor.enable = true;
      consoleShortcuts.enable = true;
      copyEmojiMarkdown.enable = true;
      crashHandler.enable = true;
      customTimestamps = {
        enable = true;
        formats.enable = false;
      };
      dearrow.enable = true;
      decor.enable = true;
      disableCameras.enable = true;
      disableDeepLinks.enable = true;
      dontRoundMyTimestamps.enable = true;
      dragify = {
        enable = true;
        reuseExistingInvites = true;
      };
      equicordHelper.enable = true;
      equicordToolbox.enable = true;
      experiments.enable = true;
      expressionCloner.enable = true;
      f8Break.enable = true;
      fakeNitro.enable = true;
      fakeProfileThemes.enable = true;
      fixCodeblockGap.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds.enable = true;
      followVoiceUser.enable = true;
      forceOwnerCrown.enable = true;
      friendCodes.enable = true;
      friendInvites.enable = true;
      gameActivityToggle.enable = true;
      gitHubRepos.enable = true;
      hideMedia.enable = true;
      iLoveSpam.enable = true;
      imageLink.enable = true;
      imageZoom = {
        enable = true;
        nearestNeighbour = true;
        size = 263.14102564102564;
        square = true;
        zoom = 2.0153885129182645;
        zoomSpeed = 1.6711094875273982;
      };
      memberCount.enable = true;
      messageLatency.enable = true;
      messageLinkEmbeds.enable = true;
      messageLogger.enable = true;
      messageLoggerEnhanced = {
        enable = true;
        imageCacheDir = "${homeDir}/.config/Equicord/MessageLoggerData/savedImages";
        logsDir = "${homeDir}/.config/Equicord/MessageLoggerData";
      };
      messageTranslate = {
        targetLanguage = "pl";
      };
      moreCommands.enable = true;
      moreUserTags = {
        tagSettings = {
          administrator.enable = false;
          chatModerator.enable = false;
          moderator.enable = false;
          moderatorStaff.enable = false;
          owner.enable = false;
          voiceModerator.enable = false;
          webhook.enable = false;
          enable = false;
        };
      };
      musicControls = {
        showSpotifyControls = true;
      };
      mutualGroupDms.enable = true;
      newPluginsManager.enable = true;
      noBlockedMessages.enable = true;
      noDevtoolsWarning.enable = true;
      noF1.enable = true;
      noOnboardingDelay.enable = true;
      noPendingCount.enable = true;
      noReplyMention.enable = true;
      noTrack.enable = true;
      noTypingAnimation.enable = true;
      onePingPerDm.enable = true;
      openInApp.enable = true;
      permissionsViewer.enable = true;
      pinDms = {
        enable = true;
        userBasedCategoryList = {
          "853621876551188490" = [ ];
        };
      };
      platformIndicators.enable = true;
      previewMessage.enable = true;
      questify = {
        enable = true;
        acknowledgedNotices = {
          quest-ban-warning-2026-08-07 = true;
          quest-ban-warning-2026-08-26 = true;
        };
        allowChangingDangerousSettings = true;
        autoCompleteQuestTypes = {
          ACHIEVEMENT_IN_ACTIVITY = true;
          PLAY_ACTIVITY = true;
          PLAY_ON_DESKTOP = true;
          PLAY_ON_PLAYSTATION = true;
          PLAY_ON_XBOX = true;
          WATCH_VIDEO = true;
          WATCH_VIDEO_ON_MOBILE = true;
        };
        completeVideoQuestsQuicker = true;
        ignoredQuestIds = {
          "853621876551188490" = [ ];
          questIDs = [ ];
        };
        makeMobileVideoQuestsDesktopCompatible = true;
        preventVideoQuestsPausing = true;
        questButtonBadgeCount = 3;
        resumeInterruptedQuests = true;
      };
      quickReply.enable = true;
      randomVoice = {
        keybind = [ ];
      };
      reactErrorDecoder.enable = true;
      readAllNotificationsButton.enable = true;
      revealAllSpoilers.enable = true;
      reviewDb = {
        enable = true;
        reviewsDropdownState = true;
      };
      roleColorEverywhere.enable = true;
      searchFix.enable = true;
      sendTimestamps.enable = true;
      serverInfo.enable = true;
      settings = {
        enable = true;
        settingsLocation = "aboveActivity";
      };
      showConnections = {
        enable = true;
        iconSpacing = 0;
      };
      showHiddenChannels.enable = true;
      showHiddenThings.enable = true;
      showMeYourName = {
        enable = true;
        includedNames = "{friend, nick} [{display}] (@{user})";
      };
      silentTyping.enable = true;
      sortFriends.enable = true;
      spotifyCrack.enable = true;
      spotifyShareCommands.enable = true;
      startupTimings.enable = true;
      streamerModeOnStream.enable = true;
      superReactionTweaks.enable = true;
      supportHelper.enable = true;
      translate = {
        enable = true;
        receivedOutput = "pl";
        sentInput = "pl";
      };
      translatePlus = {
        target = "pl";
      };
      typingIndicator.enable = true;
      typingTweaks.enable = true;
      userMessagesPronouns.enable = true;
      userPfp.enable = true;
      usrbg.enable = true;
      validReply.enable = true;
      validUser.enable = true;
      vcNarrator = {
        voice = null;
      };
      viewIcons = {
        enable = true;
        format = "png";
      };
      viewRaw.enable = true;
      voiceDownload.enable = true;
      webKeybinds.enable = true;
      whoReacted.enable = true;
      youtubeAdblock.enable = true;
    };

    extraConfig.plugins = {
      AppleMusicRichPresence = {
        activityType = 0;
        detailsLink = "Album";
        detailsString = "{name}";
        enableButtons = true;
        enableTimestamps = true;
        largeImageLink = "Album";
        largeImageType = "Album";
        largeTextString = "{album}";
        nameString = "Apple Music";
        refreshInterval = 5;
        smallImageLink = "Artist";
        smallImageType = "Artist";
        smallTextString = "{artist}";
        stateLink = "Artist";
        stateString = "{artist} · {album}";
        statusDisplayType = "off";
      };
      BANger = {
        source = "https://i.imgur.com/wp5q52C.mp4";
      };
      betterFolders = {
        nestedFolders = { };
      };
      consoleJanitor = {
        disableNoisyLoggers = false;
      };
      equicordHelper = {
        disableCreateDMButton = false;
        disableDMContextMenu = false;
        noDefaultHangStatus = false;
      };
      experiments = {
        enableIsStaff = true;
      };
      fullVcpfp = {
        useServerProfileAvatars = false;
      };
      gitHubRepos = {
        showInMiniProfile = true;
        showRepositoryTab = true;
      };
      imageZoom = {
        showMetadata = true;
      };
      musicRichPresence = {
        showLastFmLogo = true;
      };
      noBlockedMessages = {
        ignoreBlockedMessages = false;
      };
      noMosaic = {
        mediaLayoutType = "STATIC";
      };
      permissionsViewer = {
        defaultPermissionsDropdownState = false;
      };
      pinDms = {
        dmSectioncollapsed = false;
      };
      questify = {
        completeAchievementQuestsInBackground = false;
        completeGameQuestsInBackground = false;
        completeVideoQuestsInBackground = false;
        disableFriendsListActiveNowPromotion = true;
        disableMembersListActivelyPlayingIcon = true;
        disableQuestsBadgeOnUserProfiles = false;
        disableQuestsDirectMessagesTab = false;
        disableQuestsDiscoveryTab = false;
        disableQuestsFetchingQuests = false;
        disableQuestsGiftInventoryRelocationNotice = true;
        disableQuestsPageSponsoredBanner = false;
        disableQuestsPopupAboveAccountPanel = true;
        fetchingQuestsAlert = "discodo";
        fetchingQuestsAlertVolume = 100;
        fetchingQuestsInterval = 2700;
        ignoredQuestProfile = "private";
        makeMobileQuestsDesktopCompatible = true;
        questButtonUnclaimed = "both";
        questRewardIncludeCollectibles = true;
        questRewardIncludeInGame = true;
        questRewardIncludeNitroCode = true;
        questRewardIncludeOrbs = true;
        questRewardIncludeRewardCode = true;
        reorderQuests = "UNCLAIMED, CLAIMED, IGNORED, EXPIRED";
        restyleQuestsClaimed = 6105983;
        restyleQuestsExpired = 2368553;
        restyleQuestsGradient = "intense";
        restyleQuestsIgnored = 8334124;
        restyleQuestsPreload = true;
        restyleQuestsUnclaimed = 2842239;
      };
      RPCStats = {
        RPCTitle = "RPCStats";
        assetURL = "";
        lastFMApiKey = "";
        statDisplay = 0;
      };
      showHiddenThings = {
        disableDisallowedDiscoveryFilters = true;
        disableDiscoveryFilters = true;
      };
      Summaries = {
        summaryExpiryThresholdDays = 7.050176056338028;
      };
      translate = {
        showChatBarButton = true;
      };
      userMessagesPronouns = {
        pronounSource = 0;
        showInMessages = true;
        showInProfile = true;
      };
    };
  };

  environment.systemPackages = common.packages.installed;

  system.activation.scripts = {
    nixcord-disableDiscordUpdates = {
      deps = [ "users" ];
      text = activationScripts.disableDiscordUpdates;
    };

    nixcord-fixDiscordModules = {
      deps = [ "users" ];
      text = activationScripts.fixDiscordModules;
    };

    nixcord-writeFiles = {
      deps = [ "users" ];
      text = ''
        (
          set -eu
          target_user=${lib.escapeShellArg cfg.user}
          target_group="$(${pkgs.coreutils}/bin/id -gn "$target_user")"

          copy_file() {
            local src="$1"
            local dest="$2"
            local mode="$3"
            ${install} -D -m "$mode" -o "$target_user" -g "$target_group" "$src" "$dest"
          }

          ${common.fileCopyCommands}
        )
      '';
    };
  };
}
