# ── Strata Habitus — Fish config ───────────────────────────────────────────

# Starship
starship init fish | source

# direnv
direnv hook fish | source

# Variáveis de ambiente
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx BROWSER chromium

# Aliases úteis
abbr -a ll  'ls -lah'
abbr -a la  'ls -A'
abbr -a vim 'nvim'
abbr -a g   'git'
abbr -a gs  'git status'
abbr -a gc  'git commit'
abbr -a gp  'git push'
abbr -a dotfiles 'cd ~/dotfiles'
abbr -a rebuild 'sudo nixos-rebuild switch --flake ~/dotfiles#'(hostname)

# Sem saudação do Fish
set fish_greeting ""

# Cores do Fish (syntax highlighting alinhado com o Strata)
set -g fish_color_command        1a6a9a  # accent — comandos
set -g fish_color_param          2a2a2a  # argumentos
set -g fish_color_error          b4637a  # erros
set -g fish_color_comment        888888  # comentários
set -g fish_color_quote          286e38  # strings
set -g fish_color_redirection    7bafd4  # redirecionamentos
set -g fish_color_operator       80c4c4  # operadores
set -g fish_color_autosuggestion 444444  # sugestões automáticas
set -g fish_color_valid_path     --underline

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
