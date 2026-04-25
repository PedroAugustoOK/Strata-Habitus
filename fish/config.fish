# ── Strata Habitus — Fish config ───────────────────────────────────────────

# Starship
starship init fish | source

# direnv
direnv hook fish | source

# zoxide
zoxide init fish | source

# Variáveis de ambiente
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER chromium

# Aliases úteis
abbr -a ls  'eza --icons'
abbr -a ll  'eza -lah --icons --git'
abbr -a la  'ls -A'
abbr -a cat 'bat'
abbr -a vim 'nvim'
abbr -a g   'git'
abbr -a gs  'git status'
abbr -a gc  'git commit'
abbr -a gp  'git push'
abbr -a dotfiles 'cd ~/dotfiles'
abbr -a rebuild 'sudo nixos-rebuild switch --flake path:$HOME/dotfiles#'(hostname)

# Sem saudação do Fish
set fish_greeting ""

if test -f ~/dotfiles/generated/fish/theme.fish
    source ~/dotfiles/generated/fish/theme.fish
end

function codex-safe
    set -l old_intr (stty -a | string match -r 'intr = [^;]+' | string replace 'intr = ' '')
    stty intr '^]'
    codex $argv
    if test -n "$old_intr"
        stty intr "$old_intr"
    else
        stty intr '^C'
    end
end

function bt-on
    sudo systemctl start bluetooth.service
    if not pgrep -x blueman-applet >/dev/null
        nohup blueman-applet >/dev/null 2>&1 &
    end
end

function bt-off
    pkill -x blueman-applet >/dev/null 2>&1
    sudo systemctl stop bluetooth.service
end

function print-on
    sudo systemctl start cups.service
end

function print-off
    sudo systemctl stop cups.service
end

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
