# Dotfiles

## Set up a new Mac

Check your employer's rules for personal accounts, AI tools, VPNs, and app installs first. Commit and push the config you want from the old Mac, including any updates to the OpenCode wakelock plugin.

1. Install Apple's Command Line Tools and wait for the installer to finish:

   ```sh
   xcode-select --install
   ```

2. Clone and run the bootstrap as your own user, not with `sudo`:

   ```sh
   mkdir -p ~/Code
   git clone https://github.com/subaanqasim/dotfiles.git ~/Code/dotfiles
   cd ~/Code/dotfiles
   bash setup/bootstrap.sh
   ```

   Homebrew may ask for your Mac password. Downloads require internet access.

The default installs the tools in [Brewfile.core](homebrew/Brewfile.core), including Neovim, Git, Node 24 through nvm, Bun, pnpm, OpenCode v2, Codex CLI, Worktrunk, WezTerm nightly, Raycast, rcmd v3, VS Code, OrbStack, LinearMouse, and Tailscale. It links your shell config, aliases, Git/SSH settings, Neovim extras, agent skills, OpenCode config, and rcmd's native YAML. It also creates a private age key so WezTerm doesn't save scrollback unencrypted.

```sh
bash setup/bootstrap.sh --dry-run    # Print the plan and check links if Stow is installed
bash setup/bootstrap.sh --links-only # Link config without installing anything
bash setup/bootstrap.sh --apps       # Also install optional work apps
```

Reruns don't request Homebrew upgrades and skip existing shell-manager clones. Homebrew may still upgrade a dependency required by a new install. The script doesn't remove packages, start database services, change macOS defaults, or replace config files. Shell plugins download on first launch. Open Neovim once to install its plugins, then run `:checkhealth` and `:Mason` for language tools.

If Stow reports a conflict, move only the reported file to a private backup and rerun. Don't use `stow --adopt`, which can put laptop config or credentials into this repo. The bootstrap deliberately refuses to replace an existing Codex config.

## Finish setup

- Open a new terminal. Sign in with `gh auth login`, `codex login`, and `opencode auth login`. Connect MCP accounts inside the agents as needed. Railway can be signed in with `railway login` when needed.
- Set up your Git identity and SSH signing key before committing. The default identity is personal; `~/Code/sina-health/` uses the existing Sina Health identity. Use `~/.gitconfig.local` for your new employer's overrides. See [migration notes](docs/migration.md#git-and-ssh).
- Open Tailscale and sign into the approved tailnet. Open OrbStack once. Open rcmd and grant Accessibility and Screen Recording access during onboarding. Grant other requested permissions to Raycast and LinearMouse as needed. Enable VS Code Settings Sync if you use it.
- Keep API keys, SSH/GPG private keys, password stores, and account sessions outside this repo. Secret loading is now opt-in. After restoring `pass` and its GPG key, add `export DOTFILES_LOAD_SECRETS=1` to `~/.zshrc.local` if you want the old API-key exports.
- Import Raycast's refreshed `raycast/.config/raycast/subaan.rayconfig` with **Import Settings & Data** and your export passphrase. Select only the data categories appropriate for work. rcmd v3 reads its linked YAML; don't run the old Classic plist importer for the normal setup. See [utility setup](docs/utilities.md) for details.

## Optional installs and upkeep

Dock auto-hide, zero-delay animations, and hot corners are captured separately. Preview and apply them only when wanted:

```sh
bash scripts/macos-settings.sh apply --dry-run
bash scripts/macos-settings.sh apply
killall Dock
```

Bootstrap does not apply macOS preferences. See [macOS settings](docs/macos-settings.md) for refreshing the export, backups, and limitations.

`homebrew/Brewfile` is the refreshed installed-state inventory, not the minimal setup. It contains personal App Store apps, duplicated product generations, and old .NET SDK casks that may no longer install. Review it before using it. `Brewfile.apps` adds common work apps without those SDKs or App Store sign-ins.

```sh
# Refresh the source Mac's Homebrew inventory. Review the diff before committing.
bash scripts/update-brewfile.sh

# Install individual optional tools rather than the entire personal inventory.
brew install azure-cli awscli supabase/tap/supabase

# Restore captured VS Code extensions if Settings Sync isn't being used.
brew bundle list --file=homebrew/Brewfile --vscode | while IFS= read -r extension; do
  code --install-extension "$extension"
done

# Check links without changing them, or run the isolated tests.
bash scripts/stow.sh --dry-run
bash tests/setup.sh
```

Never run `brew bundle cleanup` against the core Brewfile on your existing laptop. It would remove tools outside the minimal list. More gaps and migration decisions are in [docs/migration.md](docs/migration.md). tmux and iTerm2 are excluded from the setup; [cleanup notes](docs/cleanup.md) list other possible leftovers and explain GPG's keybox.
