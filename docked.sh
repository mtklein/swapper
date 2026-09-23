#!/bin/sh
# swapper runs this when an external display is connected.
#   $SWAPPER_MODE      "docked"
#   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in); Studio Display 5120x2880"
set -eu
PATH="$HOME/.local/bin:$PATH"   # where `make install` puts swapper

swapper dock-autohide off

# Put the laptop on the side of the Studio Display facing the port it's plugged
# into: receptacles 1 and 2 are on the laptop's left edge, 3 on its right.
port=$(system_profiler SPThunderboltDataType | awk '/Receptacle:/ { r = $2 } /Studio Display/ { print r; exit }')
case "$port" in
    1|2) swapper builtin-side right ;;
    3)   swapper builtin-side left ;;
esac

# (Unity "Fullscreen mode": 1 = fullscreen window, 3 = windowed.)
defaults write com.wizards.mtga "Screenmanager Fullscreen mode" -int 3
defaults write com.wizards.mtga "Screenmanager Resolution Use Native" -int 0
defaults write com.wizards.mtga "Screenmanager Resolution Width" -int 3840
defaults write com.wizards.mtga "Screenmanager Resolution Height" -int 2160

# Adaptive vsync (2) allows Cloud G-SYNC which paces the panel to frames as they land.
gfn="$HOME/Library/Application Support/NVIDIA/GeForceNOW/sharedstorage.json"
if [ -f "$gfn" ]; then
    plutil -replace appSettingsConfig.customProfile.width      -integer 5120 "$gfn"
    plutil -replace appSettingsConfig.customProfile.height     -integer 2880 "$gfn"
    plutil -replace appSettingsConfig.customProfile.fps        -integer 120  "$gfn"
    plutil -replace appSettingsConfig.customProfile.vSync      -integer 2    "$gfn"
    plutil -replace appSettingsConfig.customProfile.cloudGsync -bool true    "$gfn"
    plutil -replace appSettingsConfig.customProfile.maxBitrate -integer 100  "$gfn"
fi
