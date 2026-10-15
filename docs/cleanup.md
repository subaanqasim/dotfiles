# Shell cleanup and legacy config

## Removed from the active setup

- tmux is no longer installed or stowed by bootstrap. The snapshot added during this migration was removed. The existing laptop's installed tmux and original `~/.tmux.conf` were left alone.
- iTerm2 was already excluded from bootstrap. Its old tracked config is retained as an archive, not imported onto the new Mac. Its `.hushlogin` file suppresses login messages in any terminal, not just iTerm2.
- The Bash Anaconda initializer pointed at `~/opt/anaconda3/bin/conda`, which no longer exists. That dead initializer was removed. Bash config is not part of the fresh-Mac Stow list.
- Stock Oh My Zsh comments, old commented Pure prompt setup, and misleading installer comments were removed from `.zshrc`.
- The four stock Zinit annexes were removed from the startup declarations. The current plugin declarations don't use their extra build, patch, or monitor features. Zinit and the actual shell plugins remain.

The full Brewfile is still an installed-state inventory, so it can still list tools you no longer want. Use `Brewfile.core` for the intended fresh-Mac setup, not the entire inventory.

## Review before removing

The shell-history check counted command names only, without exporting arguments or raw history. It is supporting evidence, not a complete usage audit. Commands invoked by aliases, editors, scripts, cron, or another shell may not show up.

| Candidate | Evidence and recommendation |
| --- | --- |
| Azure completion and Git Azure aliases | No direct `az` history matches, but Git's `pr` and `repo` aliases still invoke Azure. Remove these if you no longer use Azure Repos. |
| .NET paths, `dn`, and old SDKs | No direct `dotnet` or `dn` history matches. `dotnet-svcutil` still exists under `~/.dotnet/tools`. Keep only if an existing project requires it. The old SDKs are not in the default install. |
| Pulumi alias `pu` | One direct Pulumi history match in June 2026. Drop the alias and tooling if those older infrastructure projects are retired. |
| acme.sh shell initialization | Its env file exists, but there are no direct `acme.sh` matches. Certificate renewal may run automatically, so check renewal jobs before removing the installation. |
| PostgreSQL 16 PATH override | This selects an optional client version. Remove it if you use only OrbStack/container clients or no longer need that version. No direct `psql` matches were found. |
| Poetry/pipx leftovers | `~/.local/bin/poetry` remains, but neither command has direct history matches. Keep the generic `~/.local/bin` PATH even if Poetry is retired. |
| Neovim C# stub | `lua/plugins/csharp.lua` is an empty plugin table with commented experiments. It can be removed without disabling any active plugin. |
| Forced Neovim TERM alias | `alias nvim='env TERM=wezterm nvim'` duplicates WezTerm's `config.term = "wezterm"`. It can be dropped if it isn't fixing a specific terminal problem; forcing that TERM in another terminal can misdescribe its capabilities. |
| Old tracked Oh My Zsh loader | Bootstrap ignores `ohmyzsh/.oh-my-zsh/oh-my-zsh.sh` and clones upstream instead. Your current Mac also uses a separate upstream loader, so this archived copy isn't needed for the new setup. |
| Starship language-icon sections | These are cosmetic presets, not installers or evidence that you use those languages. Remove them only to shorten the config. |
| Oh My Zsh `ssh-agent` plugin | macOS has its own SSH agent and Keychain integration. This plugin may be redundant, but test authentication and SSH commit signing before switching to the native agent. |

## Keep for now

- Node/nvm is used by tooling even when you rarely run `node` directly. The nvm and Homebrew Node installations have different roles; Homebrew dependencies may need its copy.
- pyenv has recorded use in July 2026 and existing Python environments. It isn't the same thing as the removed Anaconda hook.
- Bun and Worktrunk have substantial recent recorded use.
- `pass` has recorded use in July 2026 and depends on GPG. Keep GPG if you still need those encrypted secrets.
- Oh My Zsh, Zinit, and Starship currently serve different roles: built-in plugins and aliases, third-party shell plugins, and the prompt. Removing one requires a deliberate replacement, not just deleting duplicate-looking names.
- The Zinit-managed zoxide fallback supports the current Mac until Homebrew's zoxide is installed. The new Mac uses the Homebrew copy.

## What is GPG's keybox?

A keybox is a public-key store. Without `keyboxd`, modern GPG can keep public keys in `~/.gnupg/pubring.kbx`.

Your `gpg/.gnupg/common.conf` enables `use-keyboxd`. That tells GPG to use the `keyboxd` background service and its database instead. The source Mac has `~/.gnupg/public-keys.d/pubring.db`, so that setting corresponds to a real key store.

Neither is a password manager or a place to put API keys. GPG private keys are stored separately under `~/.gnupg/private-keys-v1.d/`, or on hardware if you use a token. `pass` keeps its encrypted entries in `~/.password-store/` and asks GPG to decrypt them.

Your Git config uses SSH signing, not GPG signing. GPG is relevant to `pass` here, not required for your Git commits.

Leave the keybox backend alone while you use `pass`. Switching `use-keyboxd` on or off does not itself move existing keys between stores. Don't delete or commit the key database, private keys, lock files, or password-store contents as a cleanup step. For a new laptop, use an approved encrypted key transfer and GPG's import/export commands rather than treating a copied public-key database as a complete backup.

The ten-year passphrase-cache timeout in `gpg-agent.conf` is a separate policy. It is not required by keyboxd and isn't installed by bootstrap. Review it for the work laptop rather than copying it automatically.

Official GPG references:
- https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration.html
- https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
