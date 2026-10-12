#!/usr/bin/env bash
set -euo pipefail

repo='https://github.com/eggplants/setup-macos.sh.git'
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"
export PATH="$HOME/.local/bin:$PATH"

if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "Re-run this script after the Command Line Tools finish installing." >&2
  exit 1
fi

# the colima service runs ~/.local/bin/mise, so install it there
if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  curl -fsSL https://mise.run | sh
fi

if [[ ! -d "$config_dir/.git" ]]; then
  if [[ -e "$config_dir" ]]; then
    mv "$config_dir" "$config_dir.bak.$(date +%Y%m%d%H%M%S)"
  fi
  git clone "$repo" "$config_dir"
fi

mise bootstrap "$@"
