# Rebuild a working context's tmux layout from a single command.
#
# ~/projects/coconut and ~/projects/jarsater are plain directories holding
# sibling git repos with unrelated toolchains - neither is a project in its own
# right - so a window maps to a repo rather than to a directory inside one tree.
# Two sessions may therefore share a root: Coconut and Pineapple are separate
# customers whose repos sit side by side under ~/projects/coconut, much as
# containers.nix keys profiles by a path that two tenancies can share.
#
# Panes are placed but left idle apart from the editor. Several of these repos
# front a ten-container compose stack, a kind cluster or an mkdocs server, and
# two of them race for port 8000; starting all that on every attach would cost
# minutes and gigabytes to serve a session usually opened just to read
# something. The runner pane gets its command typed but not entered, so the
# useful thing is one keystroke away without ever firing on its own.
#
# Run this from outside tmux the first time after a reboot. home-manager.nix
# guards the gpg-agent launch and the podman DOCKER_HOST probe behind
# `if [[ -z "$TMUX" ]]`, so panes deliberately skip that work and inherit it
# from whichever shell started the server instead.
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
          Window name. Keep it short: window-status-format renders "#I > #W" and
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

          This is what every pane in the window is opened in, which is
          load-bearing rather than cosmetic: several coconut repos carry an
          .envrc that scopes AWS_CONFIG_FILE and KUBECONFIG to their own
          directory, so a pane started elsewhere talks to the wrong account.
        '';
      };

      editor = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to start nvim in the first pane. Set it false for directories
          that hold assets rather than code, which gives three bare shells.
        '';
      };

      runner = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "mise run ci";
        description = ''
          Command typed into the third pane without a trailing newline, so it
          waits on Enter. Meant for the repo's own gate - `make check`,
          `mise run ci`, `pulumi preview` - not for anything long-lived.
        '';
      };
    };
  };

  sessionType = types.submodule {
    options = {
      root = mkOption {
        type = types.str;
        example = "/Users/jj/projects/coconut";
        description = "Directory the session's window paths are resolved against.";
      };

      windows = mkOption {
        type = types.listOf windowType;
        default = [];
        description = ''
          Windows in creation order. The first one becomes the selected window,
          so put the repo the day usually starts in at the top.
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
        (escapeShellArg (
          if window.runner == null
          then ""
          else window.runner
        ))
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

        # split-window resolves a percentage against the window size at the
        # moment of the split, and a detached session is created at
        # default-size (80x24) however wide the terminal really is. Splitting
        # at that size and letting tmux rescale on attach lands the right-hand
        # column well wide of 40%, so build the session at the real terminal
        # size instead. The fallback only applies when there is no tty to ask,
        # which in practice means a script or a hook rather than a login shell.
        cols=240
        rows=60
        if [ -t 1 ]; then
          cols=$(tput cols)
          rows=$(tput lines)
        fi

        add_window() {
          name=$1
          dir=$2
          editor=$3
          runner=$4

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
            tmux new-session -d -s "$session" -n "$name" -c "$dir" -x "$cols" -y "$rows"
            created=1
            first=$name
          else
            tmux new-window -t "$session:" -n "$name" -c "$dir"
          fi

          # -c on both splits, because a split otherwise inherits the pane's
          # current directory only until something cds, and these panes need to
          # stay pinned to the repo for its .envrc to mean anything.
          tmux split-window -h -t "$session:$name" -c "$dir" -l 40%
          tmux split-window -v -t "$session:$name.2" -c "$dir" -l 50%

          if [ "$editor" -eq 1 ]; then
            tmux send-keys -t "$session:$name.1" nvim C-m
          fi

          if [ -n "$runner" ]; then
            tmux send-keys -t "$session:$name.3" "$runner"
          fi

          tmux select-pane -t "$session:$name.1"
        }

        ${concatMapStringsSep "\n" addWindow session.windows}

        if [ "$created" -eq 0 ]; then
          echo "$0: no window directories exist under ${session.root}" >&2
          exit 1
        fi

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
