#!/bin/sh
# swapper runs this when only the built-in display is present.
#   $SWAPPER_MODE      "mobile"
#   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in)"
set -eu
PATH="$HOME/.local/bin:$PATH"   # where `make install` puts swapper

# Dock: auto-hide.
swapper dock-autohide on

# MTG Arena: fullscreen at the panel's native resolution. Takes effect next launch.
defaults write com.wizards.mtga "Screenmanager Fullscreen mode" -int 1
defaults write com.wizards.mtga "Screenmanager Resolution Use Native" -int 1

# GeForce NOW: stream at 2560x1600 120 Hz, the largest offered mode that fits
# inside the built-in panel. Takes effect next launch.
gfn="$HOME/Library/Application Support/NVIDIA/GeForceNOW/sharedstorage.json"
if [ -f "$gfn" ]; then
    plutil -replace appSettingsConfig.customProfile.width  -integer 2560 "$gfn"
    plutil -replace appSettingsConfig.customProfile.height -integer 1600 "$gfn"
    plutil -replace appSettingsConfig.customProfile.fps    -integer 120  "$gfn"
fi
