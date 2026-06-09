#!/usr/bin/env bash
set -euo pipefail

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Node via fnm
if ! fnm ls | grep -q "^\* v"; then
  fnm install --lts
  fnm default lts-latest
fi
eval "$(fnm env)"

npm install -g @earendil-works/pi-coding-agent
