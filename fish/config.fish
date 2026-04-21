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
set -g fish_color_command        cf9fff  # accent — comandos
set -g fish_color_param          e0e0e0  # argumentos
set -g fish_color_error          f28779  # erros
set -g fish_color_comment        555555  # comentários
set -g fish_color_quote          d9bc8c  # strings
set -g fish_color_redirection    7bafd4  # redirecionamentos
set -g fish_color_operator       80c4c4  # operadores
set -g fish_color_autosuggestion 444444  # sugestões automáticas
set -g fish_color_valid_path     --underline

