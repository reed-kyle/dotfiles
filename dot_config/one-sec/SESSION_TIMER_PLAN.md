# Session Timer Re-Intervention Plan

## Goal
Allow time-limited sessions (e.g., 5 minutes) with wrapped commands like `claude`.
After time expires, detach terminal and require re-intervention to resume.
Ctrl+C during intervention kills the background session entirely.

## Architecture: tmux-based session management

### Flow
1. User runs `claude` → intervention runs
2. After intervention: launch `claude` in detached tmux session (unique name)
3. Immediately attach to that session (user interacts normally)
4. Background timer process waits N minutes
5. Timer expires → programmatically detach from tmux
6. Show intervention again in main shell
7. Outcomes:
   - Complete intervention → re-attach to tmux (resume Claude session)
   - Ctrl+C → kill tmux session (terminate Claude)

### Benefits
- Claude process never interrupted (API calls, streaming continue)
- Detach only disconnects terminal, not the process
- Can resume exactly where you left off
- Clean kill on Ctrl+C

## Implementation Details

### 1. Configuration
Add to defaults section:
```zsh
_ONESEC_SESSION_MINUTES=5  # minutes before re-intervention (0 = no timer)
```

Allow per-command override:
```
claude session_minutes=10
```

### 2. Session naming
Generate unique session names:
```zsh
local session_name="onesec-${cmd}-${EPOCHSECONDS}-$$"
```
Format: `onesec-claude-1710694000-12345`

### 3. Background timer process
```zsh
{
  sleep $((session_minutes * 60))
  # send signal to parent shell to trigger re-intervention
  kill -USR1 $parent_shell_pid
} &
local timer_pid=$!
```

### 4. Signal handling
Set up trap in parent shell:
```zsh
TRAPUSR1() {
  # detach from tmux if currently attached to onesec-* session
  # trigger intervention loop again
}
```

### 5. Modified _onesec_wrap()
```
function _onesec_wrap() {
  while true; do
    # run intervention
    # if Ctrl+C → cleanup and return 1
    
    if (( session_minutes > 0 )); then
      # tmux mode
      if [[ -z $tmux_session_name ]]; then
        # first time: create new session
        tmux_session_name="onesec-${cmd}-${EPOCHSECONDS}-$$"
        tmux new-session -d -s "$tmux_session_name" "$cmd $@"
      fi
      # start background timer
      { sleep $((session_minutes * 60)); kill -USR1 $$ } &
      timer_pid=$!
      # attach (this blocks until detached by signal or user exit)
      tmux attach -t "$tmux_session_name"
      kill $timer_pid 2>/dev/null  # user exited normally, cancel timer
      tmux kill-session -t "$tmux_session_name" 2>/dev/null
      break
    else
      # no timer: just run command directly
      command "${cmd%% *}" "$@"
      break
    fi
  done
}
```

### 6. Wrap tmux command
Prevent direct access to onesec-managed sessions:
```zsh
function tmux() {
  local arg
  for arg in "$@"; do
    if [[ "$arg" == onesec-* ]]; then
      echo "one-sec: managed session - use the wrapped command instead"
      return 1
    fi
  done
  command tmux "$@"
}
```

### 7. Ctrl+C handling during intervention
Current code has:
```zsh
$'\x03')
  printf '\033[?25h\n'; return 1 ;;
```

Need to enhance to also kill tmux session if one exists:
```zsh
$'\x03')
  printf '\033[?25h\n'
  [[ -n $tmux_session_name ]] && tmux kill-session -t "$tmux_session_name" 2>/dev/null
  return 1 ;;
```

## Edge Cases

### Session cleanup
- If shell exits unexpectedly, orphaned tmux sessions remain
- Add cleanup on shell exit: `TRAPEXIT() { tmux kill-session -t onesec-$$ 2>/dev/null }`
- Or periodic cleanup: find sessions older than X hours

### Multiple concurrent wrapped commands
- Each gets unique session name ($$, EPOCHSECONDS ensures uniqueness)
- Each has its own timer
- Should work independently

### Timer signal race conditions
- Timer fires while not attached (user already exited)
- Timer fires during intervention (ignore?)
- Kill timer PID when session ends normally

### User detaches manually (Ctrl+B D)
- Session keeps running but no timer enforcement
- Could detect manual detach and treat as early intervention trigger?
- Or just let it slide - manual detach is intentional

## Open Questions

1. **Should session time accumulate or reset?**
   - Option A: 5 minutes total usage per intervention
   - Option B: 5 minutes consecutive, but detaching pauses the clock

2. **What if tmux not installed?**
   - Graceful fallback to non-session mode?
   - Require it and show install message?

3. **Show timer countdown in tmux status bar?**
   - Visual reminder of remaining time
   - `tmux set-option status-right "one-sec: 3:42 remaining"`

4. **Allow emergency bypass?**
   - Special escape sequence/password to skip if truly urgent?
   - Or is that defeating the purpose?

## Benefits of This Approach
- Non-destructive (preserves running processes)
- Natural UX (just detaches your view)
- Enforces mindful re-commitment every N minutes
- Ctrl+C properly cleans up everything
- Can extend to any terminal app, not just Claude

## Estimated Complexity
~100 lines of additional code, mostly around:
- Timer process management
- Signal handling
- tmux session lifecycle
- Cleanup edge cases
