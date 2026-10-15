#!/bin/bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TARGET=$HOME
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --target)
      [[ $# -ge 2 ]] || { echo '--target needs a directory.' >&2; exit 1; }
      TARGET=$2; shift 2 ;;
    *) echo 'Usage: bash scripts/stow.sh [--dry-run] [--target DIRECTORY]' >&2; exit 1 ;;
  esac
done
command -v stow >/dev/null 2>&1 || { echo 'Install GNU Stow first: brew install stow' >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "Target directory does not exist: $TARGET" >&2; exit 1; }

# Keep runtime directories on the laptop, not symlinked wholesale into this repo.
# The tracked OMZ loader is an old upstream copy, not a user customization.
# Worktrunk hook approvals must be reviewed on each machine.
args=(--dir "$ROOT" --target "$TARGET" --no-folding
  --ignore='(^|/)(\.DS_Store|\.git|\.gitignore|node_modules)(/|$)'
  --ignore='(^|/)oh-my-zsh\.sh$'
  --ignore='(^|/)approvals\.toml(\.lock)?$'
  zsh ohmyzsh git ssh npm nvim starship wezterm gh opencode
  agents worktrunk linearmouse rcmd codex-portable)

if ! stow --simulate "${args[@]}"; then
  cat >&2 <<'EOF'
Nothing was linked. Stow found conflicting files.
Move the reported files to a private backup outside this repo, then rerun.
Do not use stow --adopt: it would move laptop config or secrets into the repo.
EOF
  exit 1
fi
$DRY_RUN && exit 0
stow "${args[@]}"
if [[ -d "$TARGET/.ssh" ]]; then chmod 700 "$TARGET/.ssh"; fi
