#!/usr/bin/env bash
set -euo pipefail

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env)"
fi

# Install the Pi-side extension for aliou/nvim-pi.
PI_BIN="$(command -v pi || true)"
if [[ -z "$PI_BIN" ]]; then
  echo "pi not found on PATH; skipping aliou/nvim-pi Pi extension install" >&2
  exit 0
fi

"$PI_BIN" install git:github.com/aliou/nvim-pi
