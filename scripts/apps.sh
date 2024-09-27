#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Ask for the administrator password upfront.
echo "Requesting administrator password..."
sudo -v
if [ $? -eq 0 ]; then
    echo "Administrator password accepted."
else
    echo "Failed to obtain administrator privileges."
    exit 1
fi

# Check for Homebrew,
# Install if we don't have it
echo "Checking if Homebrew is installed..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ $? -eq 0 ]; then
        echo "Homebrew installed successfully."
        echo "Adding Homebrew to PATH..."
        # Determine which shell is being used and source the appropriate profile
        if [[ $SHELL == *"zsh"* ]]; then
            echo "Configuring Homebrew environment..."
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            echo "Homebrew environment configured."
        elif [[ $SHELL == *"bash"* ]]; then
            echo "Configuring Homebrew environment..."
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
            echo "Homebrew environment configured."
        else
            echo "Unknown shell. Please restart your terminal manually to use Homebrew."
            exit 1
        fi
        echo "Homebrew added to PATH successfully."
    else
        echo "Failed to install Homebrew."
        exit 1
    fi
else
    echo "Homebrew is already installed."
fi

# Make sure we’re using the latest Homebrew.
echo "Updating Homebrew..."
brew update
if [ $? -eq 0 ]; then
    echo "Homebrew updated successfully."
else
    echo "Failed to update Homebrew."
    exit 1
fi

# Upgrade any already-installed formulae.
echo "Upgrading installed formulae..."
brew upgrade
if [ $? -eq 0 ]; then
    echo "Formulae upgraded successfully."
else
    echo "Failed to upgrade formulae."
    exit 1
fi

# Install GNU core utilities (those that come with OS X are outdated).
echo "Installing GNU core utilities..."
brew install coreutils
if [ $? -eq 0 ]; then
    echo "GNU core utilities installed successfully."
else
    echo "Failed to install GNU core utilities."
    exit 1
fi

sudo ln -s /usr/local/bin/gsha256sum /usr/local/bin/sha256sum
if [ $? -eq 0 ]; then
    echo "Symbolic link for sha256sum created successfully."
else
    echo "Failed to create symbolic link for sha256sum."
    exit 1
fi

# Core casks
echo "Installing core applications..."
for app in iterm2 "visual-studio-code" datagrip; do
    echo "Installing $app..."
    brew install --cask --appdir="/Applications" "$app"
    if [ $? -eq 0 ]; then
        echo "$app installed successfully."
    else
        echo "Failed to install $app."
    fi
done

# Misc casks
echo "Installing miscellaneous applications..."
for app in "google-chrome" firefox slack postman notion figma; do
    echo "Installing $app..."
    brew install --cask --appdir="/Applications" "$app"
    if [ $? -eq 0 ]; then
        echo "$app installed successfully."
    else
        echo "Failed to install $app."
    fi
done

# Install Docker, which requires virtualbox
echo "Installing Docker and Boot2Docker..."
brew install docker
if [ $? -eq 0 ]; then
    echo "Docker installed successfully."
else
    echo "Failed to install Docker."
    exit 1
fi

brew install boot2docker
if [ $? -eq 0 ]; then
    echo "Boot2Docker installed successfully."
else
    echo "Failed to install Boot2Docker."
    exit 1
fi

brew install --cask font-hack-nerd-font
if [ $? -eq 0 ]; then
    echo "Nerd Fonts installed successfully."
    echo "Dont forget to update your terminal profile font to be a Nerd Font."
else
    echo "Failed to install NerdFonts."
    exit 1
fi

# Function to add app to Dock
add_to_dock() {
    APP_PATH="$1"

    # Check if the app exists
    if [[ ! -d "$APP_PATH" ]]; then
        echo "Error: Application at $APP_PATH is not installed."
        return 1
    fi

    # Add the application to the Dock
    defaults write com.apple.dock persistent-apps -array-add "<dict>
        <key>tile-data</key>
        <dict>
            <key>file-data</key>
            <dict>
                <key>_CFURLString</key>
                <string>$APP_PATH</string>
                <key>_CFURLStringType</key>
                <integer>0</integer>
            </dict>
        </dict>
    </dict>"

    echo "Added $APP_PATH to the Dock."
}

# Add applications to Dock
echo "Adding applications to the Dock..."
for app in \
    "/Applications/iTerm.app" \
    "/Applications/Visual Studio Code.app" \
    "/Applications/DataGrip.app" \
    "/Applications/Google Chrome.app" \
    "/Applications/Firefox.app" \
    "/Applications/Slack.app" \
    "/Applications/Postman.app" \
    "/Applications/Notion.app" \
    "/Applications/Figma.app"; do
    echo "Adding $app to the Dock..."
    add_to_dock "$app"
done

# Restart the Dock to apply changes
echo "Restarting the Dock..."
killall Dock

# Remove outdated versions from the cellar.
echo "Cleaning up outdated versions..."
brew cleanup
if [ $? -eq 0 ]; then
    echo "Cleanup completed successfully."
else
    echo "Failed to clean up."
fi

echo "Script execution completed."
