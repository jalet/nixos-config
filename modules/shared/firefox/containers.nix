# Containers are merged into containers.json rather than generated from it.
#
# home-manager's programs.firefox.profiles.<n>.containers option writes
# containers.json as a read-only symlink into the Nix store, and its generated
# file omits Firefox's four built-in containers. Two things break under that:
#
#   1. The Granted extension creates a container per AWS profile at runtime via
#      contextualIdentities.create(). Firefox writes containers.json atomically,
#      replacing the symlink with a real file - which the next activation then
#      moves aside and re-links, discarding every Granted container.
#   2. Personal / Work / Banking / Shopping disappear.
#
# So instead: declare the containers we want, and reconcile them into whatever
# is already on disk. The script is idempotent and writes nothing when the
# declared set already matches.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.local.firefox;

  # Keyed by on-disk directory rather than tenancy name, since a tenancy may
  # adopt an existing profile directory via `path`.
  spec = {
    inherit (cfg) profilesPath;
    profiles =
      mapAttrs' (_: tenancy: nameValuePair tenancy.path tenancy.containers)
      cfg.tenancies;
  };

  mergeScript = pkgs.writeText "firefox-merge-containers.py" ''
    import json
    import os
    import sys
    import tempfile

    # The two bookkeeping identities Firefox keeps at the top of the id space.
    # Anything below this is a real, user-visible container.
    INTERNAL_MIN = 2 ** 31

    # What Firefox itself writes into a fresh profile. Used only when there is
    # no containers.json yet, so a new profile still gets the stock containers.
    DEFAULTS = [
        {"userContextId": 1, "public": True, "icon": "fingerprint",
         "color": "blue", "l10nId": "user-context-personal"},
        {"userContextId": 2, "public": True, "icon": "briefcase",
         "color": "orange", "l10nId": "user-context-work"},
        {"userContextId": 3, "public": True, "icon": "dollar",
         "color": "green", "l10nId": "user-context-banking"},
        {"userContextId": 4, "public": True, "icon": "cart",
         "color": "pink", "l10nId": "user-context-shopping"},
        {"userContextId": 4294967294, "public": False, "icon": "", "color": "",
         "accessKey": "", "name": "userContextIdInternal.thumbnail"},
        {"userContextId": 4294967295, "public": False, "icon": "", "color": "",
         "accessKey": "", "name": "userContextIdInternal.webextStorageLocal"},
    ]


    def public_ids(identities):
        return [
            i.get("userContextId", 0)
            for i in identities
            if i.get("userContextId", 0) < INTERNAL_MIN
        ]


    def reconcile(path, declared):
        try:
            with open(path) as handle:
                data = json.load(handle)
        except (FileNotFoundError, ValueError):
            data = {"version": 5, "lastUserContextId": 4,
                    "identities": list(DEFAULTS)}

        identities = data.setdefault("identities", [])
        by_name = {i["name"]: i for i in identities if i.get("name")}
        next_id = max(public_ids(identities), default=0) + 1
        changed = False

        for name in sorted(declared):
            want = declared[name]
            found = by_name.get(name)
            if found is None:
                identities.append({
                    "userContextId": next_id,
                    "public": True,
                    "icon": want["icon"],
                    "color": want["color"],
                    "name": name,
                })
                next_id += 1
                changed = True
            elif (found.get("icon"), found.get("color")) != (want["icon"], want["color"]):
                found["icon"] = want["icon"]
                found["color"] = want["color"]
                changed = True

        highest = max(public_ids(identities), default=0)
        if data.get("lastUserContextId") != highest:
            data["lastUserContextId"] = highest
            changed = True

        if not changed:
            return False

        # Atomic replace, so a symlink left over from an older generation
        # becomes a regular writable file that Firefox and Granted can update.
        directory = os.path.dirname(path)
        os.makedirs(directory, exist_ok=True)
        handle_fd, tmp = tempfile.mkstemp(dir=directory)
        try:
            with os.fdopen(handle_fd, "w") as handle:
                json.dump(data, handle, indent=2)
            os.replace(tmp, path)
        except BaseException:
            if os.path.exists(tmp):
                os.unlink(tmp)
            raise
        return True


    def main():
        spec = json.loads(sys.argv[1])
        root = spec["profilesPath"]
        for profile, declared in sorted(spec["profiles"].items()):
            if not declared:
                continue
            if reconcile(os.path.join(root, profile, "containers.json"), declared):
                print("firefox: reconciled containers for profile " + profile)


    main()
  '';
in {
  config = mkIf cfg.enable {
    home.activation.firefoxContainers = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${mergeScript} ${escapeShellArg (builtins.toJSON spec)}
    '';
  };
}
