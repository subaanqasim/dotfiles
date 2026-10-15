#!/bin/bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v brew >/dev/null 2>&1 || { echo 'Homebrew is required.' >&2; exit 1; }
snapshot=$(mktemp "${TMPDIR:-/tmp}/dotfiles-brewfile.XXXXXX")
extras=$(mktemp "${TMPDIR:-/tmp}/dotfiles-brew-extras.XXXXXX")
output=''
trap 'rm -f "$snapshot" "$extras"; if [[ -n "$output" ]]; then rm -f "$output"; fi' EXIT

brew bundle dump --file="$snapshot" --force --no-describe
# A few installed tap formulae and orphaned dependencies are missed by the dump.
brew list --formula --full-name | awk 'index($0, "/")' > "$extras"
brew leaves >> "$extras"
LC_ALL=C sort -u "$extras" -o "$extras"
output=$(mktemp "$ROOT/homebrew/.Brewfile.XXXXXX")
{
  echo '# Installed-state inventory from the source Mac. Not the default bootstrap.'
  echo '# Refresh with: bash scripts/update-brewfile.sh'
  cat "$snapshot"
  printf "\n# Installed leaves and tap formulae omitted by Homebrew's dump metadata.\n"
  while IFS= read -r formula; do
    if ! grep -Fq "brew \"$formula\"" "$snapshot"; then
      printf 'brew "%s"\n' "$formula"
    fi
  done < "$extras"
} > "$output"
chmod 644 "$output"
mv "$output" "$ROOT/homebrew/Brewfile"
echo 'Updated homebrew/Brewfile. Review git diff before committing.'
