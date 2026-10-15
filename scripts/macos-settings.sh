#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ACTION=${1:-}
[[ $# -gt 0 ]] && shift
FILE="$ROOT/macos/dock.plist"
DRY_RUN=false
file_set=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --*) echo "Unknown option: $arg" >&2; exit 1 ;;
    *)
      $file_set && { echo 'Only one settings file can be specified.' >&2; exit 1; }
      FILE=$arg; file_set=true ;;
  esac
done
if [[ "$ACTION" != export && "$ACTION" != apply ]] || { $DRY_RUN && [[ "$ACTION" != apply ]]; }; then
  echo 'Usage: bash scripts/macos-settings.sh export|apply [--dry-run] [FILE]' >&2
  echo 'Only selected Dock and hot-corner preferences are transferred.' >&2
  exit 1
fi
[[ $(uname -s) == Darwin ]] || { echo 'This script requires macOS.' >&2; exit 1; }

DOMAIN=com.apple.dock
keys=(
  autohide autohide-delay autohide-time-modifier orientation tilesize
  magnification largesize show-recents minimize-to-application mineffect
  launchanim mru-spaces
  wvous-tl-corner wvous-tl-modifier wvous-tr-corner wvous-tr-modifier
  wvous-bl-corner wvous-bl-modifier wvous-br-corner wvous-br-modifier
)

if [[ "$ACTION" == export ]]; then
  umask 077
  WORK=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-macos.XXXXXX")
  trap 'rm -rf "$WORK"' EXIT
  defaults export "$DOMAIN" "$WORK/current.plist"
  plutil -create xml1 "$WORK/selected.plist"
  for key in "${keys[@]}"; do
    if plutil -type "$key" "$WORK/current.plist" >/dev/null 2>&1; then
      xml=$(plutil -extract "$key" xml1 -o - "$WORK/current.plist")
      plutil -replace "$key" -xml "$xml" "$WORK/selected.plist"
    fi
  done
  mkdir -p "$(dirname "$FILE")"
  cp "$WORK/selected.plist" "$FILE"
  echo "Exported selected Dock and hot-corner settings to $FILE"
  exit 0
fi

[[ -f "$FILE" ]] || { echo "Missing settings file: $FILE" >&2; exit 1; }
plutil -lint "$FILE" >/dev/null
[[ $(/usr/libexec/PlistBuddy -c Print "$FILE" | sed -n '1p') == 'Dict {' ]] || {
  echo 'Settings must be a plist dictionary.' >&2; exit 1
}
# Validate every value before changing any preferences.
for key in "${keys[@]}"; do
  if type=$(plutil -type "$key" "$FILE" 2>/dev/null); then
    case "$type" in
      bool|boolean|integer|real|float|string) ;;
      *) echo "Unsupported value type for $key: $type" >&2; exit 1 ;;
    esac
  fi
done

if ! $DRY_RUN; then
  umask 077
  backups="$HOME/.local/state/dotfiles/macos"
  mkdir -p "$backups"
  backup=$(mktemp -d "$backups/dock-before-apply.XXXXXX")
  defaults export "$DOMAIN" "$backup/dock.plist"
  echo "Private pre-apply backup: $backup/dock.plist"
fi

for key in "${keys[@]}"; do
  if type=$(plutil -type "$key" "$FILE" 2>/dev/null); then
    value=$(plutil -extract "$key" raw "$FILE")
    case "$type" in
      bool|boolean) flag=-bool ;;
      integer) flag=-int ;;
      real|float) flag=-float ;;
      string) flag=-string ;;
    esac
    command=(defaults write "$DOMAIN" "$key" "$flag" "$value")
  else
    # An unset source preference means use the OS default, not the target's override.
    command=(defaults delete "$DOMAIN" "$key")
    if ! $DRY_RUN && ! defaults read-type "$DOMAIN" "$key" >/dev/null 2>&1; then
      continue
    fi
  fi
  if $DRY_RUN; then
    printf '%q ' "${command[@]}"
    printf '\n'
  else
    "${command[@]}"
  fi
done
$DRY_RUN && exit 0
echo 'Settings applied. Close System Settings, then run: killall Dock'
echo 'The Dock is not restarted automatically, and bootstrap never applies these settings.'
