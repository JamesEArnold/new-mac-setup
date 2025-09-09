# scripts/mac_defaults.sh
#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/setup_log_$(date +%Y%m%d%H%M%S).log"

log() {
  echo "$@" | tee -a "$LOGFILE"
}

echo "Requesting administrator password..."
sudo -v || { echo "Failed to obtain administrator privileges."; exit 1; }

log "Setting General UI/UX preferences..."

# Reveal IP, hostname, OS version, etc. in the login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName || true
log "Revealing IP/hostname/OS in loginwindow."

# Automatic restart if the computer freezes (may not be supported on recent macOS)
log "Enabling automatic restart if the computer freezes (if supported)..."
if /usr/sbin/systemsetup -help 2>/dev/null | grep -q 'setrestartfreeze'; then
  sudo /usr/sbin/systemsetup -setrestartfreeze on || log "systemsetup setrestartfreeze failed; skipping."
else
  log "Skipping: restart-on-freeze not supported on this macOS."
fi


# DO NOT disable Notification Center (blocked by SIP)
log "Skipping hard-disable of Notification Center (blocked by SIP)."

log "Setting Trackpad, Mouse, and Keyboard preferences..."
# Disable “natural” scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false || true

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 1 || true
defaults write NSGlobalDomain InitialKeyRepeat -int 15 || true

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40 || true

log "Setting Screen & Screenshot preferences..."
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots" || true
defaults write com.apple.screencapture type -string "png" || true

# Subpixel font rendering (mostly ignored on new macOS/retina, but harmless)
defaults write NSGlobalDomain AppleFontSmoothing -int 2 || true

# Enable HiDPI (requires restart) — may be ignored on modern systems
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true || true

log "Setting Finder preferences..."
# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true || true
# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true || true
# Show path bar
defaults write com.apple.finder ShowPathbar -bool true || true
# Enable spring loading
defaults write NSGlobalDomain com.apple.springing.enabled -bool true || true
# Reduce spring loading delay
defaults write NSGlobalDomain com.apple.springing.delay -float 0.2 || true
# Prefer list view in Finder windows
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" || true

log "Setting Dock preferences..."
# Size, minimize effect, spring loading, autohide
defaults write com.apple.dock tilesize -int 36 || true
defaults write com.apple.dock mineffect -string "scale" || true
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true || true
defaults write com.apple.dock mru-spaces -bool false || true
defaults write com.apple.dock autohide -bool true || true

# Add Simulator to /Applications if Xcode is present
if [ -d "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app" ]; then
  log "Adding Simulator to /Applications..."
  sudo ln -sf "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app" "/Applications/Simulator.app" || true
fi

log "Setting Terminal & iTerm2 preferences..."
# Terminal UTF-8 only
defaults write com.apple.terminal StringEncodings -array 4 || true

log "Setting Activity Monitor preferences..."
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true || true
defaults write com.apple.ActivityMonitor IconType -int 5 || true
defaults write com.apple.ActivityMonitor ShowCategory -int 0 || true
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage" || true
defaults write com.apple.ActivityMonitor SortDirection -int 0 || true

log "Setting TextEdit to plain text & UTF-8..."
defaults write com.apple.TextEdit RichText -int 0 || true
defaults write com.apple.TextEdit PlainTextEncoding -int 4 || true
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4 || true
# Tab width 4
defaults write com.apple.TextEdit TabWidth -int 4 || true

log "Setting Mac App Store developer menus..."
defaults write com.apple.appstore WebKitDeveloperExtras -bool true || true
defaults write com.apple.appstore ShowDebugMenu -bool true || true

# Restart affected apps
for app in "Dock" "Finder" "SystemUIServer" "cfprefsd"; do
  killall "$app" >/dev/null 2>&1 || true
done

log "Setup completed. Some changes require logout/restart. At a minimum, restart your Terminal."
echo "Logs have been saved to $LOGFILE"
