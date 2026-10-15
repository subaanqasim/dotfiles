# Migration notes

## What the audit found

The source Mac was checked on 13 October 2026. Most active config was already linked to this repo, but these files were missing and are now included:

- `~/.zprofile`, including Homebrew and OrbStack shell initialization.
- `~/.ssh/config`, without private keys, agent sockets, or known hosts.
- `~/.npmrc`.
- Neovim's `lazyvim.json`, which selects the LazyVim extras.
- OpenCode's v2 `cli.json` and older `tui.json` UI settings.

Shell paths and Git credential-helper paths no longer assume the username `subaanqasim` or Apple Silicon. Shell startup tolerates missing optional tools and doesn't read secrets unless enabled locally. npm may warn about `auto-install-peers`, which is a pnpm setting preserved from the source Mac.

OpenCode on the source Mac is v2.0.28. The Homebrew tap currently installs v1.19.0, so bootstrap uses `https://opencode.ai/v2/install` with `--no-modify-path`. It leaves an existing v2 CLI alone and refuses an existing v1 CLI rather than silently replacing it. The current OpenCode config and local wakelock plugin are left intact. Bootstrap installs that plugin's npm dependencies.

The original `codex/.codex/config.toml` contains desktop-generated runtime paths, plugin caches, and trusted worktree paths. Bootstrap instead links `codex-portable/.codex/config.toml`. Set up Codex desktop integrations on the new Mac rather than copying runtime directories or trust approvals. Global skills come from `agents/.agents/skills`. Worktrunk's saved hook approvals are not linked on a new machine.

Codex desktop may write generated fields into its linked config again. Review those diffs and keep runtime paths and project trust out of the portable config when committing.

## Git and SSH

The global config enables signed commits. A missing signing key will stop commits, so set this up before starting work:

```sh
# Fresh laptop only. Do not overwrite an existing key.
ssh-keygen -t ed25519 -C 'subaan.qasim@gmail.com' -f ~/.ssh/subaanqasim
ssh-add --apple-use-keychain ~/.ssh/subaanqasim
gh auth login
gh ssh-key add ~/.ssh/subaanqasim.pub --title "Work Mac authentication" --type authentication
gh ssh-key add ~/.ssh/subaanqasim.pub --title "Work Mac signing" --type signing
```

Git now points at the `.pub` signing key and asks ssh-agent to sign with the private key. For Sina Health, provision `~/.ssh/subaan-sh` separately if you still need that identity. Don't move personal private keys to an employer-owned Mac unless policy allows it. New per-device keys are preferable.

The default Git identity is still `subaan.qasim@gmail.com`. To use a different identity everywhere on the work Mac, create `~/.gitconfig.local`:

```gitconfig
[user]
    name = Subaan Qasim
    email = you@company.example
    signingkey = ~/.ssh/work.pub
[core]
    sshCommand = ssh -i ~/.ssh/work
```

For separate identities, use `includeIf` with your employer's checkout directory instead. The tracked SSH config retains the source Mac's Hifdh Tracker host aliases and tunnels, but they won't work until the relevant keys exist. Put new hosts in `~/.ssh/config.local`.

Git configuration doesn't restore GitHub or Azure logins. Authenticate those accounts independently. Check effective settings from inside each project:

```sh
git config --show-origin --get user.email
git config --show-origin --get user.signingkey
ssh -T git@github.com
```

Local signed-commit verification also needs a trusted `gpg.ssh.allowedSignersFile`; don't disable signing just to bypass a missing key.

## Keep private state separate

Do not commit `~/.ssh` keys, `~/.gnupg` private keyrings, `~/.password-store`, `~/.resurrect-key.txt`, shell histories, `.env` files, cloud credentials, or agent auth/session databases. Restore only what is approved through an encrypted transfer or password manager. The bootstrap doesn't read or transfer any of these.

OpenCode's `service.json` contains a per-device credential and is not copied. GitHub's `hosts.yml`, Codex auth, Claude/Pi auth, and cloud CLI sessions stay local too.

If you migrate encrypted WezTerm workspace state, restore its original age key before running bootstrap. A newly generated key cannot decrypt old state. Bootstrap never overwrites an existing key. The current WezTerm encryption command still uses `/opt/homebrew/bin/age`; Intel Macs need that path changed to `/usr/local/bin/age`. Its pending edits were intentionally preserved.

The optional `gpg/` package uses a ten-year passphrase-cache timeout until the agent exits. It is not part of the default bootstrap. Review that policy before using it on a work machine.

## Other config and apps

- The active Oh My Zsh loader is upstream code. Bootstrap clones upstream and links only your custom aliases, not the old tracked loader.
- The source Mac's Neovim Lua config matches this repo except that the repo also contains `csharp.lua`. That file currently returns an empty table and contains only commented experiments, so it doesn't activate C# plugins. Language SDKs beyond the core Go/Rust/Python/Node tools remain optional.
- rcmd has been migrated to v3.6.4, with all 14 app assignments retained. Its native YAML is now Stowed and v3 is installed by the core Brewfile. The Classic Hammerspoon helper is disabled; its script and a private init backup remain on the source Mac, but Hammerspoon is not installed on the new Mac.
- OpenCode has an untracked `commands/rams.md` design-review command. It was not required for the minimal install and has not been copied. Add it separately if you still use it.
- VS Code extensions are captured in the inventory, but User settings and keybindings live under `~/Library/Application Support/Code/User`. Use Settings Sync or export reviewed files. The tracked `vscode/.vscode/extensions/extensions.json` is not a complete user-settings backup.
- Raycast's encrypted export is refreshed from the Desktop backup and still needs manual importing. rcmd uses its linked v3 YAML; the Classic plist and helper are kept only for rollback and aren't Stowed. Vimium exports are retained for manual setup. iTerm2 is no longer used; its old files are archived and excluded from bootstrap. See [utilities](utilities.md) for rcmd instructions and recommendations.
- GUI apps installed outside Homebrew do not appear in `brew bundle dump`. `Brewfile.apps` captures the common work apps found in `/Applications`; Adobe tools, monitor drivers, personal apps, and manually distributed agent desktops are intentionally omitted.
- Other hidden directories checked included nvm, Oh My Zsh, the password store, and Pulumi templates. Don't copy those wholesale. Project-local agent config and `.env` files should stay with each project or its secret manager.
- Selected Dock and hot-corner preferences now have an opt-in export/apply script. See [macOS settings](macos-settings.md). Bootstrap does not apply it. Databases, OrbStack volumes, project checkouts, unpushed commits, browser profiles, licenses, and other macOS keyboard/privacy settings are separate migrations. No database service is started by bootstrap.

The refreshed Brewfile reflects Homebrew's installed-state dump, including current App Store IDs, VS Code extensions, and detected Go/Cargo/npm tools. The updater also adds installed tap formulae and leaves omitted by the dump, including the QMK and database tools. Other dependencies are resolved by Homebrew rather than listed individually.

Homebrew reported stale circular dependency metadata for `libtiff` and `webp` while dumping the inventory. The dump succeeded. No packages were uninstalled or repaired during this audit.
