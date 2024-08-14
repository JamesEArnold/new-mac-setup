#!/usr/bin/env bash

# Log file setup
LOGFILE="${HOME}/setup_log_$(date +%Y%m%d%H%M%S).log"

# Function to log messages
log() {
    echo "$1" | tee -a "$LOGFILE"
}

# Ask for the administrator password upfront
log "Requesting administrator password..."
sudo -v
if [ $? -eq 0 ]; then
    log "Administrator privileges obtained."
else
    log "Failed to obtain administrator privileges."
    exit 1
fi

###############################################################################
# General UI/UX                                                               #
###############################################################################

log "Setting General UI/UX preferences..."

log "Revealing IP address, hostname, OS version, etc. in the login window..."
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

log "Enabling automatic restart if the computer freezes..."
sudo systemsetup -setrestartfreeze on

log "Disabling Notification Center and removing the menu bar icon..."
launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null || log "Notification Center already disabled."

###############################################################################
# Trackpad, mouse, keyboard, Bluetooth accessories, and input                 #
###############################################################################

log "Setting Trackpad, Mouse, and Keyboard preferences..."

log "Disabling natural scrolling..."
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

log "Increasing sound quality for Bluetooth headphones/headsets..."
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

log "Setting a fast keyboard repeat rate..."
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 15

###############################################################################
# Screen                                                                      #
###############################################################################

log "Setting Screen preferences..."

log "Saving screenshots to the Pictures/Screenshots directory..."
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

log "Setting screenshots to save in PNG format..."
defaults write com.apple.screencapture type -string "png"

log "Enabling subpixel font rendering on non-Apple LCDs..."
defaults write NSGlobalDomain AppleFontSmoothing -int 2

log "Enabling HiDPI display modes (requires restart)..."
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true

###############################################################################
# Finder                                                                      #
###############################################################################

log "Setting Finder preferences..."

log "Showing hidden files by default..."
defaults write com.apple.finder AppleShowAllFiles -bool true

log "Showing all filename extensions..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

log "Showing path bar in Finder..."
defaults write com.apple.finder ShowPathbar -bool true

log "Enabling spring loading for directories..."
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

log "Setting a faster spring loading delay for directories..."
defaults write NSGlobalDomain com.apple.springing.delay -float .5

log "Setting list view as default in all Finder windows..."
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

###############################################################################
# Dock, Dashboard, and hot corners                                            #
###############################################################################

log "Setting Dock preferences..."

log "Setting Dock item icon size to 36 pixels..."
defaults write com.apple.dock tilesize -int 36

log "Changing minimize/maximize window effect to scale..."
defaults write com.apple.dock mineffect -string "scale"

log "Enabling spring loading for all Dock items..."
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

log "Disabling automatic rearranging of Spaces based on most recent use..."
defaults write com.apple.dock mru-spaces -bool false

log "Enabling auto-hide for the Dock..."
defaults write com.apple.dock autohide -bool true

log "Adding iOS Simulator to Launchpad..."
sudo ln -sf "/Applications/Xcode.app/Contents/Developer/Applications/iOS Simulator.app" "/Applications/iOS Simulator.app"

###############################################################################
# Terminal & iTerm 2                                                          #
###############################################################################

log "Setting Terminal & iTerm 2 preferences..."

log "Only using UTF-8 in Terminal.app..."
defaults write com.apple.terminal StringEncodings -array 4

###############################################################################
# Activity Monitor                                                            #
###############################################################################

log "Setting Activity Monitor preferences..."

log "Showing the main window when launching Activity Monitor..."
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

log "Visualizing CPU usage in the Activity Monitor Dock icon..."
defaults write com.apple.ActivityMonitor IconType -int 5

log "Showing all processes in Activity Monitor..."
defaults write com.apple.ActivityMonitor ShowCategory -int 0

log "Sorting Activity Monitor results by CPU usage..."
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Address Book, Dashboard, iCal, TextEdit, and Disk Utility                   #
###############################################################################

log "Setting preferences for Address Book, Dashboard, iCal, TextEdit, and Disk Utility..."

log "Using plain text mode for new TextEdit documents..."
defaults write com.apple.TextEdit RichText -int 0

log "Setting TextEdit to open and save files as UTF-8..."
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

log "Setting TextEdit tab width to 4..."
defaults write com.apple.TextEdit "TabWidth" '4'

###############################################################################
# Mac App Store                                                               #
###############################################################################

log "Setting Mac App Store preferences..."

log "Enabling WebKit Developer Tools in the Mac App Store..."
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

log "Enabling Debug Menu in the Mac App Store..."
defaults write com.apple.appstore ShowDebugMenu -bool true

###############################################################################
# Finished                                                                    #
###############################################################################

log "Setup completed. Note that some changes require a logout/restart of your OS to take effect. At a minimum, restart your Terminal."

echo "Logs have been saved to $LOGFILE"
