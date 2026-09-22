# Rebuild a working context's tmux layout from a single command.
#
# ~/projects/coconut and ~/projects/jarsater are plain directories holding
# sibling git repos with unrelated toolchains - neither is a project in its own
# right - so a window maps to a repo rather than to a directory inside one tree.
# Two sessions may therefore share a root: Coconut and Pineapple are separate
# customers whose repos sit side by side under ~/projects/coconut, much as
# containers.nix keys profiles by a path that two tenancies can share.
#
# A repo window holds nothing but its editor, full size. Each session then gets
# one shared `term` window at its root, created last. Nothing is started there
# and nothing is typed into it: several of these repos front a ten-container
# compose stack, a kind cluster or an mkdocs server, and two of them race for
# port 8000, so a session usually opened just to read something never pays for
# any of that. Because that window sits at the session root rather than in a
# repo, the .envrc files that scope AWS_CONFIG_FILE and KUBECONFIG per repo do
# not apply to it - cd first when the command cares which account it talks to.
#
# Run this from outside tmux the first time after a reboot. home-manager.nix
# guards the gpg-agent launch and the podman DOCKER_HOST probe behind
# `if [[ -z "$TMUX" ]]`, so these windows deliberately skip that work and
# inherit it from whichever shell started the server instead.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.local.tmux;

  windowType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        example = "helm";
        description = ''
          Window name. Keep it short: window-status-format renders "#I/#W" and
          status-right is empty, so these pills are the only navigational signal
          in the status bar.
        '';
      };

      path = mkOption {
        type = types.str;
        example = "k8s/s76";
        description = ''
          Repo directory, relative to the session root (an absolute path is
          taken as-is). Nested paths are fine - the most active jarsater repo
          lives two levels down at k8s/s76.

          This is what the window is opened in, which is load-bearing rather
          than cosmetic: several coconut repos carry an .envrc that scopes
          AWS_CONFIG_FILE and KUBECONFIG to their own directory, so a window
          started elsewhere talks to the wrong account.
        '';
      };

      editor = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to start nvim in the window. Set it false for directories
          that hold assets rather than code, which leaves a bare shell.
        '';
      };
    };
  };

  sessionType = types.submodule {
    options = {
      root = mkOption {
        type = types.str;
        example = "/Users/jj/projects/coconut";
        description = ''
          Directory the session's window paths are resolved against, and the
          working directory of the shared `term` window.
        '';
      };

      windows = mkOption {
        type = types.listOf windowType;
        default = [];
        description = ''
          Windows in creation order. The first one becomes the selected window,
          so put the repo the day usually starts in at the top. The `term`
          window is appended after these.
        '';
      };
    };
  };

  # One binary per session, mirroring the ff-<tenancy> launchers. The layout is
  # emitted as a list of add_window calls rather than a shell loop: the data
  # lives in Nix, so the generated script stays readable when something needs
  # debugging with `cat $(command -v tmux-coconut)`.
  mkSessionScript = sessionName: session: let
    resolve = path:
      if hasPrefix "/" path
      then path
      else "${session.root}/${path}";

    addWindow = window:
      concatStringsSep " " [
        "add_window"
        (escapeShellArg window.name)
        (escapeShellArg (resolve window.path))
        (
          if window.editor
          then "1"
          else "0"
        )
      ];
  in
    pkgs.writeShellApplication {
      name = "tmux-${toLower sessionName}";
      runtimeInputs = [pkgs.tmux];
      text = ''
        session=${escapeShellArg sessionName}

        ${attachFunction}

        # Never rebuild a session that is already up. Reattaching to yesterday's
        # windows is the whole point; recreating them would discard running
        # editors and scrollback.
        if tmux has-session -t "=$session" 2>/dev/null; then
          attach
          exit 0
        fi

        created=0
        first=""

        add_window() {
          name=$1
          dir=$2
          editor=$3

          # A repo can be absent on a machine that has not cloned it yet, or
          # after a rename upstream. Skip that window rather than aborting and
          # leaving a half-built session behind.
          if [ ! -d "$dir" ]; then
            echo "$0: skipping window '$name': $dir does not exist" >&2
            return 0
          fi

          # The first window has to come from new-session; creating it with
          # new-window instead leaves a stray empty window 1 behind.
          if [ "$created" -eq 0 ]; then
            tmux new-session -d -s "$session" -n "$name" -c "$dir"
            created=1
            first=$name
          else
            tmux new-window -t "$session:" -n "$name" -c "$dir"
          fi

          if [ "$editor" -eq 1 ]; then
            tmux send-keys -t "$session:$name" nvim C-m
          fi
        }

        ${concatMapStringsSep "\n" addWindow session.windows}

        if [ "$created" -eq 0 ]; then
          echo "$0: no window directories exist under ${session.root}" >&2
          exit 1
        fi

        # After the guard, not before: with no repo window there is no session
        # to hang this one off.
        tmux new-window -t "$session:" -n term -c ${escapeShellArg session.root}

        tmux select-window -t "$session:$first"
        attach
      '';
    };

  # switch-client rather than attach-session when we are already inside tmux:
  # attaching nests a client in the current pane, which renders a status bar
  # inside a status bar and traps the prefix key one level down.
  attachFunction = ''
    attach() {
      if [ -n "''${TMUX:-}" ]; then
        tmux switch-client -t "=$session"
      else
        tmux attach-session -t "=$session"
      fi
    }
  '';
in {
  options.local.tmux = {
    enable = mkEnableOption "declarative tmux session layouts";

    sessions = mkOption {
      type = types.attrsOf sessionType;
      default = {};
      description = ''
        tmux sessions, one per working context, installed as tmux-<name>
        binaries. The attribute name is the session name and shows up in
        status-left, so capitalisation is worth caring about.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mapAttrsToList mkSessionScript cfg.sessions;
  };
}
