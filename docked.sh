#!/bin/sh
# swapper runs this when an external display is connected.
#   $SWAPPER_MODE      "docked"
#   $SWAPPER_DISPLAYS  e.g. "Built-in Retina Display 3024x1964 (built-in); Studio Display 5120x2880"
set -eu

# Dock: always visible. Applied live; no Dock restart, no screen flash.
swapper dock-autohide off

# MTG Arena: 3840x2160 window. Read by the game at launch, so it takes effect
# next time MTGA starts. (Unity "Fullscreen mode": 1 = fullscreen window, 3 = windowed.)
defaults write com.wizards.mtga "Screenmanager Fullscreen mode" -int 3
defaults write com.wizards.mtga "Screenmanager Resolution Use Native" -int 0
defaults write com.wizards.mtga "Screenmanager Resolution Width" -int 3840
defaults write com.wizards.mtga "Screenmanager Resolution Height" -int 2160
