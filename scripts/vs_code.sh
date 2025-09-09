# scripts/vs_code.sh
#!/usr/bin/env bash
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

is_extension_installed() {
  # $1 = extension ID (e.g., esbenp.prettier-vscode)
  code --list-extensions 2>/dev/null | grep -q "^$1$"
}

APP="/Applications/Visual Studio Code.app"
CLI="$APP/Contents/Resources/app/bin/code"

if [[ ! -d "$APP" ]]; then
  echo "VSCode is not installed. Please install it first (brew install --cask visual-studio-code)."
  exit 1
fi

# Ensure code CLI is on PATH
HOMEBREW_BIN="$(brew --prefix)/bin"
mkdir -p "$HOMEBREW_BIN"
if ! command -v code >/dev/null 2>&1; then
  ln -sf "$CLI" "$HOMEBREW_BIN/code"
  echo "Linked 'code' CLI to $HOMEBREW_BIN"
fi

# Settings file
SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"
mkdir -p "$SETTINGS_DIR"

# Function to add/update a JSON key in settings.json idempotently
add_vscode_setting() {
  local key="$1"
  local value="$2"
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo "{}" > "$SETTINGS_FILE"
  fi
  # Use jq if available for safe JSON manipulation
  if command -v jq >/dev/null 2>&1; then
    tmp="$(mktemp)"
    jq --arg k "$key" --arg v "$value" '.[$k]=$v' "$SETTINGS_FILE" > "$tmp" && mv "$tmp" "$SETTINGS_FILE"
  else
    # fallback: naive append/replace (best-effort)
    if grep -q "\"$key\"" "$SETTINGS_FILE"; then
      sed -i '' "s/\"$key\"[^\n]*,/\"$key\": \"$value\",/g" "$SETTINGS_FILE" || true
      sed -i '' "s/\"$key\"[^\n]*}/\"$key\": \"$value\"}/g" "$SETTINGS_FILE" || true
    else
      sed -i '' 's/}$/,\n}/' "$SETTINGS_FILE" || true
      sed -i '' "s/},/,\n}/" "$SETTINGS_FILE" || true
      # Append just before closing brace
      ed -s "$SETTINGS_FILE" <<EOF || true
g/}/-1
,s/$/  \"$key\": \"$value\",\n}/
w
q
EOF
    fi
  fi
}

# Example useful settings; adjust to taste
add_vscode_setting "terminal.integrated.fontFamily" "MesloLGS Nerd Font Mono"
add_vscode_setting "editor.fontLigatures" "true"
add_vscode_setting "editor.formatOnSave" "true"
add_vscode_setting "files.trimTrailingWhitespace" "true"
add_vscode_setting "editor.renderWhitespace" "selection"
add_vscode_setting "workbench.startupEditor" "none"

# ---- Extension Categories ----
# Format: "extension-id|Display Name"
CORE_EXTENSIONS=(
  "esbenp.prettier-vscode|Prettier (Code Formatter)"
  "dbaeumer.vscode-eslint|ESLint (JavaScript Linting)"
  "ms-vscode.vscode-typescript-next|TypeScript Language Support"
)

GIT_EXTENSIONS=(
  "eamodio.gitlens|GitLens (Git History & Blame)"
  "donjayamanne.git-extension-pack|Git Extension Pack"
)

THEME_EXTENSIONS=(
  "dracula-theme.theme-dracula|Dracula Theme"
  "pkief.material-icon-theme|Material Icon Theme"
)

REACT_EXTENSIONS=(
  "dsznajder.es7-react-js-snippets|React/Redux Snippets"
  "bradlc.vscode-tailwindcss|Tailwind CSS IntelliSense"
  "heybourn.headwind|Headwind (Tailwind Sorting)"
)

DEV_TOOLS_EXTENSIONS=(
  "ms-azuretools.vscode-docker|Docker Support"
  "ms-python.python|Python Language Support"
  "wayou.vscode-todo-highlight|TODO Highlight"
  "streetsidesoftware.code-spell-checker|Code Spell Checker"
  "wix.vscode-import-cost|Import Cost Analyzer"
  "ms-vsliveshare.vsliveshare|Live Share (Collaboration)"
  "ms-playwright.playwright|Playwright Test Runner"
  "prisma.prisma|Prisma ORM Support"
  "sonarsource.sonarlint-vscode|SonarLint (Code Quality)"
)

# ---- Arrays to track installation state ----
declare -a SELECTED_TO_INSTALL=()
declare -a ALREADY_INSTALLED=()
declare -a INSTALLED_EXTENSIONS=()
declare -a FAILED_EXTENSIONS=()

# ---- Helper to extract extension ID from "id|name" format ----
get_extension_id() {
  local entry="$1"
  echo "${entry%%|*}"
}

get_extension_name() {
  local entry="$1"
  echo "${entry#*|}"
}

# ---- Interactive selection for extension categories ----
check_and_select_category() {
  local category_name="$1"
  local array_name="$2"
  
  echo
  echo "=== $category_name ==="
  
  local all_installed=true
  local some_installed=false
  
  # Get array contents using eval (zsh compatible)
  local -a category_array
  eval "category_array=(\"\${${array_name}[@]}\")"
  
  # Check if any extensions in this category need installation
  for entry in "${category_array[@]}"; do
    local ext_id="$(get_extension_id "$entry")"
    if is_extension_installed "$ext_id"; then
      some_installed=true
    else
      all_installed=false
    fi
  done
  
  # Determine prompt based on installation status
  if $all_installed; then
    echo "✓ All $category_name extensions already installed — skipping category."
    for entry in "${category_array[@]}"; do
      local ext_id="$(get_extension_id "$entry")"
      ALREADY_INSTALLED+=("$ext_id")
    done
    return 0
  elif $some_installed; then
    echo "Some $category_name extensions already installed."
    # Ask about individual extensions in mixed state
    for entry in "${category_array[@]}"; do
      local ext_id="$(get_extension_id "$entry")"
      local ext_name="$(get_extension_name "$entry")"
      if is_extension_installed "$ext_id"; then
        echo "✓ $ext_name already installed — skipping."
        ALREADY_INSTALLED+=("$ext_id")
      else
        if prompt_yes "Install $ext_name?"; then
          SELECTED_TO_INSTALL+=("$ext_id")
        fi
      fi
    done
  else
    # None installed, ask about the whole category
    if prompt_yes "Install all $category_name?"; then
      for entry in "${category_array[@]}"; do
        local ext_id="$(get_extension_id "$entry")"
        SELECTED_TO_INSTALL+=("$ext_id")
      done
    fi
  fi
}

# ---- Run interactive selection ----
echo
echo "Checking installed VSCode extensions and selecting what to install..."

check_and_select_category "Core Development Extensions" CORE_EXTENSIONS
check_and_select_category "Git & Version Control Extensions" GIT_EXTENSIONS  
check_and_select_category "Theme & UI Extensions" THEME_EXTENSIONS
check_and_select_category "React & Frontend Extensions" REACT_EXTENSIONS
check_and_select_category "Development Tools Extensions" DEV_TOOLS_EXTENSIONS

# ---- Install selected extensions ----
INSTALLED_EXTENSIONS=("${ALREADY_INSTALLED[@]}")
if ((${#SELECTED_TO_INSTALL[@]})); then
  echo
  echo "Installing selected extensions..."
  for ext_id in "${SELECTED_TO_INSTALL[@]}"; do
    echo "Installing $ext_id..."
    if code --install-extension "$ext_id" >/dev/null 2>&1; then
      echo "✓ $ext_id installed successfully."
      INSTALLED_EXTENSIONS+=("$ext_id")
    else
      echo "✗ Failed to install $ext_id."
      FAILED_EXTENSIONS+=("$ext_id")
    fi
  done
else
  echo
  echo "No additional extensions selected for installation."
fi

# ---- Summary ----
echo
echo "=== Summary ==="
echo "Extensions already installed: ${#ALREADY_INSTALLED[@]}"
echo "Extensions newly installed: $((${#INSTALLED_EXTENSIONS[@]} - ${#ALREADY_INSTALLED[@]}))"
if ((${#FAILED_EXTENSIONS[@]})); then
  echo "Extensions that failed to install: ${#FAILED_EXTENSIONS[@]}"
  for ext in "${FAILED_EXTENSIONS[@]}"; do
    echo "  - $ext"
  done
fi

echo
echo "vs_code.sh completed successfully."
