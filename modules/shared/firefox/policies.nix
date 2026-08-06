# Firefox enterprise policies, adapted from cloud-gouv/securix
# modules/tools/firefox.nix.
#
# These are global to the Firefox binary, so every profile shares them. nixpkgs'
# wrapFirefox writes them to Firefox.app/Contents/Resources/distribution/policies.json
# (see nixpkgs pkgs/applications/networking/browsers/firefox/wrapper.nix).
#
# Every key here was validated against modules/policies/policies-schema.json in
# the shipped omni.ja. Unknown keys are silently dropped by Firefox, so check
# about:policies after changing anything.
{
  lib,
  cfg,
}:
with lib; let
  # Extensions are pinned by AMO short id (which builds the download URL) and by
  # add-on GUID (the key Firefox matches policy against). The GUIDs were read
  # from the AMO API, not copied from documentation - several published lists
  # have them wrong.
  extension = shortId: uuid:
    nameValuePair uuid {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/${shortId}/latest.xpi";
      installation_mode = "force_installed";
    };
in {
  # -- Extensions -------------------------------------------------------------
  # Strict allowlist: anything not named below cannot be installed at all.
  # Adding an extension is a deliberate edit here plus a rebuild, which is the
  # point of running this declaratively.
  ExtensionSettings =
    {
      "*".installation_mode = "blocked";
    }
    // listToAttrs [
      (extension "ublock-origin" "uBlock0@raymondhill.net")

      # Granted registers the ext+granted-containers: protocol handler that
      # granted-firefox hands AWS console URLs to. Without this, console
      # launches fail silently.
      (extension "granted" "{b5e0e8de-ebfe-4306-9528-bcc18241a490}")

      # Provides the "always open this site in container X" UI, which is what
      # makes the declared containers usable day to day.
      (extension "multi-account-containers" "@testpilot-containers")

      (extension "proton-pass" "78272b6fa58f4a1abaac99321d503a20@proton.me")
      (extension "bitwarden-password-manager" "{446900e4-71c2-419f-a6a7-df9c091e268b}")

      # 1Password works standalone (vault, autofill, passkeys) but cannot reach
      # the desktop app: that handshake needs an Apple Team ID, and the Nix
      # bundle is unsigned. Unlock is account password + Secret Key.
      (extension "1password-x-password-manager" "{d634138d-c276-4fc8-924b-40a0ea21d284}")
    ];

  # -- Search -----------------------------------------------------------------
  # Names, not ids - the policy resolves via SearchService.getEngineByName.
  # Applied through runOncePerModification, so re-enabling one by hand sticks
  # until this list itself changes. That makes it a default, which is the
  # intent. Not ESR-gated: IS_ESR appears nowhere in Policies.sys.mjs on 153.
  SearchEngines.Remove = [
    "Bing"
    "Ecosia"
    "Perplexity"
  ];

  # -- Passwords --------------------------------------------------------------
  # Keep Firefox's own manager out of the way of the three above.
  PasswordManagerEnabled = false;
  OfferToSaveLogins = false;

  # -- Networking -------------------------------------------------------------
  # DoH stays on for untrusted networks, but must never swallow names that only
  # a local or VPN resolver knows about. Firefox matches ExcludedDomains as
  # suffixes at label boundaries (TRRService::IsExcludedFromTRR), so bare
  # "internal" covers anything.internal.
  DNSOverHTTPS = {
    Enabled = true;
    Fallback = true;
    ExcludedDomains = cfg.dohExcludedDomains;
    Locked = false;
  };

  # -- Certificates -----------------------------------------------------------
  # Trust customer root CAs already installed in the macOS Keychain. Without
  # this, every internal-PKI host on a customer VPN throws a cert error.
  Certificates.ImportEnterpriseRoots = true;

  # -- Media ------------------------------------------------------------------
  # securix disables EME to keep Netflix off a government laptop. Inverted here:
  # customer training portals and recorded workshops need Widevine.
  EncryptedMediaExtensions.Enabled = true;

  # -- Updates and profile state ---------------------------------------------
  # flake.lock owns the Firefox version and profiles.ini is generated, so
  # nothing may mutate either behind Nix's back.
  AppAutoUpdate = false;
  DisableAppUpdate = true;
  DisableProfileImport = true;
  DisableProfileRefresh = true;
  NoDefaultBookmarks = true;

  # -- Noise ------------------------------------------------------------------
  DisableTelemetry = true;
  DisableFirefoxStudies = true;
  DisablePocket = true;
  DisableFirefoxAccounts = true;
  DontCheckDefaultBrowser = true;

  # "never" | "always" | "newtab". Firefox treats this as a default rather than
  # a lock, and re-applies only when the value itself changes
  # (runOncePerModification), so toggling it by hand afterwards sticks.
  DisplayBookmarksToolbar = "never";

  UserMessaging = {
    ExtensionRecommendations = false;
    FeatureRecommendations = false;
    UrlbarInterventions = false;
    MoreFromMozilla = false;
    WhatsNew = false;
    SkipOnboarding = true;
    # Left unlocked so the messaging prefs stay adjustable in the UI.
    Locked = false;
  };
}
