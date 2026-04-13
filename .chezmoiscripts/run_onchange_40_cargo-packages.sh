#!/usr/bin/env bash
set -euo pipefail

# Ensure Homebrew-installed tools are in PATH
if [[ -x /opt/homebrew/bin/brew ]]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Cargo tools — edit this file to add/remove packages
cargo install --git https://github.com/mitsuhiko/idasen-control.git
