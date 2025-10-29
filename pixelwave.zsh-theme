
setopt prompt_subst
typeset -ga PW_PALETTE=( 'ff0066' 'ff5f00' 'ffd500' 'aaff00' '00ff88' '00ccff' '6a5cff' 'ff33cc' )

pw_bar() {
  # Rainbow "pixel bar" across the terminal width using upper blocks
  local width=${1:-$COLUMNS}
  local -a colors=(${PW_PALETTE[@]})
  local ncolors=${#colors}
  local out="" c piece extra i
  (( piece = width / ncolors, extra = width - piece * ncolors ))
  for c in $colors; do
    for ((i=1; i<=piece; i++)); do out+=$(printf "%%F{#%s}▀%%f" "$c"); done
  done
  for ((i=1; i<=extra; i++)); do out+=$(printf "%%F{#%s}▀%%f" "${colors[-1]}"); done
  print -Pnr -- "$out"
}

pw_path_full() {
  # Full path; if inside $HOME, prefix with ~/
  local p=$PWD
  if [[ $p == $HOME ]]; then
    print -r -- "~"
  elif [[ $p == $HOME/* ]]; then
    print -r -- "~/${p#$HOME/}"
  else
    print -r -- "$p"
  fi
}

pw_git() {
  # Returns a prompt segment string (not printed) with git branch + marks
  command -v git >/dev/null 2>&1 || return
  git rev-parse --is-inside-work-tree &>/dev/null || return

  local branch; branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  local marks=""
  git diff --no-ext-diff --quiet --exit-code          || marks+="✚"   # unstaged
  git diff --no-ext-diff --cached --quiet --exit-code || marks+="●"   # staged
  [[ -n "$(git ls-files --others --exclude-standard 2>/dev/null)" ]] && marks+="…"

  # Double % so outer print -P can interpret later
  printf "%%F{#8be9fd}%%f %%F{#f8f8f2}%s%%f%%F{#ff79c6}%s%%f" "$branch" "$marks"
}

# --- Precmd paints the two header lines -------------------------------------

_pw_precmd() {
  # 1) exactly one empty line
  print -r -- ""

  # 2) the rainbow bar (no trailing newline inside function)
  pw_bar $COLUMNS
  print -r -- ""   # move to next line

  # 3) second line:
  #    - prefix (▛▞▞▟ + user@host) through lolcat
  #    - then the full/~/ path in bright white (not through lolcat)
  #    - then git segment (if present)
  local prefix fullpath gitseg
  prefix="██▓▓▒▒░░  $USER@${HOST%%.*}  "
  printf "%s" "$prefix" | /usr/games/lolcat -f -p 1.0 -F 0.2 --seed 6131

  fullpath=$(pw_path_full)
  print -Pnr -- "%F{#ffffff}${fullpath}%f"

  gitseg=$(pw_git)
  [[ -n "$gitseg" ]] && print -Pnr -- " ${gitseg}"

  print -r -- ""  # end of the second line
}

# Hook precmd in a safe way (coexists with other oh-my-zsh hooks)
autoload -Uz add-zsh-hook
add-zsh-hook precmd _pw_precmd

# --- The interactive prompt (third line) ------------------------------------

# Green ❯ on success, red ❯ on error
PROMPT='%(?.%F{#50fa7b}.%F{#ff5555})❯%f '
RPROMPT='%F{#999999}%*%f'
