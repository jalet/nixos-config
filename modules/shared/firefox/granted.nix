# Route Granted's AWS console sessions into the right Firefox profile.
#
# Granted will either rewrite a console URL into the Firefox container scheme or
# consult a launch template - never both. The rewrite in pkg/assume/assume.go is
# gated on DefaultBrowser being one of the Firefox keys, while the launch
# template is only used when DefaultBrowser == "CUSTOM". Selecting a profile
# requires the template, so granted-firefox rebuilds the container URL itself.
#
# ~/.granted/config stays mutable: it carries the git profile registries and
# frecency data, and `granted registry add` has to keep working. Only the
# browser keys are managed here.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.local.firefox;

  # Longest prefix wins, so overlapping entries such as "pgg-coconut-" and
  # "coconut-" resolve to the tenancy that actually owns the account.
  routes = sort (a: b: stringLength a.prefix > stringLength b.prefix) (
    concatLists (
      mapAttrsToList
      (name: tenancy: map (prefix: {inherit name prefix;}) tenancy.awsPrefixes)
      cfg.tenancies
    )
  );

  inherit (import ./launcher.nix {inherit lib pkgs cfg;}) mkLaunchScript;

  launcherOf = name:
    escapeShellArg (getExe' (mkLaunchScript name cfg.tenancies.${name}) "ff-launch-${name}");

  caseArms =
    concatMapStringsSep "\n"
    (route: "    ${escapeShellArg route.prefix}*) launcher=${launcherOf route.name} ;;")
    routes;

  dispatcher = pkgs.writeShellApplication {
    name = "granted-firefox";
    runtimeInputs = [pkgs.jq pkgs.gawk];
    text = ''
      # Usage: granted-firefox [aws-profile] <url>
      #
      # Granted calls this through two templates and they pass different arity.
      # AWSConsoleBrowserLaunchTemplate renders {{.Profile}} to the AWS profile
      # name, so two arguments arrive. SSOBrowserLaunchTemplate renders it
      # empty - configOpts.SSOBrowserProfile is unset unless
      # --sso-browser-profile is given - and Granted's splitCommand drops the
      # empty token, so a single argument arrives. Granted detaches the process,
      # so anything this script writes to stderr is lost: it must not assume
      # two arguments or the SSO flow fails silently with no browser.

      case $# in
        2) aws_profile=$1; url=$2 ;;
        1) aws_profile=""; url=$1 ;;
        *) echo "usage: granted-firefox [aws-profile] <url>" >&2; exit 64 ;;
      esac

      wrap_in_container=1
      if [ -z "$aws_profile" ]; then
        # SSO sign-in page, not a console session, so no container. Recover a
        # profile name by matching the URL host against sso_start_url in the AWS
        # config, so the SSO cookie lands in the Firefox profile that the
        # console will later open in rather than always in the fallback.
        wrap_in_container=""
        host=''${url#*://}
        host=''${host%%/*}
        # Two config styles coexist here and both must resolve. Profiles from
        # the Granted registries inline granted_sso_start_url, while
        # hand-written ones point at a [sso-session] block via sso_session, so
        # the start URL has to be followed through that indirection.
        aws_profile=$(awk -v host="$host" '
          function val(s) {
            sub(/^[^=]*=[[:space:]]*/, "", s); gsub(/[[:space:]]+$/, "", s); return s
          }
          /^[[:space:]]*\[/ {
            sectype = ""
            if (match($0, /^[[:space:]]*\[sso-session[[:space:]]+/)) { sectype = "s" }
            else if (match($0, /^[[:space:]]*\[profile[[:space:]]+/)) { sectype = "p" }
            if (sectype != "") {
              section = substr($0, RLENGTH + 1); sub(/\].*$/, "", section)
              if (sectype == "p" && !(section in seen)) { seen[section] = 1; order[++n] = section }
            }
            next
          }
          sectype == "s" && /sso_start_url/ { sess[section] = val($0); next }
          sectype == "p" && /sso_start_url/ { purl[section] = val($0); next }
          sectype == "p" && /^[[:space:]]*sso_session[[:space:]]*=/ { pses[section] = val($0); next }
          END {
            for (i = 1; i <= n; i++) {
              p = order[i]
              u = (p in purl) ? purl[p] : ((p in pses) ? sess[pses[p]] : "")
              if (u != "" && index(u, host)) { print p; exit }
            }
          }
        ' "''${AWS_CONFIG_FILE:-$HOME/.aws/config}") || aws_profile=""
      fi

      case "$aws_profile" in
      ${caseArms}
          *) launcher=${launcherOf cfg.defaultTenancy} ;;
      esac

      if [ -n "$wrap_in_container" ]; then
        # jq's @uri covers the same character set as Go's url.QueryEscape, which
        # is what Granted uses. They differ on spaces (%20 against +), and
        # console federation URLs contain none.
        encoded=$(jq -rn --arg u "$url" '$u|@uri')

        # color and icon are sent empty, matching Granted when a profile sets no
        # granted_color / granted_icon. Populate them from ~/.aws/config here if
        # those properties ever get used.
        url="ext+granted-containers:name=$aws_profile&url=$encoded&color=&icon="
      fi

      # Detached for the same reason as the ff-<name> launchers in ./default.nix:
      # Granted's own fork covers the console flow, but a hand-run
      # granted-firefox would otherwise die with the terminal that started it.
      #
      # FF_LAUNCH_NO_OPEN keeps ./launcher.nix off `open` on the cold-start
      # path, for the same reason UseForkProcess has to stay True below: the
      # fork Granted detaches us with has no Mach bootstrap connection and
      # `open` requires one. Nothing is lost here - that flag only exists to put
      # TCC's responsible process on Mozilla's signed bundle for microphone and
      # camera prompts, and an AWS console tab raises neither.
      FF_LAUNCH_NO_OPEN=1 nohup "$launcher" --new-tab "$url" \
        </dev/null >/dev/null 2>&1 &
    '';
  };

  # Granted rewrites this file itself (granted browser set, registry add,
  # frecency) using toml.Marshal, so it does not preserve formatting or comments
  # either. Parsing and re-emitting is therefore no more destructive than
  # Granted's own writes, and tomli_w orders bare keys ahead of tables, which
  # keeps the result valid TOML.
  configureScript = pkgs.writeText "granted-configure-browser.py" ''
    import os
    import sys
    import tempfile
    import tomllib

    import tomli_w

    path = os.path.expanduser("~/.granted/config")
    command, browser = sys.argv[1], sys.argv[2]

    data = {}
    if os.path.exists(path):
        with open(path, "rb") as handle:
            data = tomllib.load(handle)

    before = tomli_w.dumps(data)

    # DefaultBrowser must be CUSTOM for AWSConsoleBrowserLaunchTemplate to be
    # consulted at all. The two paths stay set because assume.go requires either
    # a browser path or a template to be present before it will launch anything.
    data["DefaultBrowser"] = "CUSTOM"
    data["CustomBrowserPath"] = browser
    data["CustomSSOBrowserPath"] = browser

    for table in ("AWSConsoleBrowserLaunchTemplate", "SSOBrowserLaunchTemplate"):
        template = data.setdefault(table, {})
        template["Command"] = command
        # True is correct because the dispatcher invokes the Firefox binary
        # directly. It must be False only when the command is macOS `open`,
        # which needs a Mach bootstrap connection that Granted's detached fork
        # does not have. The dispatcher backgrounding Firefox rather than
        # exec'ing it does not change that.
        template["UseForkProcess"] = True

    after = tomli_w.dumps(data)
    if after == before:
        sys.exit(0)

    directory = os.path.dirname(path)
    os.makedirs(directory, exist_ok=True)
    handle_fd, tmp = tempfile.mkstemp(dir=directory)
    try:
        with os.fdopen(handle_fd, "wb") as handle:
            handle.write(after.encode())
        os.replace(tmp, path)
    except BaseException:
        if os.path.exists(tmp):
            os.unlink(tmp)
        raise

    print("granted: pointed console and SSO launches at Firefox")
  '';

  python = pkgs.python3.withPackages (ps: [ps.tomli-w]);
in {
  config = mkIf cfg.enable {
    home.packages = [dispatcher];

    home.activation.grantedBrowser = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${python}/bin/python3 ${configureScript} \
        ${escapeShellArg "${dispatcher}/bin/granted-firefox {{.Profile}} {{.URL}}"} \
        ${escapeShellArg cfg.firefoxBin}
    '';
  };
}
