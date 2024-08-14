# new-mac-setup

Automated scripts to take your Mac from zero to a fully configured development environment. This repository contains various Bash scripts that streamline the setup of essential tools, applications, and custom configurations on macOS. Whether you're starting fresh with a new Mac or setting up a new development environment, these scripts help you get up and running quickly.

## Overview

This repository includes the following automated setup scripts:


[**Homebrew Command-Line Tools and Applications Setup Script**](#homebrew-command-line-tools-and-applications-setup-script)
   - Automates the installation of Homebrew, essential command-line tools, and commonly used applications.
   - Adds selected applications to the Dock for easy access.

[**macOS Configuration Script**](#macos-configuration-script)
   - Customizes macOS system preferences, such as UI/UX settings, input devices, screen preferences, Finder settings, and more.
   - Logs all actions for review.

[**NVM Installation and Node.js Setup Script**](#nvm-installation-and-nodejs-setup-script)
   - Installs Node Version Manager (nvm) and the latest stable version of Node.js.
   - Configures shell profiles for automatic nvm loading.

[**Automated Zsh Environment Setup**](#automated-zsh-environment-setup)
   - Installs and configures Zsh with Oh My Zsh, Meslo Nerd Font, Starship.rs, and useful Zsh plugins.

## Directory Structure

```
new-mac-setup/
├── README.md                     # Project overview and usage instructions
├── brew_install_script.sh        # Homebrew and application setup script
├── macos_setup.sh                # macOS customization script
├── install_nvm_and_node.sh       # NVM and Node.js installation script
└── terminal_defaults.sh          # Automated Zsh environment setup script
```

## Usage Instructions

### 1. Homebrew Command-Line Tools and Applications Setup Script
- **File:** `brew_install_script.sh`
- **Description:** Automates the installation of Homebrew, essential command-line tools, and applications.

### 2. macOS Configuration Script
- **File:** `macos_setup.sh`
- **Description:** Customizes various macOS system preferences to enhance your user experience.

### 3. NVM Installation and Node.js Setup Script
- **File:** `install_nvm_and_node.sh`
- **Description:** Installs Node Version Manager (nvm) and the latest stable version of Node.js.

### 4. Automated Zsh Environment Setup
- **File:** `terminal_defaults.sh`
- **Description:** Sets up a customized Zsh environment with Oh My Zsh, Meslo Nerd Font, Starship.rs, and several useful plugins.


## Homebrew Command-Line Tools and Applications Setup Script

Automate the installation and setup of essential command-line tools and applications on macOS using Homebrew. It checks for the presence of Homebrew, installs it if necessary, and then proceeds to install and configure various tools, applications, and utilities. It also adds selected applications to the Dock for easy access.

#### Features:

1. **Administrator Privileges:**
   - The script requests administrator privileges at the start, ensuring it has the necessary permissions to install software and make system-level changes.

2. **Homebrew Installation and Setup:**
   - **Checks for Homebrew:** If Homebrew is not installed, the script downloads and installs it.
   - **Updates Homebrew:** Ensures you are using the latest version of Homebrew.
   - **Upgrades Installed Formulae:** Updates any already-installed Homebrew packages to their latest versions.

3. **Core Utilities Installation:**
   - Installs the GNU core utilities, which provide updated versions of tools that come with macOS.
   - Creates a symbolic link for `sha256sum` to ensure compatibility with scripts and tools that rely on this utility.

4. **Core and Miscellaneous Applications:**
   - Installs essential applications like iTerm2, Visual Studio Code, and DataGrip.
   - Installs additional productivity and development tools, including Google Chrome, Firefox, Slack, Postman, Notion, and Figma.

5. **Docker and Boot2Docker Installation:**
   - Installs Docker and Boot2Docker to enable containerized development on your macOS machine.

6. **Dock Customization:**
   - Adds installed applications to the macOS Dock for easy access. This customization ensures that your most-used apps are readily available.

7. **Cleanup:**
   - Removes outdated versions of installed formulae and applications to free up disk space and ensure a clean setup.

#### Usage:

1. **Running the Script:**
   - To execute the script, run it in your terminal:
     ```bash
     ./brew_install_script.sh
     ```
   - You will be prompted to enter your administrator password. Ensure you have the necessary permissions to install software on your machine.

2. **Reviewing Installation:**
   - The script will output the progress of each installation step, allowing you to follow along as it installs and configures your environment.
   - If any installation fails, the script will notify you and halt further execution.

3. **Customizing the Dock:**
   - The script automatically adds selected applications to the Dock. If you wish to add or remove applications from this list, modify the `add_to_dock` function and the list of applications in the script.

4. **Cleaning Up:**
   - The script performs a cleanup at the end of the execution, removing outdated versions of installed formulae.

#### Important Notes:

- The script is designed for macOS and assumes you are using a compatible shell (Bash or Zsh).
- Make sure to review the script before running it to ensure it meets your installation and customization needs.
- The script is interactive and will notify you if any part of the process fails, allowing you to address issues promptly.

This script provides a streamlined way to set up a development environment on macOS, saving time on manual installations and configurations while ensuring that your system is equipped with the latest tools and applications.

## macOS Configuration Script

This Bash script automates the setup and customization of various macOS system preferences. It makes changes to the user interface, input devices, screen settings, Finder, Dock, Terminal, Activity Monitor, and other applications. Each action is logged to a file for easy review.

#### Features:

1. **Administrator Privileges:**
   - The script requests administrator privileges upfront to execute commands that require elevated permissions.

2. **Logging:**
   - All actions are logged in a file named `setup_log_YYYYMMDDHHMMSS.log` located in the user's home directory. This allows you to review the actions taken during the setup process.

3. **General UI/UX Customizations:**
   - Reveals IP address, hostname, and OS version in the login window.
   - Enables automatic restart if the computer freezes.
   - Disables Notification Center and removes its menu bar icon.

4. **Input Devices Configuration:**
   - Disables natural scrolling for trackpads and mice.
   - Increases sound quality for Bluetooth audio devices.
   - Sets a fast keyboard repeat rate.

5. **Screen Settings:**
   - Saves screenshots to a dedicated `Screenshots` directory in the `Pictures` folder.
   - Changes screenshot format to PNG.
   - Enables HiDPI display modes for non-Apple displays.

6. **Finder Preferences:**
   - Shows hidden files and all filename extensions by default.
   - Displays the path bar and enables spring loading for directories.
   - Sets list view as the default in all Finder windows.

7. **Dock and Hot Corners:**
   - Adjusts Dock item size to 36 pixels.
   - Changes the window minimize/maximize effect to scale.
   - Enables auto-hide for the Dock and disables the automatic rearranging of Spaces.

8. **Terminal and iTerm2:**
   - Configures Terminal to use only UTF-8 encoding.

9. **Activity Monitor:**
   - Sets the main window to open by default.
   - Visualizes CPU usage in the Dock icon.
   - Shows all processes and sorts them by CPU usage.

10. **Other Applications:**
    - Configures TextEdit to use plain text mode and UTF-8 encoding.
    - Enables developer tools and the debug menu in the Mac App Store.

#### Usage:

1. **Running the Script:**
   - To run the script, execute it from the terminal:
     ```bash
     ./macos_setup.sh
     ```
   - The script will request administrator privileges at the start. Make sure to enter your password when prompted.

2. **Reviewing Logs:**
   - After the script completes, you can review the log file located at:
     ```bash
     ~/setup_log_YYYYMMDDHHMMSS.log
     ```

3. **Post-Setup Actions:**
   - Some changes require a logout or restart to take effect. At a minimum, restart your Terminal for the changes to be fully applied.

4. **Customizing the Script:**
   - You can modify the script to tailor it to your specific needs. Each section of the script is labeled for easy identification of the settings being changed.

#### Important Notes:

- This script is designed for macOS and assumes that you are using Bash or a compatible shell.
- Review the script carefully before running it to ensure it meets your customization needs.
- If you encounter issues, consult the log file to diagnose what might have gone wrong during execution.

This script streamlines the process of configuring a macOS environment to your preferences, saving time on manual setup and ensuring consistency across multiple devices.

## NVM Installation and Node.js Setup Script

This script automates the installation of Node Version Manager (nvm) and the latest stable version of Node.js. It checks if `nvm` is already installed and, if not, installs it using `curl`. After installing `nvm`, the script configures your shell profile to source `nvm` automatically in future sessions. Finally, it installs and sets the latest stable version of Node.js as the default.

#### Features:
- **Automated NVM Installation:** 
  - Installs `nvm` using `curl` from the official repository.
  - Configures the appropriate shell profile (`.zshrc`, `.bashrc`, or `.profile`) to source `nvm` automatically.
  
- **Node.js Installation:** 
  - Installs the latest stable version of Node.js.
  - Sets the installed Node.js version as the default for future terminal sessions.

#### Usage:

1. **Run the Script:**
   ```bash
   ./install_nvm_and_node.sh
   ```
   This will:
   - Install `nvm` (if not already installed).
   - Configure `nvm` in your shell profile.
   - Install the latest stable version of Node.js.
   
2. **Verify Installation:**
   - To verify that `nvm` is installed, run:
     ```bash
     nvm --version
     ```
   - To verify that Node.js is installed, run:
     ```bash
     node -v
     ```
     
3. **Reconfigure Profile Manually (if needed):**
   - If you switch shells or encounter issues with loading `nvm`, you can manually add the following lines to your profile file:
     ```bash
     export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
     [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
     ```
     
4. **Further Customization:**
   - You can customize which version of Node.js to install by modifying the `install_latest_node` function in the script.

#### Notes:
- The script assumes you are using either Bash, Zsh, or a POSIX-compliant shell. Ensure your terminal supports one of these.
- If `nvm` is already installed, the script will skip the installation step and proceed directly to installing the latest Node.js version.

This script simplifies the process of setting up `nvm` and Node.js, ensuring that your development environment is ready to use with minimal manual configuration.

## Automated Zsh Environment Setup

**terminal-defaults.sh** 

This script automates the installation and configuration of a Zsh environment with Oh My Zsh, Meslo Nerd Font, Starship.rs, and several useful Zsh plugins (`git`, `zsh-syntax-highlighting`, `zsh-autosuggestions`). It is compatible with both Linux and macOS systems.

### Features

- **Zsh Installation**: Installs Zsh on Linux and macOS systems.
- **Oh My Zsh**: Automatically installs and configures Oh My Zsh.
- **Meslo Nerd Font**: Downloads and installs the Meslo Nerd Font, commonly used with powerline symbols and terminal themes.
- **Starship.rs**: Installs Starship, a fast and customizable prompt for any shell.
- **Zsh Plugins**:
  - `git`: Useful git-related aliases and functions.
  - `zsh-syntax-highlighting`: Highlights commands while typing, enabling easier command line use.
  - `zsh-autosuggestions`: Suggests commands as you type based on history and completions.

### Usage

1. **Clone or Download the Script**: 
   Download the script and save it to your local machine.

2. **Make the Script Executable**:
   ```bash
   chmod +x terminal_defaults.sh
   ```

3. **Run the Script**:
   Execute the script to set up your Zsh environment:
   ```bash
   ./terminal_defaults.sh
   ```

4. **Restart Your Terminal**:
   After the script finishes, log out and log back in or restart your terminal to apply the changes.

### What the Script Does

- **Zsh Installation**:
  - Installs Zsh if it is not already installed on your system.
  - Changes your default shell to Zsh.

- **Oh My Zsh**:
  - Installs Oh My Zsh and configures it with a default theme.

- **Meslo Nerd Font**:
  - Downloads the Meslo Nerd Font, extracts it, and places it in the appropriate fonts directory.

- **Starship.rs**:
  - Installs the Starship prompt.
  - Adds the initialization code to your `~/.zshrc`.

- **Zsh Plugins**:
  - Ensures the `git` plugin is added to your Zsh configuration.
  - Clones the `zsh-syntax-highlighting` and `zsh-autosuggestions` plugins into the custom plugins directory for Oh My Zsh.
  - Adds the plugins to the `plugins` array in your `~/.zshrc`.

### Notes

- **Linux Users**: The script refreshes the font cache after installing the Meslo Nerd Font.
- **macOS Users**: Ensure that Homebrew is installed for Zsh installation on macOS.
- **Manual Changes**: If you have custom configurations in your `~/.zshrc`, review the changes made by this script to ensure compatibility with your existing setup.
