#!/bin/bash

# Function to install Zsh
install_zsh() {
    echo "Installing Zsh..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt update && sudo apt install zsh -y
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install zsh
    else
        echo "Unsupported OS. Please install Zsh manually."
        exit 1
    fi
}

# Function to install Oh My Zsh
install_oh_my_zsh() {
    echo "Installing Oh My Zsh..."

    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

# Function to install Meslo Nerd Font
install_meslo_nerd_font() {
    echo "Installing Meslo Nerd Font..."

    # Define the font URL
    FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip"

    # Create a temporary directory for downloading the font
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR" || exit

    # Download the font zip file
    curl -fLo Meslo.zip "$FONT_URL"

    # Unzip the font
    unzip Meslo.zip -d Meslo

    # Create the fonts directory if it doesn't exist
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        mkdir -p ~/.local/share/fonts
        mv Meslo/* ~/.local/share/fonts/
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        mkdir -p ~/Library/Fonts
        mv Meslo/* ~/Library/Fonts/
    else
        echo "Unsupported OS. Please install Meslo Nerd Font manually."
        exit 1
    fi

    # Clean up
    cd ~ || exit
    rm -rf "$TEMP_DIR"

    # Refresh the font cache
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        fc-cache -fv
    fi

    echo "Meslo Nerd Font installed successfully."
}

# Function to install Starship.rs
install_starship() {
    echo "Installing Starship.rs..."

    # Install Starship
    curl -sS https://starship.rs/install.sh | sh -s -- -y

    echo "Starship.rs installed successfully."

    # Add Starship initialization to ~/.zshrc if not already present
    if ! grep -q 'eval "$(starship init zsh)"' "$HOME/.zshrc"; then
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
        starship preset nerd-font-symbols -o ~/.config/starship.toml
        echo "Starship.rs initialized in ~/.zshrc."
    else
        echo "Starship.rs is already initialized in ~/.zshrc."
    fi
}

# Function to install Zsh plugins
install_zsh_plugins() {
    echo "Installing Zsh plugins..."

    # Ensure git plugin is added
    if ! grep -q "plugins=.*git" "$HOME/.zshrc"; then
        sed -i -e 's/plugins=(/plugins=(git /' "$HOME/.zshrc"
        echo "Added git plugin to ~/.zshrc."
    fi

    # Clone zsh-syntax-highlighting plugin if not already installed
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
        echo "Installed zsh-syntax-highlighting plugin."
    else
        echo "zsh-syntax-highlighting is already installed."
    fi

    # Clone zsh-autosuggestions plugin if not already installed
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
        echo "Installed zsh-autosuggestions plugin."
    else
        echo "zsh-autosuggestions is already installed."
    fi

    # Add zsh-syntax-highlighting and zsh-autosuggestions to plugins array in ~/.zshrc
    if ! grep -q "plugins=.*zsh-syntax-highlighting" "$HOME/.zshrc"; then
        sed -i -e 's/plugins=(/plugins=(zsh-syntax-highlighting zsh-autosuggestions /' "$HOME/.zshrc"
        echo "Added zsh-syntax-highlighting and zsh-autosuggestions plugins to ~/.zshrc."
    fi
}

# Check if Zsh is installed
if ! command -v zsh &> /dev/null; then
    install_zsh
else
    echo "Zsh is already installed."
fi

# Install Oh My Zsh if not already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh is already installed."
else
    install_oh_my_zsh
fi

# Install Meslo Nerd Font if not already installed
if [[ "$OSTYPE" == "linux-gnu"* && ! -d "~/.local/share/fonts/Meslo" ]] || [[ "$OSTYPE" == "darwin"* && ! -d "~/Library/Fonts/Meslo" ]]; then
    install_meslo_nerd_font
else
    echo "Meslo Nerd Font is already installed."
fi

# Install Starship.rs if not already installed
if ! command -v starship &> /dev/null; then
    install_starship
else
    echo "Starship.rs is already installed."
fi

# Install Zsh plugins
install_zsh_plugins

# Change default shell to Zsh
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
    echo "Please log out and log back in to apply the new shell."
fi
