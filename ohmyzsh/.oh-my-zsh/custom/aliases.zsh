alias pn='pnpm'
alias pnx='pnpm dlx'
alias nvim='env TERM=wezterm nvim'
alias ls="eza"
alias ll="eza -alh"
alias tree="eza --tree"
alias cat="bat"
alias f="fzf"
alias hf="history | fzf"
# alias cd="z"
alias zz="z -"
alias python="python3"
alias pip="pip3"
alias dn="dotnet"
alias pu="pulumi"
alias lg="lazygit"
alias nr="npm run"
alias oc="opencode"

hash -d nvim="$HOME/.config/nvim"
nvim="$HOME/.config/nvim"

hash -d code="$HOME/Code"
code="$HOME/Code"

hash -d dot="${DOTFILES_ROOT:-$HOME/Code/dotfiles}"
dot="${DOTFILES_ROOT:-$HOME/Code/dotfiles}"
