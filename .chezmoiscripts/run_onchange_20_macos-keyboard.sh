#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

echo "Configuring macOS keyboard settings for NeoVim..."

# Enable key repeat + make it fast
defaults write -g ApplePressAndHoldEnabled -bool false
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15

echo "Keyboard settings configured"
echo "Note: Changes take effect after logging out and back in"
