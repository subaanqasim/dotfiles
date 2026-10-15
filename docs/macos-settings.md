# macOS preferences

Many settings changed through System Settings and `defaults write` end up in the same preferences domains. We can capture the current values without needing the original commands. This does not tell us which settings came from the UI or the CLI, and not every macOS setting uses this system.

## Captured settings

`macos/dock.plist` contains selected `com.apple.dock` values, not the whole Dock database:

- Automatic Dock hiding, opening delay, and animation time.
- Dock size, magnification, recent-app display, and minimization settings when explicitly configured.
- Mission Control's automatic Space rearrangement setting.
- All four hot-corner actions and their modifier keys.

The source Mac has auto-hide enabled, with both delay and animation time set to zero. Its configured corner codes are top-right `12`, bottom-left `13`, and bottom-right `4`, with no modifiers. Top-left has no explicit override. Unset preferences are omitted from the snapshot and reset to the destination OS's default during apply.

Pinned Dock apps, recent-app lists, file bookmarks, display UUIDs, window state, and other machine-specific data are not exported into Git.

## Refresh on the old Mac

Close System Settings after making changes, then run:

```sh
bash scripts/macos-settings.sh export
git diff -- macos/dock.plist
```

The export reads the current preferences and does not change them or restart the Dock. Review the snapshot before committing it.

## Apply on the new Mac

This is deliberately separate from bootstrap, so it won't unexpectedly change your desktop:

```sh
bash scripts/macos-settings.sh apply --dry-run
bash scripts/macos-settings.sh apply
killall Dock
```

Close System Settings before applying. The script writes or deletes only the allowlisted keys, preserving the destination's pinned apps and unrelated preferences. A missing source key resets that selected preference to its OS default. The script validates types first and makes a private full-domain backup under `~/.local/state/dotfiles/macos/` before writing anything. The Dock restart is manual because it briefly interrupts the Dock and Mission Control.

To undo an apply, use the backup path printed by the script:

```sh
defaults import com.apple.dock /path/to/private/backup/dock.plist
killall Dock
```

That rollback restores the entire pre-apply Dock domain, including the target's previous pinned apps. Keep the backup private and outside this repo.

## Other settings

We can extend the allowlist for keyboard repeat, Finder display options, screenshot format, and other preferences you want to carry over. Each needs a known domain, key, and expected type. Don't bulk-import all of `~/Library/Preferences` or symlink system plists into dotfiles; preferences daemons cache values and apps can replace the files.

Privacy permissions, Touch ID, Apple Pay, managed company policies, display arrangements, and many per-device settings need their own setup. Hotkeys and trackpad gestures can involve additional domains or host-specific values. An exported defaults dictionary isn't a complete Mac configuration backup.

Apple doesn't document every `defaults` key as a stable interface. Test these settings when moving between macOS versions, especially hidden animation keys.

References:
- https://support.apple.com/guide/mac-help/perform-quick-actions-with-hot-corners-mchlp3000/mac
- https://macos-defaults.com/dock/autohide.html
- https://macos-defaults.com/dock/autohide-delay.html
- https://macos-defaults.com/dock/autohide-time-modifier.html
