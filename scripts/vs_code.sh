#!/bin/bash

# Ask for the administrator password upfront.
echo "Requesting administrator password..."
sudo -v
if [ $? -eq 0 ]; then
    echo "Administrator password accepted."
else
    echo "Failed to obtain administrator privileges."
    exit 1
fi

# Function to check if VSCode is installed
check_vscode_installed() {
  if ! command -v code &> /dev/null; then
    echo "VSCode is not installed. Please install it first."
    exit 1
  fi
}

# Function to install a VSCode extension
install_vscode_extension() {
  local extension=$1
  echo "Installing $extension..."
  code --install-extension $extension
  if [ $? -eq 0 ]; then
    echo "$extension successfully installed!"
  else
    echo "Failed to install $extension."
    exit 1
  fi
}

# Function to add a setting to the VSCode settings file
add_vscode_setting() {
  local setting_key=$1
  local setting_value=$2

  # Path to VSCode settings file
  VSCODE_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"

  # Check if the settings file exists
  if [ -f "$VSCODE_SETTINGS" ]; then
    # Check if the setting already exists
    if ! grep -q "\"$setting_key\": \"$setting_value\"" "$VSCODE_SETTINGS"; then
      # Add the setting before the last closing brace
      sed -i '' -e "\$s/}/,\n    \"$setting_key\": \"$setting_value\"\n}/" "$VSCODE_SETTINGS"
      echo "Added '$setting_key' to VSCode settings."
    else
      echo "'$setting_key' is already set."
    fi
  else
    echo "VSCode settings file not found."
  fi
}

# Run the checks and installation
check_vscode_installed

# Install extensions
install_vscode_extension dracula-theme.theme-dracula # Dracula Theme
install_vscode_extension dbaeumer.vscode-eslint # Eslint
install_vscode_extension dsznajder.es7-react-js-snippets # React Snippets
install_vscode_extension heybourn.headwind # Opinionated Tailwind Sorting
install_vscode_extension bradlc.vscode-tailwindcss # Tailwind Intellisense
install_vscode_extension wayou.vscode-todo-highlight # TODO Highlights
install_vscode_extension esbenp.prettier-vscode # Prettier
install_vscode_extension pkief.material-icon-theme # Material Theme Icons
install_vscode_extension streetsidesoftware.code-spell-checker # Spell Checker
install_vscode_extension donjayamanne.git-extension-pack # Gitblame, Gitignore, line history
install_vscode_extension wix.vscode-import-cost # Import size
install_vscode_extension ms-vsliveshare.vsliveshare # Live share pair programming
install_vscode_extension ms-playwright.playwright # Playwright runner
install_vscode_extension prisma.prisma # Prisma intellisense
install_vscode_extension sonarsource.sonarlint-vscode # Sonar Linting

# Add desired settings
add_vscode_setting "terminal.integrated.fontFamily" "FiraCode Nerd Font Mono"

echo "All extensions installed successfully, and settings configured!"
