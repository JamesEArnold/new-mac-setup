#!/usr/bin/env bash
# scripts/iterm.sh
# Point iTerm2 at this repo's configs/iterm2/ folder for prefs, and link
# DynamicProfiles into the repo so JSON profiles are version-controlled.
#
# How iTerm uses this:
#   - Reads com.googlecode.iterm2.plist from PrefsCustomFolder on launch
#   - Watches ~/Library/Application Support/iTerm2/DynamicProfiles/ for JSON profiles
#
# iTerm must be quit before running — it overwrites the plist on quit.

set -euo pipefail

log() { printf '%s\n' "$*"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ITERM_DIR="$SCRIPT_DIR/../configs/iterm2"
ITERM_DIR="$(cd "$ITERM_DIR" && pwd)"
PLIST_REPO="$ITERM_DIR/com.googlecode.iterm2.plist"
PLIST_LIVE="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
DP_REPO="$ITERM_DIR/DynamicProfiles"
DP_LIVE="$HOME/Library/Application Support/iTerm2/DynamicProfiles"

# --- Refuse to run while iTerm is open (it will clobber on quit) -------------
if pgrep -x iTerm2 >/dev/null 2>&1; then
  log "iTerm2 is currently running. Quit it fully (Cmd-Q) and re-run this script."
  log "Reason: iTerm rewrites its prefs plist on quit, which would overwrite the custom folder."
  exit 1
fi

# --- Bootstrap the tracked plist from current prefs if not yet present -------
mkdir -p "$ITERM_DIR"
if [[ ! -f "$PLIST_REPO" ]]; then
  if [[ -f "$PLIST_LIVE" ]]; then
    log "Bootstrapping $PLIST_REPO from current iTerm prefs."
    cp "$PLIST_LIVE" "$PLIST_REPO"
    log "Note: this plist is binary and may contain recent hosts / window state."
    log "Review before committing: git diff --stat $PLIST_REPO"
  else
    log "No existing iTerm prefs at $PLIST_LIVE and nothing tracked yet. Skipping plist setup."
  fi
fi

# --- Point iTerm at the custom folder ----------------------------------------
if [[ -f "$PLIST_REPO" ]]; then
  log "Setting iTerm2 PrefsCustomFolder -> $ITERM_DIR"
  defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$ITERM_DIR"
  defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true
fi

# --- Wire DynamicProfiles to a symlink into the repo -------------------------
mkdir -p "$DP_REPO"
mkdir -p "$(dirname "$DP_LIVE")"

if [[ -L "$DP_LIVE" ]]; then
  current_target="$(readlink "$DP_LIVE")"
  if [[ "$current_target" == "$DP_REPO" ]]; then
    log "DynamicProfiles already symlinked to repo."
  else
    log "DynamicProfiles symlink points elsewhere ($current_target). Re-pointing to $DP_REPO."
    rm "$DP_LIVE"
    ln -s "$DP_REPO" "$DP_LIVE"
  fi
elif [[ -d "$DP_LIVE" ]]; then
  log "Migrating existing DynamicProfiles JSON files into $DP_REPO"
  shopt -s nullglob
  for f in "$DP_LIVE"/*.json; do
    cp -n "$f" "$DP_REPO"/
  done
  shopt -u nullglob
  backup="$DP_LIVE.backup-$(date +%Y%m%d-%H%M%S)"
  mv "$DP_LIVE" "$backup"
  log "Backed up old DynamicProfiles dir to $backup"
  ln -s "$DP_REPO" "$DP_LIVE"
else
  ln -s "$DP_REPO" "$DP_LIVE"
fi
log "DynamicProfiles linked: $DP_LIVE -> $DP_REPO"

# --- Flush cfprefsd so the new defaults are picked up next launch ------------
killall cfprefsd >/dev/null 2>&1 || true

log "iTerm2 configured. Launch iTerm2; it will load prefs from $ITERM_DIR."
log "iterm.sh completed."
