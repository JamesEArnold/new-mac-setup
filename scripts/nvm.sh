#!/bin/bash

# Function to install nvm using curl
install_nvm() {
    echo "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

    # Automatically source nvm in the correct profile file
    echo "Configuring nvm..."

    # Determine which profile file to update
    PROFILE_FILE=""

    if [ -n "$ZSH_VERSION" ]; then
        PROFILE_FILE="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        PROFILE_FILE="$HOME/.bashrc"
    elif [ -f "$HOME/.profile" ]; then
        PROFILE_FILE="$HOME/.profile"
    fi

    # Add nvm source lines to the profile file
    NVM_INIT_SCRIPT='export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm'

    if ! grep -q 'nvm.sh' "$PROFILE_FILE"; then
        echo "$NVM_INIT_SCRIPT" >> "$PROFILE_FILE"
        echo "Added nvm configuration to $PROFILE_FILE"
    else
        echo "nvm configuration already exists in $PROFILE_FILE"
    fi

    # Source the profile file to make nvm available in the current session
    # Only source the file if we're running an interactive shell
    if [[ $- == *i* ]]; then
        source "$PROFILE_FILE"
    fi
}

# Function to install the latest stable version of Node.js using nvm
install_latest_node() {
    echo "Installing the latest stable version of Node.js..."
    nvm install node
    nvm use node
    nvm alias default node
    echo "Installed Node.js version: $(node -v)"
}

# Check if nvm is already installed
if command -v nvm &> /dev/null; then
    echo "nvm is already installed."
else
    install_nvm
    # Source the nvm script to make it available for this session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install the latest stable version of Node.js
if command -v nvm &> /dev/null; then
    install_latest_node
else
    echo "Error: nvm is not available. Please check the installation."
fi
