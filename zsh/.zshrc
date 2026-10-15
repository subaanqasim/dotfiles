# Uncomment to profile shell startup, then run zprof.
# zmodload zsh/zprof

# Interactive non-login shells also need Homebrew on PATH.
if ! command -v brew >/dev/null 2>&1; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
if command -v brew >/dev/null 2>&1; then
  export HOMEBREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix)}"
fi
typeset -U path PATH
path=("$HOME/.opencode/bin" "$HOME/.bun/bin" "$HOME/.cargo/bin" $path
  "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.dotnet/tools")
export BUN_INSTALL="$HOME/.bun"
export EDITOR=nvim

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# Starship supplies the prompt instead of an Oh My Zsh theme.
ZSH_THEME=""
plugins=(git ssh-agent)

zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain -q
[[ -n $HOMEBREW_PREFIX ]] && fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

autoload bashcompinit && bashcompinit
[[ -f "$HOMEBREW_PREFIX/etc/bash_completion.d/az" ]] && source "$HOMEBREW_PREFIX/etc/bash_completion.d/az"

# https://starship.rs/
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# Bootstrap installs the manager. Shell startup must not install it implicitly.
if [[ -f "$HOME/.local/share/zinit/zinit.git/zinit.zsh" ]]; then
  source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100
  zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

  ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
  ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
  ZVM_VI_EDITOR=nvim
  zinit ice depth=1
  zinit light jeffreytse/zsh-vi-mode

  # Keep the existing Zinit binary until this Mac installs Homebrew's zoxide.
  if ! command -v zoxide >/dev/null 2>&1; then
    zinit ice wait"2" as"command" from"gh-r" lucid \
      mv"zoxide*/zoxide -> zoxide" \
      atclone"./zoxide init zsh > init.zsh" \
      atpull"%atclone" src"init.zsh" nocompile'!'
    zinit light ajeetdsouza/zoxide
  fi

  export NVM_DIR="$HOME/.nvm"
  export NVM_COMPLETION=true
  export NVM_AUTO_USE=true
  zinit wait lucid light-mode for lukechilds/zsh-nvm
fi

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

[[ -d "$HOMEBREW_PREFIX/opt/postgresql@16/bin" ]] && path=("$HOMEBREW_PREFIX/opt/postgresql@16/bin" $path)
[[ -f "$HOME/.acme.sh/acme.sh.env" ]] && source "$HOME/.acme.sh/acme.sh.env"

# Project Python environments.
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

# Keep local credentials and employer settings outside this repo.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Opt in only after restoring your password store and its GPG key.
if [[ ${DOTFILES_LOAD_SECRETS:-0} == 1 ]] && command -v pass >/dev/null 2>&1; then
  typeset -A _dotfiles_secrets=(
    ANTHROPIC_API_KEY anthropic/api-key
    TAVILY_API_KEY tavily/api-key
    GROQ_API_KEY groq/api-key-menza
    GEMINI_API_KEY gemini/api-key-menza
    SCHEMATIC_API_KEY schematic/api-key
    SCHEMATIC_API_KEY_PROD schematic/api-key-prod
  )
  for _name _entry in "${(@kv)_dotfiles_secrets}"; do
    [[ -n ${(P)_name} ]] && continue
    if _secret=$(pass show "$_entry" 2>/dev/null); then
      export "$_name=${_secret%%$'\n'*}"
    fi
  done
  unset _dotfiles_secrets _name _entry _secret
fi

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
