# swapper

Runs one shell script when this Mac gains an external display and another when
it goes back to the built-in panel alone. Use it to flip anything that should
differ between docked and mobile: Dock hiding, game resolutions, and so on.

The scripts are the configuration:

    ~/.config/swapper/docked.sh   # any external display is online
    ~/.config/swapper/mobile.sh   # only the built-in display is online

Each runs with `$SWAPPER_MODE` (`docked` or `mobile`) and `$SWAPPER_DISPLAYS`
(a human-readable list of online displays) in its environment. Lid closed with
an external display attached counts as docked.

## How it works

`swapper watch` registers a CoreGraphics display-reconfiguration callback,
waits two seconds for the burst of events a dock or undock produces to settle,
and runs the matching script only when the mode actually changes. It also runs
once at startup so login syncs state. A per-user launchd agent keeps it alive.

Built on system frameworks only.

## Install

    make install

That builds a release binary into `~/.local/bin/swapper`, writes the example
scripts if none exist, and installs `~/Library/LaunchAgents/com.mtklein.swapper.plist`.
Output from the scripts goes to `~/Library/Logs/swapper.log`.

    swapper status          # detected mode, displays, script and agent state
    swapper run [mode]      # run a script by hand (defaults to the detected mode)
    swapper dock-autohide [on|off]   # show or set Dock auto-hide live
    swapper init            # write example scripts, keeping existing ones
    swapper uninstall       # stop and remove the launchd agent
    make uninstall          # the above plus remove the binary

My own `docked.sh` and `mobile.sh` are tracked in this repo; `make link` symlinks
them into `~/.config/swapper`. Edit the scripts freely; the agent runs whatever
is there at the moment the mode changes. Restarting the agent is only needed after rebuilding the binary
(`make install` handles that).

## The example scripts

- Dock: shown when docked, auto-hidden when mobile, via `swapper dock-autohide`.
  That calls the same HIServices `CoreDock` functions System Events uses, so the
  live Dock updates in place. If a future macOS drops those symbols it falls back
  to `defaults write` plus a Dock restart.
- MTG Arena: a 3840x2160 window when docked, native fullscreen when mobile.
  Written to the Unity `Screenmanager` keys in `com.wizards.mtga`, which the
  game reads at launch, so a running game picks the change up next start.
