# The one place that knows how to start a tenancy.
#
# Both entry points share it: the ff-<tenancy> scripts on PATH (./default.nix)
# and the .app bundles (./apps.nix). Launch logic that exists twice drifts, and
# this logic is subtle enough that drift would be expensive.
#
# The subtlety is that starting a profile has two quite different cases, and
# they want opposite things:
#
#   already running  ->  hand our command line to the instance holding the
#                        profile and let it raise its own window. Firefox's
#                        per-profile remote handoff does this for us, and it is
#                        reachable only by invoking the binary directly.
#
#   cold start       ->  go through `open`, so launchd rather than this script
#                        is Firefox's parent. TCC attributes a permission prompt
#                        to the responsible process, and the microphone and
#                        camera entitlements live on Mozilla's signed bundle, so
#                        the grant has to land on org.mozilla.firefox and not on
#                        an unsigned launcher. Cold start is the only case that
#                        can ever raise such a prompt, because it is the case
#                        that creates the app.
#
# Deciding between them explicitly, rather than letting Firefox work it out, is
# deliberate: a second tenancy launched while another was already running was
# colliding on a profile lock and raising "A copy of Firefox is already open"
# instead of opening a window.
{
  lib,
  pkgs,
  cfg,
}:
with lib; {
  mkLaunchScript = name: tenancy:
    pkgs.writeShellApplication {
      name = "ff-launch-${name}";
      text = ''
        profile_dir=${escapeShellArg "${cfg.profilesPath}/${tenancy.path}"}

        # Match the child processes, not the parent. A Firefox that restarts
        # itself re-execs through XRE_PROFILE_PATH and loses its -P, so the
        # parent's argv can be bare while every child still carries
        # -profile <dir>.
        #
        # Two details in the pattern. [-] is a bracket expression matching a
        # literal dash: it keeps the pattern from starting with one, which pgrep
        # would otherwise read as an option. The ( |$) anchor stops a profile
        # named "play" matching "playground".
        if /usr/bin/pgrep -f "[-]profile $profile_dir( |\$)" >/dev/null 2>&1; then
          exec ${escapeShellArg cfg.firefoxBin} -P ${escapeShellArg name} "$@"
        fi

        if [ -n "''${FF_LAUNCH_NO_OPEN:-}" ]; then
          # granted-firefox sets this. Granted detaches its dispatcher with a
          # fork that has no Mach bootstrap connection and `open` needs one, so
          # the console flow takes the direct path instead. Safe there: a
          # console tab never asks for the microphone or the camera.
          exec ${escapeShellArg cfg.firefoxBin} --new-instance \
            -P ${escapeShellArg name} "$@"
        fi

        # -n is not optional. `open -a` on an app that is already running just
        # activates it and silently discards --args, which would drop both the
        # profile and any URL. --new-instance then tells Gecko not to attempt
        # the handoff the check above has already ruled out.
        exec /usr/bin/open -n -a ${escapeShellArg cfg.firefoxApp} \
          --args --new-instance -P ${escapeShellArg name} "$@"
      '';
    };
}
