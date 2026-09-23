#!/bin/sh
# swapper runs this when an external display is connected.
#   $SWAPPER_MODE      "docked"
#   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in); Studio Display 5120x2880"
set -eu
PATH="$HOME/.local/bin:$PATH"   # where `make install` puts swapper

swapper dock-autohide off

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
