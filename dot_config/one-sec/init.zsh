# one-sec — mindful pause before opening distracting terminal apps
# Config: ~/.config/one-sec/commands

# ---------------------------------------------------------------------------
# Defaults (override per-command in the commands file)
# ---------------------------------------------------------------------------
_ONESEC_PACE=3.0        # seconds for one half-cycle (inhale OR exhale)
_ONESEC_CYCLES=3        # breath cycles before typing
_ONESEC_CYCLES_AFTER=3  # breath cycles after typing
_ONESEC_HOLD=0.5        # pause at peak inhale / end of exhale
_ONESEC_MIN_CHARS=50    # minimum chars the user must type per prompt (prefix excluded)
_ONESEC_MIN_ENTROPY=3.0 # minimum Shannon entropy (bits) — typical English ≈ 4.0, mashing ≈ 0–1.5
_ONESEC_MIN_REAL_WORDS=3 # minimum dictionary words (defeats gibberish that has high entropy)
_ONESEC_VERB=open       # action verb — override per-command with verb=install etc.

# ---------------------------------------------------------------------------
# Breathing animation — full-screen vertical fill, like the one-sec app
# Inhale: fill rises from bottom to top (blue background)
# Exhale: fill recedes from top to bottom
# pace = total seconds for one half-cycle (inhale or exhale)
# ---------------------------------------------------------------------------
_onesec_breathe() {
  local cycles="${1:-$_ONESEC_CYCLES}"
  local pace="${2:-$_ONESEC_PACE}"
  local hold="${3:-$_ONESEC_HOLD}"

  local c row height width num_steps step_time mid_row mid_col

  height=${LINES:-24}
  width=${COLUMNS:-80}
  mid_row=$(( height / 2 ))
  mid_col=$(( (width - 8) / 2 + 1 ))  # " inhale " / " exhale " = 8 chars, 1-indexed

  num_steps=$(( height - 1 ))
  step_time=$(awk "BEGIN{printf \"%.6f\", $pace / $num_steps}")

  # enter alternate screen buffer, hide cursor, clear screen
  printf '\033[?1049h\033[?25l\033[2J'

  for ((c = 0; c < cycles; c++)); do

    # Inhale — fill from bottom to top with blue background
    for ((row = height; row >= 1; row--)); do
      printf '\033[%d;1H\033[44m%*s\033[0m' "$row" "$width" ""
      printf '\033[%d;%dH\033[1;97m inhale \033[0m' "$mid_row" "$mid_col"
      sleep "$step_time"
    done
    sleep "$hold"

    # Exhale — clear from top to bottom
    for ((row = 1; row <= height; row++)); do
      printf '\033[%d;1H\033[K' "$row"
      printf '\033[%d;%dH\033[1;34m exhale \033[0m' "$mid_row" "$mid_col"
      sleep "$step_time"
    done
    sleep "$hold"

  done

  # show cursor, exit alternate screen (restores normal terminal state)
  printf '\033[?25h\033[?1049l'
}

# ---------------------------------------------------------------------------
# Dictionary — lazy-loaded on first use
# ---------------------------------------------------------------------------
typeset -gA _onesec_dict
typeset -g _onesec_dict_loaded=0

_onesec_load_dict() {
  (( _onesec_dict_loaded )) && return
  local w dict_file="${0:A:h}/words.txt"
  [[ -f "$dict_file" ]] || dict_file="/usr/share/dict/words"
  while IFS= read -r w; do
    _onesec_dict[${(L)w}]=1
  done < "$dict_file" 2>/dev/null
  _onesec_dict_loaded=1
}

# ---------------------------------------------------------------------------
# Count dictionary words in a string — result in _onesec_real_words
# ---------------------------------------------------------------------------
_onesec_count_words() {
  _onesec_load_dict
  local str="$1"
  _onesec_real_words=0
  local -a words=(${=str})
  local w
  for w in "${words[@]}"; do
    (( ${+_onesec_dict[${(L)w}]} )) && (( _onesec_real_words++ ))
  done
}

# ---------------------------------------------------------------------------
# Shannon entropy (bits per character) of a string
# Returns result in global _onesec_entropy (avoids subshell)
# ---------------------------------------------------------------------------
_onesec_entropy() {
  local str="$1" len=${#1}
  _onesec_entropy_val=0
  (( len == 0 )) && return
  # count frequency of each character
  typeset -A freq
  local i ch
  for (( i=1; i<=len; i++ )); do
    ch="${str[$i]}"
    freq[$ch]=$(( ${freq[$ch]:-0} + 1 ))
  done
  # H = -Σ (count/len) * log2(count/len)  — computed via awk for float math
  local counts=""
  for ch in ${(k)freq}; do
    counts+="${freq[$ch]} "
  done
  _onesec_entropy_val=$(awk -v counts="$counts" -v len="$len" 'BEGIN{
    n=split(counts,a," "); h=0
    for(i=1;i<=n;i++){ p=a[i]/len; h -= p * (log(p)/log(2)) }
    printf "%.2f", h
  }')
}

# ---------------------------------------------------------------------------
# Check if input meets quality threshold (length + entropy + real words)
# Sets _onesec_input_ok=1 if acceptable, 0 otherwise
# ---------------------------------------------------------------------------
_onesec_quality_ok() {
  local input="$1" min_chars="$2"
  _onesec_input_ok=0
  (( ${#input} < min_chars )) && return
  [[ "${input[-1]}" == "." ]] || return
  _onesec_entropy "$input"
  (( $(awk "BEGIN{print ($_onesec_entropy_val >= $_ONESEC_MIN_ENTROPY)}") )) || return
  _onesec_count_words "$input"
  (( _onesec_real_words >= _ONESEC_MIN_REAL_WORDS )) && _onesec_input_ok=1
}

# ---------------------------------------------------------------------------
# Word-wrap $1 to $2 cols, storing lines in global array _onesec_lines
# ---------------------------------------------------------------------------
_onesec_wrap_text() {
  local text="$1" width="$2"
  _onesec_lines=()
  local rem="$text" sp i
  while (( ${#rem} > width )); do
    sp=0
    for (( i=width; i>=1; i-- )); do
      [[ "${rem[$i]}" == " " ]] && { sp=$i; break; }
    done
    if (( sp > 0 )); then
      _onesec_lines+=("${rem[1,$((sp-1))]}")
      rem="${rem[$((sp+1)),-1]}"
    else
      _onesec_lines+=("${rem[1,$width]}")
      rem="${rem[$((width+1)),-1]}"
    fi
  done
  _onesec_lines+=("$rem")
}

# ---------------------------------------------------------------------------
# Render one commitment prompt inside the centred column.
# Counter counts only ${#input}, not the prefix.
# Optional $7 header (a completed prior prompt) is shown above with a gap.
# Sets _onesec_n_lines = total lines printed (used to clear on next redraw).
# ---------------------------------------------------------------------------
_onesec_render_commit() {
  local prefix="$1" input="$2" col_left="$3" col_width="$4"
  local min_chars="$5" show_cursor="$6" header="$7"
  local dim=$'\e[2m' reset=$'\e[0m' green=$'\e[32m'
  local line n=0

  # completed prompt from a previous phase
  if [[ -n "$header" ]]; then
    _onesec_wrap_text "$header" "$col_width"
    for line in "${_onesec_lines[@]}"; do
      printf "%*s%s\n" "$col_left" "" "$line"
    done
    printf "\n"
    n=$(( ${#_onesec_lines[@]} + 1 ))
  fi

  local display="${prefix}${input}"
  [[ "$show_cursor" == 1 ]] && display+="▋"
  _onesec_wrap_text "$display" "$col_width"
  for line in "${_onesec_lines[@]}"; do
    printf "%*s%s\n" "$col_left" "" "$line"
  done

  # status line — check both length and entropy
  local len=${#input}
  _onesec_quality_ok "$input" "$min_chars"
  if (( _onesec_input_ok )); then
    printf "%*s%s\n" "$col_left" "" "${green}↵  to continue${reset}"
  elif (( len >= min_chars )); then
    local red=$'\e[31m'
    if [[ "${input[-1]}" != "." ]]; then
      printf "%*s%s\n" "$col_left" "" "${red}end your sentence with a full stop${reset}"
    else
      printf "%*s%s\n" "$col_left" "" "${red}please write a real sentence${reset}"
    fi
  else
    printf "%*s%s\n" "$col_left" "" "${dim}${len} / ${min_chars}${reset}"
  fi

  _onesec_n_lines=$(( n + ${#_onesec_lines[@]} + 1 ))
}

# ---------------------------------------------------------------------------
# Shared read loop — fills $input until min_chars typed, then returns.
# Caller must have already rendered the initial state.
# ---------------------------------------------------------------------------
_onesec_input_loop() {
  local prefix="$1" col_left="$2" col_width="$3" min_chars="$4" header="$5"
  input=""  # sets caller's local via dynamic scoping in zsh
  local c seq
  while true; do
    read -sk1 c
    case "$c" in
      $'\n'|$'\r')
        _onesec_quality_ok "$input" "$min_chars"
        (( _onesec_input_ok )) && break ;;
      $'\x7f'|$'\b')
        (( ${#input} > 0 )) && input="${input[1,-2]}" ;;
      $'\x03')
        printf '\033[?25h\n'; return 1 ;;
      $'\033')
        read -sk2 -t 0.05 seq 2>/dev/null ;;
      *)
        [[ "$c" == [[:print:]] ]] && input+="$c" ;;
    esac
    printf '\033[%dA\033[J' "$_onesec_n_lines"
    _onesec_render_commit "$prefix" "$input" "$col_left" "$col_width" "$min_chars" 1 "$header"
  done
}

# ---------------------------------------------------------------------------
# Wrapper — pause, prompt, pause, then run
# ---------------------------------------------------------------------------
_onesec_wrap() {
  local cmd="$1"
  local pace="${2:-$_ONESEC_PACE}"
  local cycles="${3:-$_ONESEC_CYCLES}"
  local min_chars="${4:-$_ONESEC_MIN_CHARS}"
  local verb="${5:-$_ONESEC_VERB}"
  shift 5

  # gerund: drop trailing 'e' then add 'ing' (open→opening, install→installing, use→using)
  local gerund
  if [[ "${verb[-1]}" == "e" ]]; then
    gerund="${verb[1,-2]}ing"
  else
    gerund="${verb}ing"
  fi

  local name="${cmd##* }"  # slack → slack, brew install claude-code → claude-code
  local prefix1="I acknowledge that I should not be ${gerund} ${name} because "
  local prefix2="Despite this I am going to continue to ${verb} ${name} because "

  _onesec_breathe "$cycles" "$pace"

  local col_width=$(( COLUMNS > 80 ? 64 : COLUMNS - 8 ))
  local col_left=$(( (COLUMNS - col_width) / 2 ))
  (( col_left < 0 )) && col_left=0

  printf "\n"
  printf '\033[?25l'

  # Phase 1
  local input
  _onesec_render_commit "$prefix1" "" "$col_left" "$col_width" "$min_chars" 1 ""
  _onesec_input_loop "$prefix1" "$col_left" "$col_width" "$min_chars" "" || return 1
  local answer1="$input"

  # Phase 2 — show phase 1 as a locked header above
  local header1="${prefix1}${answer1}"
  printf '\033[%dA\033[J' "$_onesec_n_lines"
  _onesec_render_commit "$prefix2" "" "$col_left" "$col_width" "$min_chars" 1 "$header1"
  _onesec_input_loop "$prefix2" "$col_left" "$col_width" "$min_chars" "$header1" || return 1
  local answer2="$input"

  # Final render — both prompts completed, no cursors
  printf '\033[%dA\033[J' "$_onesec_n_lines"
  local line
  _onesec_wrap_text "$header1" "$col_width"
  for line in "${_onesec_lines[@]}"; do printf "%*s%s\n" "$col_left" "" "$line"; done
  printf "\n"
  _onesec_wrap_text "${prefix2}${answer2}" "$col_width"
  for line in "${_onesec_lines[@]}"; do printf "%*s%s\n" "$col_left" "" "$line"; done
  printf '\033[?25h\n'

  _onesec_breathe "$_ONESEC_CYCLES_AFTER" "$pace"
  printf "\n"

  # for compound commands like "brew install", extract the real executable
  command "${cmd%% *}" "$@"
}

# ---------------------------------------------------------------------------
# Blocked packages — intercept installation via any package manager
# ---------------------------------------------------------------------------
typeset -gA _onesec_blocked_pkgs  # set: pkg_name → 1

_onesec_check_pkg() {
  local base="$1"; shift

  # only intercept install-like subcommands (npx is always a run)
  case "$base" in
    npm|pip|pip3|pipx|brew) [[ "$1" != "install" ]] && return 1 ;;
    yarn|pnpm)             [[ "$1" != "add" && "$1" != "install" ]] && return 1 ;;
    npx) ;;
  esac

  local arg pkg
  for arg in "$@"; do
    # skip flags and subcommands
    [[ "$arg" == -* || "$arg" == "install" || "$arg" == "add" ]] && continue
    # strip version suffix: @scope/pkg@1.2 → @scope/pkg, pkg@latest → pkg, pkg==1.0 → pkg
    pkg="$arg"
    if [[ "$pkg" == @*/*@* ]]; then pkg="${pkg%@*}"
    elif [[ "$pkg" != @* && "$pkg" == *@* ]]; then pkg="${pkg%@*}"
    fi
    pkg="${pkg%%[=<>~!]*}"
    if (( ${+_onesec_blocked_pkgs[$pkg]} )); then
      _onesec_wrap "$base $pkg" "$_ONESEC_PACE" "$_ONESEC_CYCLES" "$_ONESEC_MIN_CHARS" "install" "$@"
      return 0
    fi
  done
  return 1
}

# ---------------------------------------------------------------------------
# Loader — read commands file and register wrapper functions
# ---------------------------------------------------------------------------
_onesec_load() {
  local config="$HOME/.config/one-sec/commands"
  [[ -f "$config" ]] || return

  local line cmd pace cycles min_chars verb _pm

  while IFS= read -r line; do
    # strip comments and blank lines
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"  # ltrim
    [[ -z "$line" ]] && continue

    local -a tokens=(${=line})

    # "package <name>" → add to blocked packages set
    if [[ "${tokens[1]}" == "package" ]]; then
      local pkg="${tokens[2]}"
      pkg="${pkg%\"}"  # strip trailing quote
      pkg="${pkg#\"}"  # strip leading quote
      _onesec_blocked_pkgs[$pkg]=1
      continue
    fi

    # simple command with optional key=value overrides
    cmd="${tokens[1]}"
    pace="$_ONESEC_PACE"
    cycles="$_ONESEC_CYCLES"
    min_chars="$_ONESEC_MIN_CHARS"
    verb="$_ONESEC_VERB"

    local rest="${line#* }"
    if [[ "$rest" != "$line" ]]; then
      [[ "$rest" =~ pace=([0-9.]+) ]]      && pace="${match[1]}"
      [[ "$rest" =~ cycles=([0-9]+) ]]     && cycles="${match[1]}"
      [[ "$rest" =~ min_chars=([0-9]+) ]]  && min_chars="${match[1]}"
      [[ "$rest" =~ verb=([a-z]+) ]]       && verb="${match[1]}"
    fi

    eval "
      function ${cmd}() {
        _onesec_wrap '${cmd}' '${pace}' '${cycles}' '${min_chars}' '${verb}' \"\$@\"
      }
    "
  done < "$config"

  # wrap common package managers (only if there are blocked packages)
  if (( ${#_onesec_blocked_pkgs} > 0 )); then
    for _pm in brew npm npx yarn pnpm pip pip3 pipx; do
      # don't clobber a simple-command wrapper already defined above
      (( ${+functions[$_pm]} )) && continue
      eval "function ${_pm}() { _onesec_check_pkg '${_pm}' \"\$@\" || command ${_pm} \"\$@\"; }"
    done
  fi
}

_onesec_load
