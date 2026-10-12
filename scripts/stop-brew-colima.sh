#!/usr/bin/env bash
# post-tools hook: colima now runs as mise's user service (dev.mise.colima);
# unload the old `brew services` LaunchAgent so the two do not fight.
set -euo pipefail

if [[ -f ~/Library/LaunchAgents/homebrew.mxcl.colima.plist ]] && command -v brew &>/dev/null; then
  brew services stop colima
fi
