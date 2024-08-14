#!/bin/bash

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

# Run the checks and installation
check_vscode_installed

install_vscode_extension dracula-theme.theme-dracula # Dracula Theme
install_vscode_extension dbaeumer.vscode-eslint # Eslint
install_vscode_extension dsznajder.es7-react-js-snippets # React Snippets
install_vscode_extension heybourn.headwind # Opinionated Tailwind Sorting
install_vscode_extension bradlc.vscode-tailwindcss # Tailwind Intellisense
install_vscode_extension wayou.vscode-todo-highlight # TODO Highlights
install_vscode_extension esbenp.prettier-vscode # Prettier
install_vscode_extension pkief.material-icon-theme # Material Theme Icons

echo "All extensions installed successfully!"
