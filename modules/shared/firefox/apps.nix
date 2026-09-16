# One macOS launcher bundle per tenancy, so a profile can be started from
# Spotlight, Finder or the Dock rather than only from a shell.
#
# What these are NOT, and cannot be made into: a separate app identity per
# tenancy. macOS takes an application's identity from the bundle containing the
# running executable, never from whoever launched it - `lsappinfo` reports a
# Firefox started by the bare ff-<name> script as bundleID org.mozilla.firefox
# living in Mozilla's bundle, despite that script having no bundle at all. So
# however these are launched, Cmd-Tab shows one Firefox, the Dock shows one
# running tile, and AeroSpace's app-id rules cannot tell the tenancies apart.
# Do not try to fix that by pinning a bundle to the Dock and expecting a running
# indicator; it will never appear.
#
# Giving the tenancies real identities would mean putting Firefox's own binary
# inside a bundle declaring a different CFBundleIdentifier. That breaks
# Mozilla's seal and forfeits the entitlements it carries:
#
#   com.apple.security.device.audio-input / .camera
#       microphone and camera - the exact constraint firefoxPkg exists to
#       protect, see the comment above it in ./default.nix
#   com.apple.developer.web-browser.public-key-credential
#       passkeys and WebAuthn
#   com.apple.security.smartcard
#       client certificates, which is half the point of per-tenancy profiles
#
# Ad-hoc re-signing restores none of these; they need Mozilla's provisioning.
# That is not a trade worth making for a Cmd-Tab entry. In-window identification
# is already handled by the per-tenancy accent in mkUserChrome.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.local.firefox;

  inherit (import ./launcher.nix {inherit lib pkgs cfg;}) mkLaunchScript;

  plistFormat = pkgs.formats.plist {};

  appNameOf = name: "Firefox ${toSentenceCase name}";

  # Deliberately not org.mozilla.firefox: two bundles claiming one identifier
  # confuse LaunchServices, and it would be a lie - nothing of Mozilla's runs
  # from this bundle.
  bundleIdOf = name: "io.playgroundtech.firefox.${name}";

  # Stripe Mozilla's own icon in the tenancy accent rather than draw a new one,
  # so the tile still reads as Firefox at Dock size and the accent is the only
  # thing distinguishing them - the same trick mkUserChrome plays on the window.
  mkTenancyIcon = name: tenancy:
    if tenancy.accent == null
    then "${cfg.firefoxApp}/Contents/Resources/firefox.icns"
    else
      pkgs.runCommand "firefox-${name}.icns" {
        nativeBuildInputs = [pkgs.libicns pkgs.imagemagick];
      } ''
        icns2png -x -o . ${cfg.firefoxApp}/Contents/Resources/firefox.icns

        # icns2png names its output <base>_<w>x<h>x<depth>.png and png2icns only
        # accepts 16/32/48/128/256/512, so glob the depth rather than guess it.
        layers=""
        for size in 16 32 128 256 512; do
          src=$(echo ./*_"''${size}x''${size}"x*.png | cut -d' ' -f1)
          [ -f "$src" ] || continue

          bar=$((size / 6))
          magick "$src" -fill ${escapeShellArg tenancy.accent} \
            -draw "rectangle 0,$((size - bar)) $size,$size" "layer-$size.png"
          layers="$layers layer-$size.png"
        done

        if [ -z "$layers" ]; then
          echo "no layers extracted from firefox.icns - check icns2png -l" >&2
          exit 1
        fi

        # shellcheck disable=SC2086
        png2icns "$out" $layers
      '';

  mkTenancyApp = name: tenancy: let
    appName = appNameOf name;

    # Must match the file actually installed into Contents/MacOS below.
    exeName = "ff-launch-${name}";

    infoPlist = plistFormat.generate "Info-${name}.plist" {
      CFBundleIdentifier = bundleIdOf name;
      CFBundleName = appName;
      CFBundleDisplayName = appName;
      CFBundleExecutable = exeName;
      CFBundlePackageType = "APPL";
      CFBundleSignature = "????";
      CFBundleInfoDictionaryVersion = "6.0";

      # Extension-less by convention: LaunchServices appends .icns.
      CFBundleIconFile = "firefox";

      # This bundle's own version, not Firefox's. Tying it to firefoxPkg would
      # mean duplicating that choice here and letting the two drift.
      CFBundleShortVersionString = "1.0";
      CFBundleVersion = "1";

      # Matches Mozilla's own Info.plist.
      LSMinimumSystemVersion = "10.15.0";
      NSHighResolutionCapable = true;

      # The launcher execs Firefox and exits. Without this it would claim a Dock
      # tile of its own and bounce it for a second next to the real Firefox tile
      # that actually owns the window.
      LSUIElement = true;
    };
  in
    pkgs.runCommand "firefox-app-${name}" {
      meta = {
        description = "macOS launcher bundle for the ${name} Firefox profile";
        platforms = pkgs.lib.platforms.darwin;
      };
    } ''
      app="$out/Applications/${appName}.app"
      mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"

      cp ${infoPlist} "$app/Contents/Info.plist"
      cp ${mkTenancyIcon name tenancy} "$app/Contents/Resources/firefox.icns"
      printf 'APPL????' > "$app/Contents/PkgInfo"

      # Left unsigned on purpose. Gatekeeper does not block a locally built
      # bundle the user launches themselves, and a signature here would buy
      # nothing: the process that matters is Mozilla's, started via `open`.
      install -m555 ${mkLaunchScript name tenancy}/bin/${exeName} \
        "$app/Contents/MacOS/${exeName}"
    '';
in {
  config = mkIf cfg.enable {
    # targets.darwin.linkApps builds a buildEnv over home.packages with
    # pathsToLink = ["/Applications"], so exposing $out/Applications/<x>.app is
    # all that is needed to land in ~/Applications/Home Manager Apps.
    home.packages = mapAttrsToList mkTenancyApp cfg.tenancies;
  };
}
