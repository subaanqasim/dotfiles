#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
APPS=false
DRY_RUN=false
LINKS_ONLY=false

usage() {
  cat <<'EOF'
Usage: bash setup/bootstrap.sh [--dry-run] [--links-only] [--apps]

Default: install core tools and apps, Node 24, OpenCode v2, shell managers,
         plugin dependencies, and dotfile links. Existing files are not replaced.
--dry-run    Print the plan and simulate links. No installs or file changes.
--links-only Only link config. Requires GNU Stow.
--apps       Also install the optional work apps in homebrew/Brewfile.apps.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --apps) APPS=true ;;
    --dry-run) DRY_RUN=true ;;
    --links-only) LINKS_ONLY=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

[[ $(uname -s) == Darwin ]] || { echo 'This bootstrap is for macOS.' >&2; exit 1; }
[[ $EUID != 0 ]] || { echo 'Run as your own user, not sudo.' >&2; exit 1; }

if $DRY_RUN; then
  if ! $LINKS_ONLY; then
    echo "Would install Homebrew if missing and bundle $ROOT/homebrew/Brewfile.core."
    $APPS && echo "Would also bundle $ROOT/homebrew/Brewfile.apps."
    echo 'Would clone missing Oh My Zsh, Zinit, and nvm; install Node 24 and OpenCode v2.'
    echo 'Would install wakelock dependencies and create a private WezTerm age key if missing.'
  fi
  if command -v stow >/dev/null 2>&1; then
    bash "$ROOT/scripts/stow.sh" --dry-run
  else
    echo 'Stow is not installed yet. Link simulation will be available after installing it.'
  fi
  exit 0
fi

if $LINKS_ONLY; then
  exec bash "$ROOT/scripts/stow.sh"
fi

# Catch conflicts before downloads when Stow is already available.
if command -v stow >/dev/null 2>&1; then
  bash "$ROOT/scripts/stow.sh" --dry-run
fi
plugin="$ROOT/opencode/.config/opencode/plugins/wakelock"
[[ -f "$plugin/package-lock.json" ]] || {
  echo 'Missing wakelock plugin. Commit the plugin files on the old Mac before cloning.' >&2
  exit 1
}

if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install
  echo 'Finish installing Command Line Tools, then rerun this command.'
  exit 1
fi

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
if ! command -v brew >/dev/null 2>&1; then
  installer=$(mktemp "${TMPDIR:-/tmp}/dotfiles-homebrew.XXXXXX")
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
  /bin/bash "$installer"
  rm -f "$installer"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

# Don't request upgrades, removals, background services, or app overwrites.
brew bundle install --no-upgrade --file="$ROOT/homebrew/Brewfile.core"
$APPS && brew bundle install --no-upgrade --file="$ROOT/homebrew/Brewfile.apps"

# Check every package before creating any dotfile links.
bash "$ROOT/scripts/stow.sh" --dry-run

clone_missing() {
  local url=$1 destination=$2
  shift 2
  if [[ ! -e "$destination" && ! -L "$destination" ]]; then
    mkdir -p "$(dirname "$destination")"
    git clone --depth=1 "$@" "$url" "$destination"
  fi
}
clone_missing https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
clone_missing https://github.com/zdharma-continuum/zinit.git "$HOME/.local/share/zinit/zinit.git"
clone_missing https://github.com/nvm-sh/nvm.git "$HOME/.nvm" --branch v0.40.3

for manager in "$HOME/.oh-my-zsh/oh-my-zsh.sh" "$HOME/.local/share/zinit/zinit.git/zinit.zsh"; do
  [[ -s "$manager" ]] || {
    echo "Incomplete shell-manager directory, missing $manager. Back it up and rerun." >&2
    exit 1
  }
done

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] || { echo 'Missing nvm.sh in ~/.nvm.' >&2; exit 1; }
# nvm is not nounset-safe.
set +u
source "$NVM_DIR/nvm.sh" --no-use
if [[ $(nvm version 24) == N/A ]]; then nvm install 24; fi
if [[ $(nvm version default) == N/A ]]; then nvm alias default 24; fi
nvm use 24
set -u

export PATH="$HOME/.opencode/bin:$PATH"
if ! command -v opencode >/dev/null 2>&1; then
  installer=$(mktemp "${TMPDIR:-/tmp}/dotfiles-opencode.XXXXXX")
  curl -fsSL https://opencode.ai/v2/install -o "$installer"
  /bin/bash "$installer" --no-modify-path
  rm -f "$installer"
fi
case "$(opencode --version)" in
  *v2.*|2.*) ;;
  *) echo 'OpenCode v2 is required. Upgrade your existing CLI using https://opencode.ai/v2/install.' >&2; exit 1 ;;
esac

npm ci --prefix "$plugin" --no-audit --no-fund

# Prevent the current WezTerm config from saving scrollback unencrypted.
if [[ ! -e "$HOME/.resurrect-key.txt" && ! -L "$HOME/.resurrect-key.txt" ]]; then
  (umask 077; age-keygen -o "$HOME/.resurrect-key.txt")
fi

bash "$ROOT/scripts/stow.sh"
echo 'Setup complete. Open a new terminal, then follow the sign-in checklist in README.md.'
