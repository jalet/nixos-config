# Send every link the system opens to the Firefox window that was focused last.
#
# macOS records the default browser as a bundle ID, and this machine's was
# still org.nixos.firefox - the wrapped nixpkgs build that ./default.nix
# abandoned in favour of firefox-bin-unwrapped (org.mozilla.firefox). So
# LaunchServices answered every http(s) open by starting a Firefox that was not
# one of the running ones, and Firefox, which only hands a URL to an existing
# window when the two builds are identical, put up "A copy of Firefox is
# already open. Only one copy of Firefox can be open at a time." instead. The
# AWS VPN Client's SAML renewal is the flow where that hurt most.
#
# Pointing the handler at the current bundle would not have been enough: a
# rebuild routinely leaves an older Firefox still running on an old store path,
# and a link routed to the *current* binary collides with it in exactly the
# same way. So the router re-invokes whichever binary the target window is
# already running, and the mismatch stops mattering.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.local.firefox;

  # Quartz for the window list, Cocoa for NSApplication and the Apple Event
  # manager. Both are needed in one interpreter because the handler resolves
  # and dispatches in-process.
  python = pkgs.python3.withPackages (ps: [
    ps.pyobjc-framework-Quartz
    ps.pyobjc-framework-Cocoa
  ]);

  # Where the activation script below installs the bundle. Stable by design;
  # see the activation block for why it is not a store symlink.
  routerApp = "${config.home.homeDirectory}/Applications/Firefox Router.app";

  routeScript = pkgs.writeText "ff-route.py" ''
    """Route a URL into the Firefox window that was focused most recently.

    ff-route <url>            resolve and open
    ff-route --dry-run <url>  print the decision, launch nothing
    ff-route --set-default    ask macOS to make the router the default browser
    ff-route --handler        Apple Event handler; the app bundle's entry point
    """

    import os
    import shlex
    import subprocess
    import sys
    from urllib.parse import urlsplit

    # Every Firefox build lays its bundle out this way, so the suffix both
    # identifies a Firefox and excludes its children: a plugin-container's
    # argv[0] points inside plugin-container.app, and only parents own windows.
    FIREFOX_SUFFIX = "/Firefox.app/Contents/MacOS/firefox"

    FALLBACK_BIN = "${cfg.firefoxBin}"
    FALLBACK_PROFILE = "${cfg.defaultTenancy}"
    ROUTER_APP = "${routerApp}"


    def firefox_processes():
        """pid -> (executable, profile) for every running Firefox parent."""
        completed = subprocess.run(
            ["/bin/ps", "-axo", "pid=,args="],
            capture_output=True,
            text=True,
            check=False,
        )
        processes = {}
        for line in completed.stdout.splitlines():
            line = line.strip()
            if not line:
                continue
            pid_text, _, arguments = line.partition(" ")
            try:
                pid = int(pid_text)
            except ValueError:
                continue
            try:
                argv = shlex.split(arguments)
            except ValueError:
                argv = arguments.split()
            if not argv or not argv[0].endswith(FIREFOX_SUFFIX):
                continue
            profile = None
            for index, argument in enumerate(argv):
                if argument in ("-P", "--P") and index + 1 < len(argv):
                    profile = argv[index + 1]
                    break
            processes[pid] = (argv[0], profile)
        return processes


    def focused_firefox(processes):
        """The Firefox parent owning the frontmost ordinary window, or None.

        CGWindowListCopyWindowInfo returns the on-screen list front to back, so
        the first layer-0 window belonging to a Firefox is the one most
        recently raised. Only the owner pid and the layer are read, and neither
        needs the Screen Recording permission that window *titles* would.

        kCGWindowListOptionAll is deliberately not used as a second chance:
        measured here it comes back in window-id order rather than z-order, so
        it cannot answer "most recently focused" and would only ever hand back
        an arbitrary Firefox. resolve() falls back on the process list instead,
        which is at least predictable.
        """
        import Quartz

        windows = (
            Quartz.CGWindowListCopyWindowInfo(
                Quartz.kCGWindowListOptionOnScreenOnly
                | Quartz.kCGWindowListExcludeDesktopElements,
                Quartz.kCGNullWindowID,
            )
            or []
        )
        for window in windows:
            # Layer 0 is the ordinary window layer; anything else is a panel,
            # a menu or the status bar.
            if window.get("kCGWindowLayer") != 0:
                continue
            pid = window.get("kCGWindowOwnerPID")
            if pid in processes:
                return pid
        return None


    def resolve():
        """(executable, profile, reason) for the Firefox that should get it."""
        processes = firefox_processes()

        pid = focused_firefox(processes) if processes else None
        if pid is not None:
            executable, profile = processes[pid]
            return executable, profile, "focused window, pid %d" % pid

        # No Firefox window on screen. AeroSpace parks the windows of inactive
        # workspaces outside the display bounds, so this is a normal state, not
        # an error.
        for pid, (executable, profile) in sorted(processes.items()):
            if profile == FALLBACK_PROFILE:
                return executable, profile, "no window on screen, running %s, pid %d" % (
                    FALLBACK_PROFILE,
                    pid,
                )
        if processes:
            pid = sorted(processes)[0]
            executable, profile = processes[pid]
            return executable, profile, "no window on screen, lowest running pid %d" % pid

        return FALLBACK_BIN, FALLBACK_PROFILE, "no Firefox running, cold start"


    def accepted(url):
        """Whether this is a URL worth handing to Firefox.

        It arrives from whatever app asked the system to open it, so it is
        untrusted input: it is passed as one argv element and never through a
        shell, and anything that is not http(s) is dropped rather than
        forwarded.
        """
        try:
            return urlsplit(url).scheme.lower() in ("http", "https")
        except ValueError:
            return False


    def dispatch(executable, profile, url):
        argv = [executable]
        if profile:
            argv += ["-P", profile]
        argv += ["--new-tab", url]
        # start_new_session for the same reason the ff-<name> launchers in
        # ./default.nix use nohup: nothing that started the router should be
        # able to take Firefox down with it.
        with open(os.devnull, "r+b") as devnull:
            subprocess.Popen(
                argv,
                stdin=devnull,
                stdout=devnull,
                stderr=devnull,
                start_new_session=True,
            )


    def route(url):
        if not accepted(url):
            return
        executable, profile, _ = resolve()
        dispatch(executable, profile, url)


    def set_default():
        """Hand http, https and the web-browser role to the router bundle.

        setDefaultApplicationAtURL is asynchronous, and macOS may raise a
        confirmation sheet before it takes effect, so the process has to stay
        on a run loop until both completion handlers fire. Returning straight
        away - which is what an obvious implementation does - cancels the
        request and silently changes nothing.
        """
        import AppKit
        import Foundation
        from Foundation import NSURL

        schemes = ("http", "https")
        workspace = AppKit.NSWorkspace.sharedWorkspace()
        bundle = NSURL.fileURLWithPath_(ROUTER_APP)
        outstanding = {"count": len(schemes)}

        app = AppKit.NSApplication.sharedApplication()
        app.setActivationPolicy_(AppKit.NSApplicationActivationPolicyAccessory)

        def completed(error):
            # NSApp.terminate_ exits the process, so anything worth saying has
            # to be said here rather than after app.run() returns.
            if error is not None:
                print("ff-route: %s" % error, file=sys.stderr)
            outstanding["count"] -= 1
            if outstanding["count"] == 0:
                print("http and https now open through:")
                print("  " + ROUTER_APP)
                AppKit.NSApp().terminate_(None)

        for scheme in schemes:
            workspace.setDefaultApplicationAtURL_toOpenURLsWithScheme_completionHandler_(
                bundle, scheme, completed
            )

        def timed_out(timer):
            print(
                "ff-route: macOS did not answer. Set it by hand in "
                "System Settings > Desktop & Dock > Default web browser.",
                file=sys.stderr,
            )
            AppKit.NSApp().terminate_(None)

        Foundation.NSTimer.scheduledTimerWithTimeInterval_repeats_block_(
            30.0, False, timed_out
        )
        app.run()


    def run_handler():
        """Serve one GURL Apple Event, then exit.

        LaunchServices delivers a URL as a kInternetEventClass/kAEGetURL Apple
        Event rather than as argv, which is why the bundle cannot simply wrap a
        shell script.
        """
        import AppKit
        import Foundation
        import objc

        INTERNET_EVENT_CLASS = 0x4755524C  # 'GURL'
        GET_URL_EVENT_ID = 0x4755524C  # 'GURL'
        DIRECT_OBJECT = 0x2D2D2D2D  # '----'

        class RouterDelegate(Foundation.NSObject):
            def applicationWillFinishLaunching_(self, notification):
                # Registered here rather than in didFinishLaunching:
                # LaunchServices has already queued the event by the time the
                # process starts, and delivers it as soon as the run loop
                # turns. A handler installed any later misses the very event
                # the app was launched to serve.
                manager = Foundation.NSAppleEventManager.sharedAppleEventManager()
                manager.setEventHandler_andSelector_forEventClass_andEventID_(
                    self,
                    b"handleGetURL:withReply:",
                    INTERNET_EVENT_CLASS,
                    GET_URL_EVENT_ID,
                )

            def handleGetURL_withReply_(self, event, reply):
                descriptor = event.paramDescriptorForKeyword_(DIRECT_OBJECT)
                if descriptor is not None:
                    route(descriptor.stringValue())
                AppKit.NSApp().terminate_(None)

        app = AppKit.NSApplication.sharedApplication()
        # Accessory: routing a link must never steal focus or claim a Dock tile.
        app.setActivationPolicy_(AppKit.NSApplicationActivationPolicyAccessory)
        delegate = RouterDelegate.alloc().init()
        app.setDelegate_(delegate)
        # setDelegate_ does not retain, and the only other reference is local.
        objc.setAssociatedObject(
            app, b"ff-route-delegate", delegate, objc.OBJC_ASSOCIATION_RETAIN
        )
        # Never linger: with no event to serve the run loop would sit forever.
        Foundation.NSTimer.scheduledTimerWithTimeInterval_repeats_block_(
            10.0, False, lambda timer: AppKit.NSApp().terminate_(None)
        )
        app.run()


    def main(argv):
        if argv[:1] == ["--handler"]:
            run_handler()
            return 0

        if argv[:1] == ["--set-default"]:
            set_default()
            return 0

        dry_run = argv[:1] == ["--dry-run"]
        if dry_run:
            argv = argv[1:]

        if len(argv) != 1:
            print(
                "usage: ff-route [--dry-run] <url> | --set-default | --handler",
                file=sys.stderr,
            )
            return 64

        url = argv[0]
        executable, profile, reason = resolve()

        if dry_run:
            print("url      %s" % url)
            print("accepted %s" % accepted(url))
            print("reason   %s" % reason)
            print("profile  %s" % (profile or "(profiles.ini default)"))
            print("exe      %s" % executable)
            return 0

        if not accepted(url):
            print("ff-route: refusing non-web URL: %s" % url, file=sys.stderr)
            return 65

        dispatch(executable, profile, url)
        return 0


    if __name__ == "__main__":
        sys.exit(main(sys.argv[1:]))
  '';

  route = pkgs.writeShellApplication {
    name = "ff-route";
    text = ''
      exec ${python}/bin/python3 ${routeScript} "$@"
    '';
  };

  # Declaring http and https is what makes an app eligible for the System
  # Settings default-browser list. LSUIElement keeps it out of the Dock and the
  # app switcher, since it exists only to forward an event and quit.
  infoPlist = pkgs.writeText "firefox-router-Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key><string>io.playgroundtech.ff-router</string>
      <key>CFBundleName</key><string>Firefox Router</string>
      <key>CFBundleDisplayName</key><string>Firefox Router</string>
      <key>CFBundleExecutable</key><string>ff-router</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
      <key>CFBundleShortVersionString</key><string>1.0</string>
      <key>CFBundleVersion</key><string>1</string>
      <key>LSUIElement</key><true/>
      <key>CFBundleURLTypes</key>
      <array>
        <dict>
          <key>CFBundleURLName</key><string>Web site URL</string>
          <key>CFBundleTypeRole</key><string>Viewer</string>
          <key>CFBundleURLSchemes</key>
          <array>
            <string>http</string>
            <string>https</string>
          </array>
        </dict>
      </array>
    </dict>
    </plist>
  '';

  # The bundle's executable is a Python script whose shebang points at the
  # interpreter in the store, so NSBundle.mainBundle() resolves to the store
  # rather than to this bundle. That is harmless here: LaunchServices delivers
  # the event to the process it launched, and nothing in the handler reads the
  # bundle. Verified end to end before this module was written.
  routerAppPkg = pkgs.runCommand "firefox-router-app" {} ''
    app="$out/Applications/Firefox Router.app"
    mkdir -p "$app/Contents/MacOS"
    cp ${infoPlist} "$app/Contents/Info.plist"

    cat > "$app/Contents/MacOS/ff-router" <<EOF
    #!${python}/bin/python3
    import runpy
    import sys

    sys.argv = ["ff-router", "--handler"]
    runpy.run_path("${routeScript}", run_name="__main__")
    EOF

    chmod +x "$app/Contents/MacOS/ff-router"
  '';

  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";
in {
  config = mkIf cfg.enable {
    home.packages = [route];

    # Copied to a fixed path rather than linked from the store, and re-registered
    # on every activation. LaunchServices resolves a symlink to its target, so a
    # store-linked bundle would register a new path on every rebuild and leave
    # the old ones behind - which is precisely the mess this module exists to
    # clean up (six Firefox records, the default browser pointing at a build
    # that had not been installed for two versions). One stable path keeps one
    # record, and the bundle is a plist plus a script, so copying it is free.
    home.activation.firefoxRouter = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${escapeShellArg "${config.home.homeDirectory}/Applications"}
      $DRY_RUN_CMD rm -rf ${escapeShellArg routerApp}
      $DRY_RUN_CMD cp -R ${escapeShellArg "${routerAppPkg}/Applications/Firefox Router.app"} ${escapeShellArg routerApp}
      $DRY_RUN_CMD chmod -R u+w ${escapeShellArg routerApp}
      $DRY_RUN_CMD ${lsregister} -f ${escapeShellArg routerApp}
    '';
  };
}
