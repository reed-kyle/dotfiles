#!/usr/bin/env bash
set -euo pipefail

# Install the Pi-side extension for aliou/nvim-pi.
PI_BIN="$(command -v pi || true)"
if [[ -z "$PI_BIN" ]] && command -v zsh >/dev/null 2>&1; then
  PI_BIN="$(zsh -lc 'command -v pi' 2>/dev/null || true)"
fi

if [[ -z "$PI_BIN" ]]; then
  echo "pi not found on PATH; skipping aliou/nvim-pi Pi extension install" >&2
  exit 0
fi

"$PI_BIN" install git:github.com/aliou/nvim-pi
