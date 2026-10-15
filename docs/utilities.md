# Everyday utilities

## Raycast

The tracked `raycast/.config/raycast/subaan.rayconfig` was refreshed from the Desktop export `Raycast-X-2026-10-13 11.38.00.rayconfig` on 13 October 2026.

On the new Mac, open Raycast and run **Import Settings & Data**. Select this file and enter the export passphrase. Keep that passphrase in your password manager, not in Git.

Raycast v2 exports are encrypted and can contain clipboard history, chats, notes, snippets, quicklinks, and extension settings. Only import the categories you want on an employer-owned Mac. The bootstrap installs Raycast but does not import personal data automatically.

Official instructions: https://manual.raycast.com/import-export

## rcmd

### Current setup

The source Mac has rcmd 3.6.4 installed through Homebrew. All 14 Classic app assignments migrated, and v3's permissions and keyboard diagnostics passed. Bootstrap now installs v3 and Stows `rcmd/.config/rcmd/config.yaml` to `~/.config/rcmd/config.yaml` before you open the app.

On the new Mac:

1. Run the normal bootstrap.
2. Open rcmd and complete onboarding, granting Accessibility, Screen Recording, and any needed Automation permissions.
3. Check your trigger keys and app assignments. Mappings for optional or personal apps only work once those apps are installed.
4. Check whether your Pro features need a license after the trial. Licenses and macOS permissions aren't transferred through dotfiles.

No Classic plist import or Hammerspoon helper is needed. The old helper is disabled in the source Mac's Hammerspoon init, and Hammerspoon is not installed by bootstrap. The old helper script and a private backup of the init are retained locally for rollback.

### Config and backups

rcmd supports YAML symlinks and writes UI changes through to the linked file. Review those diffs before committing, especially if stages or actions start referencing personal folders, URLs, or scripts. The captured `overrideUserDefaults: false` is preserved; changing it to `true` also resets settings omitted from the file to their defaults.

The native JSON export is an optional separate backup, not the YAML file used by Stow:

```sh
rcmd config export --file ~/Desktop/rcmd-settings.json
```

Search caches, licenses, and per-device permissions stay local. The `lenses/` directory currently has no files; add any future custom lens scripts separately after reviewing them.

### Classic rollback only

The old `preferences.plist`, screenshots, and `scripts/rcmd-settings.sh` are retained as Classic 2.x rollback artifacts. They are excluded from Stow. Don't use that importer for the normal v3 setup, and don't install App Store ID `1596283165` over v3.

The original sandbox preferences remain on the old Mac. They contain a private Hammerspoon token and a machine-specific bookmark, so don't commit the raw plist or the generated helper script.

Sources:
- https://lowtechguys.com/rcmd
- https://files.lowtechguys.com/rcmd/changelog.html

## What to include

Based on what's installed on the source Mac, I'd add these to a daily-use install list:

| Utility | Why include it | Current setup coverage |
| --- | --- | --- |
| Raycast | Launcher, shortcuts, window layouts | Core install; refreshed encrypted export |
| rcmd v3 | App and window switching | Core Homebrew install and linked native YAML |
| LinearMouse | Mouse behavior and acceleration | Core install and linked config |
| Tailscale | Approved private-network access | Core install; sign-in remains manual |
| Amphetamine | Keep the laptop awake when needed | App Store inventory, ID `937984704` |
| AlDente | Your existing charge-management setup | Not in bootstrap; Homebrew cask `aldente` |
| Hex | Dictation | Optional `--apps` install |
| Klack | Your preferred keyboard sounds | App Store inventory, ID `6446206067` |

Keep hardware-dependent tools separate:

- Keymapp for your ZSA keyboard is already in `--apps`.
- Logi Options+ is worth including only if the new setup uses your Logitech hardware. The cask is `logi-options+`; avoid installing both old Logi Options and Options+ without a device-specific reason.
- Display Pilot 2 is useful only for a supported BenQ monitor. The cask is `display-pilot`.
- Hammerspoon is no longer needed for rcmd. Only add it if you write other automation that uses it.

KeyCastr and Screen Studio are already in `--apps`; keep them optional unless you record demos regularly. Review employer policy before adding ProtonVPN, another authenticator, or personal cloud accounts. Use the employer's approved password manager and backup service rather than automatically installing personal choices.

I wouldn't add another launcher, app switcher, or window manager by default. Raycast and rcmd already cover that. Finish the utility setup by configuring login items, granting macOS permissions, and checking keyboard shortcuts for conflicts.
