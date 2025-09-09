#!/usr/bin/env bash

# Interactive app installer + Dock setup (idempotent, Apple Silicon–safe)
# Auto-detects already-installed apps and skips prompts/installs for them.
# Installs Claude Desktop & Claude Code, but does NOT attempt authorization.

set -euo pipefail

prompt_yes() {
  # Portable prompt that works in bash and zsh (avoids `read -p`).
  local prompt="${1:-Proceed?} [Y/n] "
  local ans=""
  printf "%s" "$prompt"
  read -r ans || true
  case "${ans:-Y}" in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    *)     return 0 ;;
  esac
}

is_app_installed() {
  # $1 = /Applications/Whatever.app
  [[ -n "${1:-}" && -d "$1" ]]
}

is_cask_installed() {
  # $1 = brew cask token (e.g., visual-studio-code)
  brew list --cask "$1" >/dev/null 2>&1
}

# ---- Arrays (predeclare to avoid set -u issues) ----
declare -a SELECTED_TO_INSTALL=()
declare -a ALREADY_INSTALLED=()
declare -a INSTALLED_TOKENS=()
declare -a FAILED_TOKENS=()
declare -a APP_PATH_MAP=()
declare -a DISPLAY_MAP=()

# Ask for the administrator password upfront.
echo "Requesting administrator password..."
if sudo -v; then
  echo "Administrator password accepted."
else
  echo "Failed to obtain administrator privileges."
  exit 1
fi

# Keep-alive: update existing sudo time stamp until script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Check for Homebrew; install if missing.
echo "Checking if Homebrew is installed..."
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "Adding Homebrew to PATH..."
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    if [[ ${SHELL:-} == *"zsh"* ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    elif [[ ${SHELL:-} == *"bash"* ]]; then
      echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
    fi
    echo "Homebrew environment configured."
  else
    echo "Warning: /opt/homebrew/bin/brew not found after install."
  fi
else
  echo "Homebrew is already installed."
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Update/upgrade brew
echo "Updating Homebrew..."
brew update && echo "Homebrew updated successfully."
echo "Upgrading installed formulae..."
brew upgrade || true

# Install GNU coreutils and ensure sha256sum is available via gnubin
echo "Installing GNU core utilities..."
brew install coreutils && echo "GNU core utilities installed successfully."

GNUBIN="$(brew --prefix coreutils)/libexec/gnubin"
if [[ -d "$GNUBIN" ]]; then
  if ! echo "$PATH" | grep -q "$GNUBIN"; then
    echo "Adding coreutils gnubin to PATH via ~/.zprofile"
    echo 'export PATH="'"$GNUBIN"':$PATH"' >> ~/.zprofile
  fi
  export PATH="$GNUBIN:$PATH"
  echo "coreutils gnubin added to PATH (sha256sum available)."
else
  echo "Warning: coreutils gnubin not found; skipping PATH change."
fi

# --- GitHub CLI (gh) for easy Claude github work  --------------------------------
echo "Installing GitHub CLI (gh)..."
if command -v gh >/dev/null 2>&1 || brew list --cask gh >/dev/null 2>&1 || brew list gh >/dev/null 2>&1; then
  echo "GitHub CLI already installed — skipping."
else
  if prompt_yes "Install GitHub CLI (gh)?"; then
    if brew install gh || brew install --cask gh; then
      echo "GitHub CLI installed successfully."
    else
      echo "Failed to install GitHub CLI."
    fi
  fi
fi



# ---- App Catalog ----
# Format: "token|Display Name|/Applications/AppName.app"
# (CLI tools like Claude Code have empty app paths and won't be pinned to the Dock.)
CASK_CATALOG=(
  "iterm2|iTerm|/Applications/iTerm.app"
  "visual-studio-code|Visual Studio Code|/Applications/Visual Studio Code.app"
  "beekeeper-studio|Beekeeper Studio|/Applications/Beekeeper Studio.app"
  "google-chrome|Google Chrome|/Applications/Google Chrome.app"
  "firefox|Firefox|/Applications/Firefox.app"
  "slack|Slack|/Applications/Slack.app"
  "postman|Postman|/Applications/Postman.app"
  "notion|Notion|/Applications/Notion.app"
  "figma|Figma|/Applications/Figma.app"
  "1password|1Password|/Applications/1Password.app"
  "docker|Docker Desktop|/Applications/Docker.app"
  "claude-code|Claude Code (CLI)|"
)

# ---- Helper to fetch value from token=>value arrays ----
get_map_val() {
  local key="$1"; shift
  local pair k v
  for pair in "$@"; do
    k="${pair%%|*}"
    v="${pair#*|}"
    if [[ "$k" == "$key" ]]; then
      printf "%s" "$v"
      return 0
    fi
  done
  return 1
}

# Build maps
for entry in "${CASK_CATALOG[@]}"; do
  IFS='|' read -r token display app_path <<<"$entry"
  APP_PATH_MAP+=("$token|$app_path")
  DISPLAY_MAP+=("$token|$display")
done

# ---- Selection logic with auto-detect ----
echo
echo "Checking installed apps and selecting what to install..."
for entry in "${CASK_CATALOG[@]}"; do
  IFS='|' read -r token display app_path <<<"$entry"
  if { [[ -n "$app_path" ]] && is_app_installed "$app_path"; } || is_cask_installed "$token"; then
    echo "✓ $display already installed — will skip installing, but keep for Dock if applicable."
    ALREADY_INSTALLED+=("$token")
  else
    if prompt_yes "Install $display?"; then
      SELECTED_TO_INSTALL+=("$token")
    fi
  fi
done

# Optional: Nerd Font
INSTALL_FONT=false
if prompt_yes "Install Hack Nerd Font (for terminals/editors)?"; then
  INSTALL_FONT=true
fi

# ---- Install selected casks ----
# Start INSTALLED_TOKENS with those already present so Dock step includes them.
INSTALLED_TOKENS=("${ALREADY_INSTALLED[@]}")
if ((${#SELECTED_TO_INSTALL[@]})); then
  echo
  echo "Installing selected applications..."
  for token in "${SELECTED_TO_INSTALL[@]}"; do
    display="$(get_map_val "$token" "${DISPLAY_MAP[@]}" || true)"
    echo "Installing ${display:-$token}..."
    if brew install --cask --appdir="/Applications" "$token"; then
      echo "${display:-$token} installed successfully."
      INSTALLED_TOKENS+=("$token")
    else
      echo "Failed to install ${display:-$token}."
      FAILED_TOKENS+=("$token")
    fi
  done
else
  echo "No additional applications selected for installation."
fi

# Optional Docker installs
if prompt_yes "Install Docker (CLI) now?"; then
  brew install docker && echo "Docker installed successfully." || echo "Failed to install Docker."
fi
if prompt_yes "Install docker-machine?"; then
  # On modern macOS, docker-machine is a more realistic legacy tool than boot2docker.
  brew install docker-machine && echo "docker-machine installed successfully." || echo "Failed to install docker-machine."
fi

# Nerd Font
if $INSTALL_FONT; then
  echo "Installing Hack Nerd Font..."
  if brew install --cask font-hack-nerd-font; then
    echo "Nerd Fonts installed successfully."
    echo "Don't forget to update your terminal profile font to a Nerd Font."
  else
    echo "Failed to install Nerd Fonts."
  fi
fi

# ---- Dock Pinning (only apps with .app bundles) ----
add_to_dock() {
  local APP_PATH="$1"
  if [[ -z "$APP_PATH" ]]; then
    return 0
  fi
  if [[ ! -d "$APP_PATH" ]]; then
    echo "Skip Dock: Application at $APP_PATH is not installed."
    return 1
  fi
  if defaults read com.apple.dock persistent-apps 2>/dev/null | grep -Fq "$APP_PATH"; then
    echo "Dock already contains: $APP_PATH (skipping)"
    return 0
  fi
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

if ((${#INSTALLED_TOKENS[@]})); then
  echo
  echo "Adding installed applications to the Dock..."
  for token in "${INSTALLED_TOKENS[@]}"; do
    app_path="$(get_map_val "$token" "${APP_PATH_MAP[@]}" || true)"
    display="$(get_map_val "$token" "${DISPLAY_MAP[@]}" || true)"
    if [[ -n "$app_path" ]]; then
      echo "Adding ${display:-$token} to the Dock..."
      add_to_dock "$app_path"
    fi
  done
  echo "Restarting the Dock..."
  killall Dock || true
fi

if ((${#FAILED_TOKENS[@]})); then
  echo
  echo "The following apps failed to install:"
  for t in "${FAILED_TOKENS[@]}"; do
    disp="$(get_map_val "$t" "${DISPLAY_MAP[@]}" || true)"
    echo " - ${disp:-$t}"
  done
fi

echo
echo "Cleaning up outdated versions..."
brew cleanup || true
echo "Script execution completed."
