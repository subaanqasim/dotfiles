#!/bin/bash
set -euo pipefail
trap 'echo "Setup test failed at line $LINENO" >&2' ERR
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
command -v stow >/dev/null 2>&1 || { echo 'Tests require GNU Stow.' >&2; exit 1; }
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/home" "$TEST_DIR/conflict" "$TEST_DIR/omz"

bash -n "$ROOT/setup/bootstrap.sh"
bash -n "$ROOT/scripts/stow.sh"
bash -n "$ROOT/scripts/update-brewfile.sh"
bash -n "$ROOT/scripts/rcmd-settings.sh"
bash -n "$ROOT/scripts/macos-settings.sh"
bash -n "$ROOT/bash/.bash_profile"
zsh -n "$ROOT/zsh/.zshrc"
zsh -n "$ROOT/zsh/.zprofile"

bash "$ROOT/scripts/stow.sh" --target "$TEST_DIR/home" --dry-run
[[ ! -e "$TEST_DIR/home/.zshrc" ]]
bash "$ROOT/scripts/stow.sh" --target "$TEST_DIR/home"
[[ -L "$TEST_DIR/home/.zshrc" ]]
[[ -L "$TEST_DIR/home/.zprofile" ]]
[[ -L "$TEST_DIR/home/.ssh/config" ]]
[[ -L "$TEST_DIR/home/.config/nvim/lazyvim.json" ]]
[[ -L "$TEST_DIR/home/.config/opencode/cli.json" ]]
[[ -L "$TEST_DIR/home/.config/rcmd/config.yaml" ]]
[[ "$TEST_DIR/home/.config/rcmd/config.yaml" -ef "$ROOT/rcmd/.config/rcmd/config.yaml" ]]
[[ ! -L "$TEST_DIR/home/.config/rcmd" ]]
[[ ! -e "$TEST_DIR/home/.config/rcmd/preferences.plist" ]]
[[ ! -e "$TEST_DIR/home/.config/rcmd/settings.png" ]]
[[ ! -e "$TEST_DIR/home/.config/rcmd/.stow-local-ignore" ]]
[[ -L "$TEST_DIR/home/.codex/config.toml" ]]
[[ "$TEST_DIR/home/.codex/config.toml" -ef "$ROOT/codex-portable/.codex/config.toml" ]]
[[ ! -L "$TEST_DIR/home/.config" ]]
[[ ! -L "$TEST_DIR/home/.codex" ]]
[[ ! -L "$TEST_DIR/home/.config/opencode" ]]
[[ ! -e "$TEST_DIR/home/.oh-my-zsh/oh-my-zsh.sh" ]]
[[ ! -e "$TEST_DIR/home/.config/worktrunk/approvals.toml" ]]
[[ ! -e "$TEST_DIR/home/.config/opencode/plugins/wakelock/node_modules" ]]
[[ ! -e "$TEST_DIR/home/.tmux.conf" ]]
[[ ! -e "$TEST_DIR/home/.config/iterm2" ]]
bash "$ROOT/scripts/stow.sh" --target "$TEST_DIR/home"

# rcmd-only linking also respects its local ignores without the global wrapper.
mkdir -p "$TEST_DIR/rcmd-only"
stow --dir "$ROOT" --target "$TEST_DIR/rcmd-only" --no-folding rcmd
[[ -L "$TEST_DIR/rcmd-only/.config/rcmd/config.yaml" ]]
[[ ! -e "$TEST_DIR/rcmd-only/.DS_Store" ]]
[[ ! -e "$TEST_DIR/rcmd-only/.config/.DS_Store" ]]
[[ ! -e "$TEST_DIR/rcmd-only/.config/rcmd/preferences.plist" ]]

# One conflict must prevent all links, not just the conflicting package.
printf 'keep this file\n' > "$TEST_DIR/conflict/.zshrc"
if bash "$ROOT/scripts/stow.sh" --target "$TEST_DIR/conflict" > "$TEST_DIR/conflict.log" 2>&1; then
  echo 'Expected a conflict failure.' >&2; exit 1
fi
[[ $(cat "$TEST_DIR/conflict/.zshrc") == 'keep this file' ]]
[[ ! -e "$TEST_DIR/conflict/.gitconfig" ]]

# A real upstream OMZ installation must be left alone.
mkdir -p "$TEST_DIR/omz/.oh-my-zsh/custom"
printf 'upstream loader\n' > "$TEST_DIR/omz/.oh-my-zsh/oh-my-zsh.sh"
bash "$ROOT/scripts/stow.sh" --target "$TEST_DIR/omz"
[[ $(cat "$TEST_DIR/omz/.oh-my-zsh/oh-my-zsh.sh") == 'upstream loader' ]]
[[ -L "$TEST_DIR/omz/.oh-my-zsh/custom/aliases.zsh" ]]

# Missing optional tools must not cause startup errors or secret reads.
mkdir -p "$TEST_DIR/bin" "$TEST_DIR/shell-home"
cat > "$TEST_DIR/bin/pass" <<'EOF'
#!/bin/sh
echo 'Unexpected password-store access' >&2
exit 99
EOF
chmod +x "$TEST_DIR/bin/pass"
HOME="$TEST_DIR/shell-home" PATH="$TEST_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  /bin/zsh -dfc 'source "$1"' zsh "$ROOT/zsh/.zshrc" > "$TEST_DIR/shell.log" 2>&1
[[ ! -s "$TEST_DIR/shell.log" ]]

# Opt-in secret loading must keep existing values and use only the first line.
cat > "$TEST_DIR/shell-home/.zshrc.local" <<'EOF'
pass() { print -r -- test-value; print -r -- metadata; }
EOF
HOME="$TEST_DIR/shell-home" PATH="$TEST_DIR/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  /bin/zsh -dfc '
    unset TAVILY_API_KEY GROQ_API_KEY GEMINI_API_KEY SCHEMATIC_API_KEY SCHEMATIC_API_KEY_PROD
    export DOTFILES_LOAD_SECRETS=1 ANTHROPIC_API_KEY=existing-value
    source "$1"
    [[ $ANTHROPIC_API_KEY == existing-value && $TAVILY_API_KEY == test-value ]]
  ' zsh "$ROOT/zsh/.zshrc" > "$TEST_DIR/secrets.log" 2>&1
[[ ! -s "$TEST_DIR/secrets.log" ]]

mkdir -p "$TEST_DIR/dry-home"
HOME="$TEST_DIR/dry-home" bash "$ROOT/setup/bootstrap.sh" --dry-run > "$TEST_DIR/dry.log" 2>&1
[[ ! -e "$TEST_DIR/dry-home/.zshrc" ]]
[[ ! -e "$TEST_DIR/dry-home/.opencode" ]]
[[ ! -e "$TEST_DIR/dry-home/.resurrect-key.txt" ]]

# Exercise the inventory updater without touching this repo or invoking Homebrew.
mkdir -p "$TEST_DIR/inventory/scripts" "$TEST_DIR/inventory/homebrew" "$TEST_DIR/inventory/bin"
cp "$ROOT/scripts/update-brewfile.sh" "$TEST_DIR/inventory/scripts/"
cat > "$TEST_DIR/inventory/bin/brew" <<'EOF'
#!/bin/bash
set -eu
case "$1" in
  bundle)
    for arg in "$@"; do
      case "$arg" in --file=*) file=${arg#--file=} ;; esac
    done
    printf 'brew "git"\nbrew "demo/tap/existing"\n' > "$file"
    ;;
  list) printf 'git\ndemo/tap/existing\ndemo/tap/missing\n' ;;
  leaves) printf 'git\norphan\n' ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/inventory/bin/brew"
PATH="$TEST_DIR/inventory/bin:$PATH" bash "$TEST_DIR/inventory/scripts/update-brewfile.sh"
inventory="$TEST_DIR/inventory/homebrew/Brewfile"
[[ $(grep -Fc 'brew "git"' "$inventory") == 1 ]]
[[ $(grep -Fc 'brew "demo/tap/existing"' "$inventory") == 1 ]]
grep -Fq 'brew "demo/tap/missing"' "$inventory"
grep -Fq 'brew "orphan"' "$inventory"

# Classic preferences transfers must exclude secrets and preserve local tokens.
rcmd_home="$TEST_DIR/rcmd-home"
domain="$rcmd_home/Library/Containers/com.lowtechguys.rcmd/Data/Library/Preferences/com.lowtechguys.rcmd"
mkdir -p "$(dirname "$domain")" "$TEST_DIR/rcmd-bin"
cat > "$TEST_DIR/rcmd-bin/pgrep" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$TEST_DIR/rcmd-bin/pgrep"
plutil -create xml1 "$domain.plist"
plutil -replace hstoken -string test-private-token "$domain.plist"
plutil -replace workingDirectoryBookmark -data dGVzdC1ib29rbWFyaw== "$domain.plist"
plutil -replace showAppSwitcher -bool true "$domain.plist"
plutil -replace appKeyAssignments -json '["test-assignment"]' "$domain.plist"
HOME="$rcmd_home" PATH="$TEST_DIR/rcmd-bin:$PATH" \
  bash "$ROOT/scripts/rcmd-settings.sh" export "$TEST_DIR/rcmd-export.plist"
if plutil -type hstoken "$TEST_DIR/rcmd-export.plist" >/dev/null 2>&1; then exit 1; fi
if plutil -type workingDirectoryBookmark "$TEST_DIR/rcmd-export.plist" >/dev/null 2>&1; then exit 1; fi
[[ $(plutil -extract appKeyAssignments raw "$TEST_DIR/rcmd-export.plist") == 1 ]]

plutil -replace showAppSwitcher -bool false "$domain.plist"
# Even if someone supplies an unfiltered backup, private fields aren't imported.
plutil -replace hstoken -string do-not-import "$TEST_DIR/rcmd-export.plist"
HOME="$rcmd_home" PATH="$TEST_DIR/rcmd-bin:$PATH" \
  bash "$ROOT/scripts/rcmd-settings.sh" import "$TEST_DIR/rcmd-export.plist"
[[ $(defaults read "$domain" hstoken) == test-private-token ]]
[[ $(defaults read "$domain" showAppSwitcher) == 1 ]]
[[ $(plutil -extract workingDirectoryBookmark raw "$domain.plist") == dGVzdC1ib29rbWFyaw== ]]

cat > "$TEST_DIR/rcmd-bin/pgrep" <<'EOF'
#!/bin/sh
exit 0
EOF
if HOME="$rcmd_home" PATH="$TEST_DIR/rcmd-bin:$PATH" \
  bash "$ROOT/scripts/rcmd-settings.sh" import "$TEST_DIR/rcmd-export.plist" > "$TEST_DIR/rcmd-running.log" 2>&1; then
  echo 'Expected import to refuse a running rcmd app.' >&2; exit 1
fi

# Dock exports and applies must never touch live defaults during tests.
mkdir -p "$TEST_DIR/macos-bin" "$TEST_DIR/macos-home"
export MACOS_TEST_FIXTURE="$TEST_DIR/dock-fixture.plist"
export MACOS_TEST_LOG="$TEST_DIR/dock-defaults.log"
plutil -create xml1 "$MACOS_TEST_FIXTURE"
plutil -replace autohide -bool true "$MACOS_TEST_FIXTURE"
plutil -replace autohide-delay -float 0 "$MACOS_TEST_FIXTURE"
plutil -replace autohide-time-modifier -integer 0 "$MACOS_TEST_FIXTURE"
plutil -replace show-recents -bool false "$MACOS_TEST_FIXTURE"
plutil -replace wvous-tl-corner -integer 2 "$MACOS_TEST_FIXTURE"
plutil -replace persistent-apps -json '["private-app-bookmark"]' "$MACOS_TEST_FIXTURE"
cat > "$TEST_DIR/macos-bin/defaults" <<'EOF'
#!/bin/bash
set -eu
printf '%s\t' "$@" >> "$MACOS_TEST_LOG"
printf '\n' >> "$MACOS_TEST_LOG"
case "$1" in
  export) cp "$MACOS_TEST_FIXTURE" "$3" ;;
  read-type) plutil -type "$3" "$MACOS_TEST_FIXTURE" ;;
  write|delete) ;;
  *) echo 'Unexpected defaults operation in macOS settings test.' >&2; exit 1 ;;
esac
EOF
chmod +x "$TEST_DIR/macos-bin/defaults"
HOME="$TEST_DIR/macos-home" PATH="$TEST_DIR/macos-bin:$PATH" \
  bash "$ROOT/scripts/macos-settings.sh" export "$TEST_DIR/dock-export.plist"
[[ $(plutil -extract autohide raw "$TEST_DIR/dock-export.plist") == true ]]
[[ $(plutil -extract autohide-delay raw "$TEST_DIR/dock-export.plist") =~ ^0([.]0+)?$ ]]
[[ $(plutil -extract show-recents raw "$TEST_DIR/dock-export.plist") == false ]]
if plutil -type persistent-apps "$TEST_DIR/dock-export.plist" >/dev/null 2>&1; then exit 1; fi
plutil -remove wvous-tl-corner "$TEST_DIR/dock-export.plist"
# Extra keys in a supplied file must not cause a whole-domain import.
plutil -replace persistent-apps -json '["do-not-apply"]' "$TEST_DIR/dock-export.plist"
: > "$MACOS_TEST_LOG"
HOME="$TEST_DIR/macos-home" PATH="$TEST_DIR/macos-bin:$PATH" \
  bash "$ROOT/scripts/macos-settings.sh" apply --dry-run "$TEST_DIR/dock-export.plist" > "$TEST_DIR/dock-plan.log"
[[ ! -s "$MACOS_TEST_LOG" ]]
[[ ! -e "$TEST_DIR/macos-home/.local/state/dotfiles/macos" ]]
HOME="$TEST_DIR/macos-home" PATH="$TEST_DIR/macos-bin:$PATH" \
  bash "$ROOT/scripts/macos-settings.sh" apply "$TEST_DIR/dock-export.plist"
grep -Fq $'write\tcom.apple.dock\tautohide\t-bool\ttrue\t' "$MACOS_TEST_LOG"
grep -Eq $'write\tcom.apple.dock\tautohide-delay\t-float\t0([.]0+)?\t' "$MACOS_TEST_LOG"
grep -Fq $'write\tcom.apple.dock\tautohide-time-modifier\t-int\t0\t' "$MACOS_TEST_LOG"
grep -Fq $'write\tcom.apple.dock\tshow-recents\t-bool\tfalse\t' "$MACOS_TEST_LOG"
grep -Fq $'delete\tcom.apple.dock\twvous-tl-corner\t' "$MACOS_TEST_LOG"
if grep -Fq 'persistent-apps' "$MACOS_TEST_LOG"; then exit 1; fi
# Invalid values must be rejected before any preferences or backups are touched.
plutil -replace autohide -array "$TEST_DIR/dock-export.plist"
: > "$MACOS_TEST_LOG"
if HOME="$TEST_DIR/macos-home" PATH="$TEST_DIR/macos-bin:$PATH" \
  bash "$ROOT/scripts/macos-settings.sh" apply "$TEST_DIR/dock-export.plist" > "$TEST_DIR/dock-invalid.log" 2>&1; then
  echo 'Expected invalid preference types to be rejected.' >&2; exit 1
fi
[[ ! -s "$MACOS_TEST_LOG" ]]

echo 'Setup tests passed.'
