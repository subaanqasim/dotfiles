#!/bin/bash
# Legacy Classic 2.x rollback helper. Bootstrap uses v3's config.yaml instead.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ACTION=${1:-}
FILE=${2:-"$ROOT/rcmd/.config/rcmd/preferences.plist"}
DOMAIN="$HOME/Library/Containers/com.lowtechguys.rcmd/Data/Library/Preferences/com.lowtechguys.rcmd"
PREFS="$DOMAIN.plist"

if [[ $# -gt 2 || "$ACTION" != export && "$ACTION" != import ]]; then
  echo 'Usage: bash scripts/rcmd-settings.sh export|import [FILE]' >&2
  echo 'For rcmd Classic 2.x. Quit rcmd before a final export or any import.' >&2
  exit 1
fi
[[ $(uname -s) == Darwin ]] || { echo 'This script requires macOS.' >&2; exit 1; }
[[ -f "$PREFS" ]] || {
  echo 'No rcmd Classic preferences found. Install Classic, open it once, then quit it.' >&2
  exit 1
}

# Never transfer the Hammerspoon token, sandbox bookmarks, or cached app lists.
keys=(
  allowWindowSwitcher appKeyAssignments appSort appSortReverse
  appSwitcherFeatures appSwitcherUseNumbersForWindows enableAssignHotkey
  enableCycleHotkey hideMenubarIcon hideOnlyFocusedAppOnMinus hideStaticSettings
  ignoredApps ignoredKeys minimizeKey showAppSwitcher showWindowSwitcher
  switcherScreenPlacement triggerKeys windowKeyAssignments windowKeyPatterns
  windowSwitchOSDDelay windowSwitcherAppearance zeroAsLastFocusedWindow
)

umask 077
WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-rcmd.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

copy_settings() {
  local source=$1 target=$2 key xml
  for key in "${keys[@]}"; do
    if plutil -type "$key" "$source" >/dev/null 2>&1; then
      xml=$(plutil -extract "$key" xml1 -o - "$source")
      plutil -replace "$key" -xml "$xml" "$target"
    fi
  done
}

if [[ "$ACTION" == export ]]; then
  if pgrep -x rcmd >/dev/null 2>&1; then
    echo 'rcmd is running. Exporting saved preferences; quit it before a final migration export.' >&2
  fi
  plutil -create xml1 "$WORK/export.plist"
  copy_settings "$PREFS" "$WORK/export.plist"
  plutil -lint "$WORK/export.plist" >/dev/null
  mkdir -p "$(dirname "$FILE")"
  cp "$WORK/export.plist" "$FILE"
  echo "Exported portable rcmd Classic settings to $FILE"
else
  [[ -f "$FILE" ]] || { echo "Missing settings file: $FILE" >&2; exit 1; }
  if pgrep -x rcmd >/dev/null 2>&1; then
    echo 'Quit rcmd before importing settings.' >&2
    exit 1
  fi
  plutil -lint "$FILE" >/dev/null
  defaults export "$DOMAIN" "$WORK/original.plist"
  cp "$WORK/original.plist" "$WORK/merged.plist"
  copy_settings "$FILE" "$WORK/merged.plist"

  # Keep a private backup and preserve this Mac's local integration credentials.
  backups="$HOME/.local/state/dotfiles/rcmd"
  mkdir -p "$backups"
  backup=$(mktemp "$backups/classic-before-import.XXXXXX")
  cp "$WORK/original.plist" "$backup"
  defaults import "$DOMAIN" "$WORK/merged.plist"
  echo "Imported rcmd Classic settings. Private previous settings are saved at $backup"
  echo 'Reopen rcmd. Regenerate its Hammerspoon helper if you use window switching.'
fi
