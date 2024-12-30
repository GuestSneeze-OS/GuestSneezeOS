#!/bin/bash
# Yep, this script is inspired by winesapOS. Check it out! 
# https://github.com/winesapOS/winesapOS
export \
  GUESTSNEEZEOSOS_DE="${GUESTSNEEZEOS_DE:-plasma}" \
  GUESTSNEEZEOS_GAMING="${GUESTSNEEZEOS_GAMING:-true}" \
  GUESTSNEEZEOS_BUILD="${GUESTSNEEZEOS_BUILD:-true}" \
  GUESTSNEEZEOS_WAYLAND_ENABLE="${GUESTSNEEZEOS_WAYLAND_ENABLE:-false}" \
# Set GUESTSNEEZEOS_BUILD to false if you want to enable configs