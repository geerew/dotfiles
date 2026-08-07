export PATH="/usr/local/bin:/usr/bin:$PATH"

if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Start oh-my-posh
eval "$(oh-my-posh init zsh --config $HOME/.config/ohmyposh/zen.toml)"

# Keybindings
bindkey -e
# bindkey '\e[H' beginning-of-line     # Home key
# bindkey '\e[F' end-of-line           # End key
# bindkey '^[[1;5C' forward-word       # Ctrl+right arrow
# bindkey '^[[1;5D' backward-word      # Ctrl+left arrow
# bindkey '^H'      backward-kill-word # Ctrl+Backspace

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion stylinh
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

# fzf
eval "$(fzf --zsh)"

# PNPM
export PNPM_HOME="/Users/michaelbell/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Aliases
alias ls='ls --color'
alias ll="ls -l"
alias k="kubectl"
alias kx="kubectx"

# Functions
delete_local_git_branches() {
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; return 1; }
    git fetch -p || return 1

    local base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null)
    if [[ -z "$base" ]]; then
        local candidate
        for candidate in origin/main origin/master; do
            git rev-parse -q --verify "$candidate" >/dev/null && { base="$candidate"; break; }
        done
    fi
    [[ -n "$base" ]] || { echo "cannot determine default branch" >&2; return 1; }

    local branch merge_base probe
    git branch -vv | grep ': gone\]' | grep -v '^[*+]' | awk '{ print $1; }' | while read -r branch; do
        if git merge-base --is-ancestor "$branch" "$base"; then
            git branch -d "$branch"
            continue
        fi

        # Squash and rebase merges rewrite commits, so the branch tip is never an
        # ancestor of the base. Replay the branch's cumulative diff as a throwaway
        # commit and let patch-id matching decide whether it already landed.
        merge_base=$(git merge-base "$base" "$branch") || continue
        probe=$(git commit-tree "$branch^{tree}" -p "$merge_base" -m squash-probe) || continue
        if [[ "$(git cherry "$base" "$probe")" == -* ]]; then
            git branch -D "$branch"
        else
            echo "kept $branch: has changes not in $base (force with: git branch -D $branch)"
        fi
    done
}

timer() {
  SECONDS=0
  while true; do
    printf "\r%02d:%02d:%02d" $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))
    sleep 1
  done
}
