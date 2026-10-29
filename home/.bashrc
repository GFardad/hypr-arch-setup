export MOZ_WEBRENDER=0
export OPENCODE_YOLO=true
export LD_LIBRARY_PATH="/opt/hiddify-desktop/lib:$LD_LIBRARY_PATH"
# Broken reference removed: .jetbrains.vmoptions.sh points to missing /home/gfardad/Projects/PyCharm/ja-netfilter/vmoptions/

# Created by `pipx` on 2026-09-12 01:58:30
export PATH="$PATH:/home/gfardad/.local/bin"

# opam environment (sourced for bash used by non-interactive tools like topgrade)
[[ ! -r '/home/gfardad/.opam/opam-init/init.sh' ]] || source '/home/gfardad/.opam/opam-init/init.sh' > /dev/null 2>&1

# pnpm global bin directory
export PNPM_HOME="$HOME/.local/share/pnpm"
[[ -d "$PNPM_HOME" ]] && case ":$PATH:" in
    *":$PNPM_HOME/bin:"*) ;;
    *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
___MY_VMOPTIONS_SHELL_FILE="${HOME}/.jetbrains.vmoptions.sh"; if [ -f "${___MY_VMOPTIONS_SHELL_FILE}" ]; then . "${___MY_VMOPTIONS_SHELL_FILE}"; fi
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# --- WhatHappened? (wh) shell integration -------------------------------------
# No-op unless the shell runs under `wh wrap bash`.
[[ -f "$HOME/.local/share/wh/hooks/bash" ]] && source "$HOME/.local/share/wh/hooks/bash"
# --- end WhatHappened? -------------------------------------------------------
