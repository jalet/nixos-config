# Declarative Firefox for consulting across concurrent customer tenancies.
#
# Baseline: cloud-gouv/securix modules/tools/firefox.nix, adapted from its
# single-user government-hardening model. The securix original is a NixOS
# module; this is home-manager on nix-darwin, so policies arrive through the
# macOS defaults channel rather than the NixOS programs.firefox option.
#
# Shape:
#   one Firefox profile per tenancy   -> isolates history, bookmarks, client
#                                        certs, extension state, proxy settings
#   containers within each profile    -> isolate cookies and site storage
#   granted-firefox (granted.nix)     -> routes AWS console URLs into the right
#                                        profile, in a per-AWS-profile container
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.local.firefox;

  # pkgs.firefox and pkgs.firefox-bin both go through nixpkgs' wrapFirefox,
  # which on Darwin rebuilds Firefox.app as a symlink tree and replaces
  # Contents/MacOS/firefox with a generated wrapper. That strips the code
  # signature, and macOS TCC will not create Microphone or Camera entries for an
  # unsigned bundle - Firefox never appears in System Settings > Privacy &
  # Security at all, with no error logged anywhere to explain why.
  #
  # firefox-bin-unwrapped is the only attribute that escapes the wrapper: its
  # Darwin branch undmgs Mozilla's official build and sets dontFixup ("don't
  # break code signing"), keeping the Developer ID signature and the real
  # org.mozilla.firefox bundle ID. Do not simplify this back to pkgs.firefox.
  firefoxPkg = pkgs.firefox-bin-unwrapped;

  inherit (import ./launcher.nix {inherit lib pkgs cfg;}) mkLaunchScript;

  containerType = types.submodule {
    options = {
      color = mkOption {
        # Mirrors the enum in home-manager's firefox module, which in turn
        # mirrors toolkit/components/extensions/parent/ext-contextualIdentities.js.
        type = types.enum [
          "blue"
          "turquoise"
          "green"
          "yellow"
          "orange"
          "red"
          "pink"
          "purple"
          "toolbar"
        ];
        default = "toolbar";
        description = "Container colour in the tab strip.";
      };

      icon = mkOption {
        type = types.enum [
          "briefcase"
          "cart"
          "circle"
          "dollar"
          "fence"
          "fingerprint"
          "gift"
          "vacation"
          "food"
          "fruit"
          "pet"
          "tree"
          "chill"
        ];
        default = "circle";
        description = "Container icon.";
      };
    };
  };

  tenancyType = types.submodule ({name, ...}: {
    options = {
      id = mkOption {
        type = types.ints.unsigned;
        description = ''
          profiles.ini section number. Must be unique across tenancies; the
          tenancy with id 0 becomes the default profile unless isDefault says
          otherwise.
        '';
      };

      isDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this is the profile Firefox opens by default.";
      };

      path = mkOption {
        type = types.str;
        default = name;
        example = "asyc414s.default";
        description = ''
          Directory name under Profiles/. Defaults to the tenancy name; set it
          to adopt a profile that already exists on disk. profiles.ini is
          generated, so a profile not named by some tenancy keeps its data but
          becomes invisible to Firefox.
        '';
      };

      awsPrefixes = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["coconut-" "papaya-"];
        description = ''
          AWS profile name prefixes routed to this Firefox profile by
          granted-firefox. Longer prefixes are matched first, so overlapping
          entries such as "pgg-coconut-" and "coconut-" resolve correctly.
        '';
      };

      accent = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "#5E81AC";
        description = ''
          Hex colour used to tint the window chrome and print the tenancy name
          in the tab strip. Firefox exposes the profile name nowhere in a normal
          window - not the title, not the bundle ID - so without this every
          profile looks identical, which matters most when screen-sharing.
        '';
      };

      containers = mkOption {
        type = types.attrsOf containerType;
        default = {};
        description = ''
          Containers to ensure exist in this profile. userContextIds are
          assigned automatically and merged into any containers Granted has
          already created - see containers.nix.
        '';
      };

      bookmarks = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {Console = "https://console.aws.amazon.com";};
        description = "Bookmarks toolbar entries for this profile, as name -> URL.";
      };

      settings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Extra about:config settings, merged over the shared defaults.";
      };
    };
  });

  # Shared by every profile; a tenancy's own `settings` merge on top.
  commonSettings = {
    # Firefox 153 ships its selectable-profiles service enabled, and that
    # service rewrites profiles.ini - the same file home-manager generates.
    # Turn it off so the Nix-generated profiles.ini stays authoritative.
    "browser.profiles.enabled" = false;

    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;

    # Pairs with the Certificates.ImportEnterpriseRoots policy.
    "security.enterprise_roots.enabled" = true;

    # Required for the per-tenancy userChrome.css accent to load at all.
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

    # Restore the previous session; per-tenancy profiles are long-lived.
    "browser.startup.page" = 3;

    # Vertical tabs everywhere. revamp is the sidebar these depend on.
    "sidebar.revamp" = true;
    "sidebar.verticalTabs" = true;

    # Keep the tab strip collapsed to icons instead of the ~239px expanded
    # launcher. "expand-on-hover" is a real pref, unlike the collapsed state
    # under "always-show", which only lives inside the sidebar.backupState JSON
    # blob. Hovering the strip expands it as an overlay, so labels are still
    # one mouse-move away.
    "sidebar.visibility" = "expand-on-hover";

    # Firefox Home. Toggle-to-pref mapping read out of
    # newtab/lib/AboutPreferences.sys.mjs in the shipped omni.ja.
    "browser.newtabpage.activity-stream.showSearch" = true;
    "browser.newtabpage.activity-stream.feeds.topsites" = false; # Shortcuts
    "browser.newtabpage.activity-stream.feeds.section.highlights" = false; # Recent activity
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false; # Recommended stories
    "browser.newtabpage.activity-stream.logowordmark.alwaysVisible" = false; # Firefox logo
    # "Support Firefox" is a pair of nested sponsored prefs, not one toggle.
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    # Weather moved pref when nova.enabled went true by default in 153; set
    # both so the toggle is off regardless of which branch is live.
    "browser.newtabpage.activity-stream.widgets.weather.enabled" = false;
    "browser.newtabpage.activity-stream.showWeather" = false;

    # Address bar suggestions.
    "browser.urlbar.suggest.history" = true;
    "browser.urlbar.suggest.openpage" = true;
    "browser.urlbar.suggest.topsites" = true;
    "browser.urlbar.suggest.bookmark" = false;
    "browser.urlbar.suggest.recentsearches" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.suggest.quickactions" = false;
  };

  # Firefox puts the profile name in no window-visible surface, so tint the
  # chrome and label the tab strip. Requires
  # toolkit.legacyUserProfileCustomizations.stylesheets, set below.
  mkUserChrome = name: tenancy:
    optionalString (tenancy.accent != null) ''
      /* Generated by modules/shared/firefox - identifies the "${name}" profile. */
      :root {
        --tenancy-accent: ${tenancy.accent};
      }

      /* Present in every tab layout, so this is the reliable signal. */
      #navigator-toolbox {
        border-top: 3px solid var(--tenancy-accent) !important;
      }

      #nav-bar {
        border-bottom: 1px solid color-mix(in srgb, var(--tenancy-accent) 55%, transparent) !important;
      }

      /* One anchor for every profile and both tab layouts.
         #TabsToolbar is not usable: vertical tabs collapse it to ~20px, so the
         label renders but is invisible. #nav-bar::after is not usable either -
         it lands past the hamburger at the far right of the window.
         #nav-bar-customization-target exists in both layouts and starts
         immediately after the macOS traffic lights, so ::before is always in
         the same visible spot. Verified in both modes via Marionette. */
      #nav-bar-customization-target::before {
        content: "${toUpper name}";
        color: var(--tenancy-accent);
        font-size: 10px;
        font-weight: 700;
        letter-spacing: 0.08em;
        align-self: center;
        white-space: nowrap;
        padding: 0 10px;
      }

      :root:has(#vertical-tabs #tabbrowser-tabs) #vertical-tabs {
        border-inline-start: 3px solid var(--tenancy-accent) !important;
      }
    '';

  mkBookmarks = bookmarks:
    optionalAttrs (bookmarks != {}) {
      force = true;
      settings = [
        {
          name = "toolbar";
          toolbar = true;
          bookmarks = mapAttrsToList (name: url: {inherit name url;}) bookmarks;
        }
      ];
    };

  # Containers are deliberately NOT passed to home-manager here. Its `containers`
  # option writes containers.json as a read-only store symlink and omits
  # Firefox's four built-in containers, so Granted - which creates a container
  # per AWS profile at runtime - would have its work discarded on every
  # activation. containers.nix merges instead. See that file.
  mkProfile = name: tenancy: {
    inherit name;
    inherit (tenancy) id isDefault path;
    settings = commonSettings // tenancy.settings;
    bookmarks = mkBookmarks (cfg.bookmarks // tenancy.bookmarks);
    userChrome = mkUserChrome name tenancy;
  };

  # A Firefox exec'd from a terminal becomes that tty's foreground job, so
  # closing the window SIGHUPs it and the browser dies with the shell. nohup
  # plus background detaches instead: this script exits immediately, leaving
  # Firefox SIGHUP-immune and reparented to launchd.
  #
  # </dev/null keeps the dead tty off Firefox's stdin; the stdout redirect is
  # also what stops nohup writing a nohup.out into $PWD. The cost is that
  # Firefox's stderr is discarded rather than landing in the terminal.
  #
  # Detaching is all that belongs here. Which of the two ways to start a profile
  # to use - hand off to the instance already holding it, or cold start through
  # `open` - is decided in ./launcher.nix, because the bundles in ./apps.nix
  # need the same decision and must not detach: LaunchServices already has.
  #
  # An earlier version of this comment argued that invoking the binary directly
  # was sufficient on its own, since a second process carrying -P would hand its
  # command line to whichever instance held that profile's lock. That holds when
  # the handoff is reached, but it is not reached reliably: launching a second
  # tenancy while another was running collided on a profile lock and raised
  # "A copy of Firefox is already open". ./launcher.nix decides explicitly now.
  mkLauncher = name: tenancy:
    pkgs.writeShellApplication {
      name = "ff-${name}";
      text = ''
        nohup ${escapeShellArg (getExe' (mkLaunchScript name tenancy) "ff-launch-${name}")} "$@" \
          </dev/null >/dev/null 2>&1 &
      '';
    };
in {
  imports = [
    ./apps.nix
    ./containers.nix
    ./granted.nix
  ];

  options.local.firefox = {
    enable = mkEnableOption "declarative Firefox";

    tenancies = mkOption {
      type = types.attrsOf tenancyType;
      default = {};
      description = "Firefox profiles, one per customer tenancy.";
    };

    defaultTenancy = mkOption {
      type = types.str;
      description = ''
        Tenancy that granted-firefox falls back to when an AWS profile matches
        no awsPrefixes.
      '';
    };

    bookmarks = mkOption {
      type = types.attrsOf types.str;
      default = {};
      example = {GitHub = "https://github.com";};
      description = ''
        Bookmarks present in every profile, merged with each tenancy's own.

        Firefox re-imports these on every start and the import runs with
        replace: true, so the declared set is authoritative - bookmarks added
        by hand do not survive a restart.
      '';
    };

    dohExcludedDomains = mkOption {
      type = types.listOf types.str;
      description = ''
        Domain suffixes that must never be resolved over DNS-over-HTTPS,
        because only a local or VPN resolver knows them. Expect to extend this
        as engagements come and go.
      '';
    };

    firefoxBin = mkOption {
      type = types.str;
      readOnly = true;
      description = "Path to the Firefox binary inside the wrapped app bundle.";
    };

    firefoxApp = mkOption {
      type = types.str;
      readOnly = true;
      description = ''
        Path to Mozilla's Firefox.app bundle. Distinct from firefoxBin because
        `open -a` wants the bundle, not the executable inside it.
      '';
    };

    profilesPath = mkOption {
      type = types.str;
      readOnly = true;
      description = "Absolute path to the directory holding the profile directories.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tenancies ? ${cfg.defaultTenancy};
        message = "local.firefox.defaultTenancy '${cfg.defaultTenancy}' is not a declared tenancy.";
      }
      {
        assertion = length (filter (t: t.isDefault) (attrValues cfg.tenancies)) == 1;
        message = "local.firefox: exactly one tenancy must set isDefault = true.";
      }
    ];

    local.firefox = {
      firefoxApp = "${firefoxPkg}/Applications/Firefox.app";
      firefoxBin = "${firefoxPkg}/Applications/Firefox.app/Contents/MacOS/firefox";
      profilesPath = "${config.home.homeDirectory}/${config.programs.firefox.profilesPath}";
    };

    programs.firefox = {
      enable = true;

      # null stops home-manager applying wrapFirefox to firefoxPkg - it wraps
      # any package that is not already wrapped, which would undo the whole
      # point of firefoxPkg. The app comes from home.packages below instead.
      package = null;

      # Unwrapped means no policies.json inside the bundle: firefox-bin's Darwin
      # installPhase only moves the .app, and the policies.json link is on its
      # Linux branch. So Firefox's macOS provider is the only policy channel
      # left, and nothing remains for it to override. It reads the app's own
      # preferences domain, which for Mozilla's build really is
      # org.mozilla.firefox - pkgs.firefox is built with
      # --with-distribution-id=org.nixos and so ignored this domain entirely,
      # which is why it used to be disabled here.
      #
      # Inspect the result with `defaults read org.mozilla.firefox`, and what
      # Firefox made of it with about:policies.
      darwinDefaultsId = "org.mozilla.firefox";

      policies = import ./policies.nix {inherit lib cfg;};
      profiles = mapAttrs mkProfile cfg.tenancies;
    };

    home.packages = [firefoxPkg] ++ mapAttrsToList mkLauncher cfg.tenancies;
  };
}
