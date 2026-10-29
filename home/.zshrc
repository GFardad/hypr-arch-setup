
# Enable Powerlevel10k instant prompt. Must be FIRST so the prompt appears
# immediately and the rest of .zshrc (incl. `fetch`) loads behind it.


fetch

# ۲. تنظیمات Oh My Zsh و پلاگین‌ها
export ZSH="$HOME/.oh-my-zsh"
# export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export PATH="$HOME/.local/bin:$PATH"
export PYTHONPATH="${PYTHONPATH}:$HOME/Documents/Python-Shit/"
export FZF_DEFAULT_OPTS="--preview 'bat --style=numbers --color=always --line-range :500 {}'"
fpath=(/usr/share/zsh/site-functions /usr/local/share/zsh/site-functions $fpath)
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
ZSH_THEME="powerlevel10k/powerlevel10k"


plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    sudo
)

# Skip compinit's security rescan (compaudit): our fpath dirs are all secure
export ZSH_DISABLE_COMPFIX=true
source $ZSH/oh-my-zsh.sh




# unifetch (after oh-my-zsh to not break p10k instant prompt)
# Delay fastfetch so p10k instant prompt isn't broken by startup I/O.
# Run fastfetch once after the prompt is fully ready.
autoload -Uz add-zsh-hook

# ۳. مقداردهی ابزارهای هوشمند
# zoxide must run in the main shell so z/zi functions are available
eval "$(zoxide init zsh)" 2>/dev/null

# Async init for plugins that don't need exported functions
_async_init_plugins() {
  eval "$(atuin init zsh --disable-up-arrow 2>/dev/null)" 2>/dev/null
  eval "$(thefuck --alias 2>/dev/null)" 2>/dev/null
  source <(fzf --zsh) 2>/dev/null
}
(_async_init_plugins &) 2>/dev/null
unset -f _async_init_plugins

# ۴. تنظیمات FZF

HISTFILE=~/.zsh_history
HISTSIZE=50000000
SAVEHIST=2000000000

setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt appendhistory
setopt share_history
unsetopt hist_ignore_space
unsetopt nomatch


bindkey '^H' backward-kill-word
bindkey '^[[3;5~' kill-word
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

aria-batch() {
    aria2c -x 8 -s 8 -k 1M --file-allocation=none -j 5 -i "$1"
}

# تابع برای کسانی که می‌خواهند سریع کارشان راه بیفتد
lazy-git() {
    git add .
    git commit -m "Update: $(date +'%Y-%m-%d %H:%M')"
    git push
    echo "\033[1;32m>> Changes pushed to cloud successfully!\033[0m"
}


topdir() {
    local target="${1:-.}"
    # گرفتن مسیر مطلق واقعی پوشه
    local abs_path
    abs_path=$(realpath "$target" 2>/dev/null || (cd "$target" 2>/dev/null && pwd) || echo "$target")

    echo "5 Top biggest folder in : -> $abs_path <-"
    # حذف خط اول (کل پوشه) و گرفتن ۵ خط بعدی
    du -hx --max-depth=1 "$target" 2>/dev/null | sort -hr | tail -n +2 | head -n 5
}

# جایگزین هوشمند برای man
help-me() {
    if [[ -z "$1" ]]; then
        echo "Wahts in your mind?"
        return
    fi

    # اولویت ۱: نمایش مثال‌های کاربردی سریع
    if tldr "$1" &>/dev/null; then
        tldr "$1"
        echo -e "\n\e[1;34m[ برای جزئیات بیشتر: man $1 ]\e[0m"
    # اولویت ۲: جستجوی تعاملی اگر دستور پیچیده باشد
    elif navi --query "$1" &>/dev/null; then
        navi --query "$1"
    # اولویت ۳: برگشت به man با نمایشگر مدرن bat
    else
        man "$1"
    fi
}


fcode() {
  local file
  file=$(fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
  [[ -n "$file" ]] && code "$file"
}


ENABLE_CORRECTION="true"

alias td="topdir"
alias g-up='lazy-git'
alias zsh="c ~/.zshrc"
alias szsh="source ~/.zshrc"
alias vpnon="sudo openvpn --config $HOME/VPN/main.ovpn --daemon"
alias vpnoff="sudo pkill openvpn"
alias l='ls -l'
alias la='ls -a'
alias lsa='ls -ah'
# alias c='systemd-run --user --unit=myjob pycharm'  # pycharm is not installed on this machine
alias aria='aria-download'
alias list-big='du -sh * | sort -h'
alias cls='printf "\033[2J\033[3J\033[H"'
alias br='broot -dhp' # نمایش سایز و فایل‌های مخفی
alias tree='br'
alias qr="qrencode -t ansiutf8"
alias pa="curl -T- https://pasted.ir <"
alias ssh="kitty +kitten ssh"
alias c="pycharm -e"
alias cf="pycharm"
# alias load_api='eval "$(gpg --decrypt --quiet --use-agent ~/.my_api_keys.gpg)"'

alias -g G='| grep --color=auto'
alias -g L='| less'
alias -g H='| head'
alias -g T='| tail'
alias -g NE='2> /dev/null' # مخفی کردن ارورها
# بارگذاری خودکار کلیدها بدون درخواست تایید مجدد
# /usr/bin/keychain --nogui --quiet $HOME/.ssh/id_ed25519
# source $HOME/.keychain/$HOST-sh


[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# source ~/.secrets
[[ -f "$HOME/.config/broot/launcher/bash/br" ]] && source "$HOME/.config/broot/launcher/bash/br"
export PATH=$PATH:$HOME/go/bin
export PATH="/home/gfardad/.bun/bin:$PATH"

# SETTHING FOR DOWNLOADING AND COMPILEING
export GOPROXY=direct
export GOSUMDB=off
export UV_INDEX_URL="https://pypi.org/simple"
export GROFF_NO_SGR=1

# >>> conda initialize >>>
# Lazy-init: `conda shell.zsh hook` spawns a whole Python interpreter on EVERY
# shell start (4-8 s), and this file is sourced by non-interactive shells too.
# Sourcing conda.sh is instant, so we defer it until conda is first used.
if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
    conda() {
        unset -f conda
        . "/opt/miniconda3/etc/profile.d/conda.sh"
        conda activate base   # drop this line for no auto-activate
        conda "$@"
    }
else
    export PATH="/opt/miniconda3/bin:$PATH"
fi
# <<< conda initialize <<<


[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"


# FIX: Proper zsh completion cache configuration
export ZSH_COMPDUMP=$HOME/.zsh/cache/.zcompdump-$HOST
mkdir -p $HOME/.zsh/cache

# FIX: Disable problematic completion functions that cause comptags errors
# zstyle ':completion:*' use-compctl false
# zstyle ':completion:*' verbose false
# zstyle ':completion:*' show-completer

# FIX: Use cache for completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $HOME/.zsh/cache

# FIX: Don't try to use non-existent commands
zstyle ':completion:*:functions' ignored-patterns '_*'

[[ -f ~/.zsh/completion.zsh ]] && source ~/.zsh/completion.zsh

# bun completions
[ -s "/home/gfardad/.bun/_bun" ] && source "/home/gfardad/.bun/_bun"
export PATH=/opt/cuda/bin:$PATH

# === OpenCode Review (OCR) ===
# Provider/model/key live in ~/.opencodereview/config.json (voke-api route).
# Do NOT set OCR_LLM_* here: env vars override the config file.
# (.npm-global/bin already added above; no need to repeat it here.)

# pnpm
export PNPM_HOME='/home/gfardad/.local/share/pnpm'
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end


# BEGIN opam configuration
# This is useful if you're using opam as it adds:
#   - the correct directories to the PATH
#   - auto-completion for the opam binary
# This section can be safely removed at any time if needed.
[[ ! -r '/home/gfardad/.opam/opam-init/init.zsh' ]] || source '/home/gfardad/.opam/opam-init/init.zsh' > /dev/null 2> /dev/null; true
# END opam configuration

# --- WhatHappened? (wh) shell integration -------------------------------------
# Emits OSC 133 marks + the JSONL side-channel so `wh wrap zsh` knows the exact
# command text, cwd and exit code. No-op unless the shell runs under `wh wrap`.
[[ -f "$HOME/.local/share/wh/hooks/zsh" ]] && source "$HOME/.local/share/wh/hooks/zsh"
# --- end WhatHappened? -------------------------------------------------------

# === Lazy `extract` (was oh-my-zsh plugins/extract): loads on first use ===
alias x=extract
extract() {
  unfunction extract
  source "$ZSH/plugins/extract/extract.plugin.zsh"
  extract "$@"
}

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi