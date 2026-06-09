#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

# Rectangle window snapping on the Hyper layer (Ctrl+Opt+Cmd+Shift).
#
# Grammar: arrows = reshape current region, so halves live on Hyper+arrows.
# Quarters keep Rectangle's native u/i/j/k cluster. Maximize on Hyper+Enter.
#
# Each binding is stored as a real dict (not a JSON string) with two integer
# keys: keyCode and modifierFlags.
#   modifierFlags = NSEvent modifier mask, Hyper = 0x1E0000 = 1966080
#   keyCode       = macOS virtual keycode
#                   arrows: ←=123 →=124 ↓=125 ↑=126
#                   Return=36, u=32, i=34, j=38, k=40
#
# Rectangle re-reads its config on launch and persists its in-memory state
# on quit, so we stop the app first to prevent it from clobbering the writes.

HYPER=1966080

if pgrep -x Rectangle >/dev/null; then
	osascript -e 'tell application "Rectangle" to quit' || true
	sleep 1
fi

set_binding() {
	local action="$1" keycode="$2"
	defaults write com.knollsoft.Rectangle "$action" \
		-dict keyCode -int "$keycode" modifierFlags -int "$HYPER"
}

# Halves on Hyper+arrows
set_binding leftHalf    123
set_binding rightHalf   124
set_binding bottomHalf  125
set_binding topHalf     126

# Maximize on Hyper+Enter
set_binding maximize    36

# Quarters on Hyper+u/i/j/k (Rectangle's native cluster)
set_binding topLeft     32
set_binding topRight    34
set_binding bottomLeft  38
set_binding bottomRight 40

open -ga Rectangle

echo "Rectangle Hyper+hjkl half-snap bindings written and app relaunched."
