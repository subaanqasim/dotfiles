# for profiling zsh load speed -> uncomment line below then run `zprof` in the shell for the output
# zmodload zsh/zprof


# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH


# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

ZSH_THEME=""


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git ssh-agent)

# ssh
# ssh-add --apple-load-keychain -q
zstyle :omz:plugins:ssh-agent ssh-add-args --apple-load-keychain -q
FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

source $ZSH/oh-my-zsh.sh

autoload bashcompinit && bashcompinit
source $(brew --prefix)/etc/bash_completion.d/az



# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# https://starship.rs/
eval "$(starship init zsh)"

# pnpm
export PNPM_HOME="/Users/subaanqasim/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end


### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# https://github.com/sindresorhus/pure
# zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
# zinit light sindresorhus/pure

ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=100

zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
      zdharma-continuum/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
      zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
      zsh-users/zsh-completions


# https://github.com/jeffreytse/zsh-vi-mode
ZVM_LINE_INIT_MODE=$ZVM_MODE_INSERT
ZVM_VI_INSERT_ESCAPE_BINDKEY=jj
# ZVM_CURSOR_STYLE_ENABLED=false
# ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
# ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
# ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_UNDERLINE
ZVM_VI_EDITOR=nvim
zinit ice depth=1
zinit light jeffreytse/zsh-vi-mode

zinit ice wait"2" as"command" from"gh-r" lucid \
  mv"zoxide*/zoxide -> zoxide" \
  atclone"./zoxide init zsh > init.zsh" \
  atpull"%atclone" src"init.zsh" nocompile'!'
zinit light ajeetdsouza/zoxide

# nvm
export NVM_COMPLETION=true
# export NVM_SYMLINK_CURRENT="true"
export NVM_AUTO_USE=true
zinit wait lucid light-mode for lukechilds/zsh-nvm


# bun completions
[ -s "/Users/subaanqasim/.bun/_bun" ] && source "/Users/subaanqasim/.bun/_bun"

# export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="/Users/subaanqasim/.cargo/bin":$PATH
export PATH="$PATH:/Users/subaanqasim/.local/bin"
. "/Users/subaanqasim/.acme.sh/acme.sh.env"
export PATH=$PATH:$HOME/go/bin


# Created by `pipx` on 2024-04-19 13:51:30
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export ANTHROPIC_API_KEY=$(pass show anthropic/api-key)
export TAVILY_API_KEY=$(pass show tavily/api-key)
export GROQ_API_KEY=$(pass show groq/api-key-menza)
export GEMINI_API_KEY=$(pass show gemini/api-key-menza)
