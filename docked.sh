#!/bin/sh
# swapper runs this when an external display is connected.
#   $SWAPPER_MODE      "docked"
#   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in); Studio Display 5120x2880"
set -eu
PATH="$HOME/.local/bin:$PATH"   # where `make install` puts swapper

# Dock: always visible.
swapper dock-autohide off

# MTG Arena: 4K window.
# (Unity "Fullscreen mode": 1 = fullscreen window, 3 = windowed.)
defaults write com.wizards.mtga "Screenmanager Fullscreen mode" -int 3
defaults write com.wizards.mtga "Screenmanager Resolution Use Native" -int 0
defaults write com.wizards.mtga "Screenmanager Resolution Width" -int 3840
defaults write com.wizards.mtga "Screenmanager Resolution Height" -int 2160

# GeForce NOW: stream at 2560x1440 120 Hz, exactly half the Studio Display XDR
# in each axis, so the upscale lands on pixel boundaries. The client reads this
# file at launch and rewrites it at quit, so the change lands the next time
# GeForce NOW starts.
gfn="$HOME/Library/Application Support/NVIDIA/GeForceNOW/sharedstorage.json"
if [ -f "$gfn" ]; then
    plutil -replace appSettingsConfig.customProfile.width  -integer 2560 "$gfn"
    plutil -replace appSettingsConfig.customProfile.height -integer 1440 "$gfn"
    plutil -replace appSettingsConfig.customProfile.fps    -integer 120  "$gfn"
    # Adaptive vsync (2) is what unlocks Cloud G-SYNC, which paces the panel to
    # the frames as they land. 75 Mbps of the 100 the service allows, so a WiFi
    # burst has room to pass without the encoder noticing and backing off.
    plutil -replace appSettingsConfig.customProfile.vSync      -integer 2  "$gfn"
    plutil -replace appSettingsConfig.customProfile.cloudGsync -bool true  "$gfn"
    plutil -replace appSettingsConfig.customProfile.maxBitrate -integer 75 "$gfn"
fi
