#!/usr/bin/env bash
# scripts/terminal_defaults.sh
# Robust, idempotent terminal setup for macOS (Apple Silicon–safe)
# - Ensures Oh My Zsh, Starship, Nerd Font, and popular zsh plugins
# - Uses Homebrew casks for fonts (no manual ZIPs)
# - Leaves existing configs intact; only appends when missing

set -euo pipefail

log() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- Ensure Homebrew is available (in case this runs standalone) --------------
if ! have brew; then
  log "Homebrew not found. Please run apps.sh first or install Homebrew."
  exit 1
fi
# Load brew env for this session (safe if already set)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || true)"

# --- Make sure the user's default shell is zsh (don't force, just hint) ------
if [[ "${SHELL:-}" != "/bin/zsh" ]]; then
  log "Note: Default shell is not zsh (current: ${SHELL:-unknown})."
  log "You can switch with: chsh -s /bin/zsh"
fi

# --- Oh My Zsh (idempotent) ---------------------------------------------------
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh..."
  CHSH=no RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh already installed."
fi

# --- Starship prompt via Homebrew (idempotent) --------------------------------
if have starship; then
  log "Starship already installed."
else
  log "Installing Starship prompt..."
  brew install starship || log "Warning: Failed to install Starship."
fi

# --- Fonts tap (idempotent) ---------------------------------------------------
if brew tap | grep -q '^homebrew/cask-fonts$'; then
  log "homebrew/cask-fonts already tapped."
else
  brew tap homebrew/cask-fonts || true
fi

# --- Meslo Nerd Font via Homebrew cask (idempotent) ---------------------------
if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
  log "Meslo Nerd Font already installed."
else
  log "Installing Meslo Nerd Font..."
  if brew install --cask font-meslo-lg-nerd-font; then
    log "Meslo Nerd Font installed."
  else
    log "Warning: Failed to install Meslo Nerd Font."
  fi
fi

# --- Starship config with Nerd Font symbols (create if missing) ---------------
mkdir -p "$HOME/.config"
STAR_CFG="$HOME/.config/starship.toml"
if [[ ! -f "$STAR_CFG" ]]; then
  if have starship; then
    log "Creating Starship config with Nerd Font symbols preset..."
    if ! starship preset nerd-font-symbols -o "$STAR_CFG"; then
      log "Preset generation failed; writing a minimal config."
      cat > "$STAR_CFG" <<'EOF'
# Minimal Starship config using Nerd Font symbols
format = """
$all\
"""

[character]
success_symbol = "➜ "
error_symbol = "✗ "

[git_branch]
symbol = " "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold yellow"
EOF
    fi
  else
    log "Starship not available to generate preset; skipping config."
  fi
else
  log "Starship config exists at $STAR_CFG — leaving it unchanged."
fi

# --- Ensure Starship initializes in zsh ---------------------------------------
ZSHRC="$HOME/.zshrc"
if ! grep -q 'eval "\$\(starship init zsh\)"' "$ZSHRC" 2>/dev/null; then
  log "Adding Starship init to ~/.zshrc"
  {
    echo ''
    echo '# Starship prompt'
    echo 'eval "$(starship init zsh)"'
  } >> "$ZSHRC"
else
  log "Starship init already present in ~/.zshrc"
fi

# --- zsh plugins: zsh-syntax-highlighting, zsh-autosuggestions ----------------
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# zsh-syntax-highlighting
if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/.git" ]]; then
  log "Updating zsh-syntax-highlighting..."
  git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" fetch --quiet || true
  git -C "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" pull --ff-only --quiet || true
elif [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  log "zsh-syntax-highlighting already present."
else
  log "Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# zsh-autosuggestions
if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions/.git" ]]; then
  log "Updating zsh-autosuggestions..."
  git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" fetch --quiet || true
  git -C "$ZSH_CUSTOM/plugins/zsh-autosuggestions" pull --ff-only --quiet || true
elif [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  log "zsh-autosuggestions already present."
else
  log "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# Ensure plugins are enabled in ~/.zshrc (append if missing)
ensure_plugin_in_zshrc() {
  local plugin="$1"
  if grep -E '^\s*plugins=\(' "$ZSHRC" >/dev/null 2>&1; then
    if grep -E "^\s*plugins=\(.*\b${plugin}\b.*\)" "$ZSHRC" >/dev/null 2>&1; then
      return 0
    fi
    # Add plugin to existing plugins=(...) line
    log "Enabling $plugin in ~/.zshrc plugins list."
    perl -0777 -pe 's/^\s*plugins=\(([^)]*)\)/"plugins=(".$1." '"$plugin"')"/se' -i "$ZSHRC"
  else
    # No plugins line found; create one
    log "Creating plugins list with $plugin in ~/.zshrc."
    {
      echo ''
      echo 'plugins=('"$plugin"')'
    } >> "$ZSHRC"
  fi
}

ensure_plugin_in_zshrc "git"
ensure_plugin_in_zshrc "zsh-syntax-highlighting"
ensure_plugin_in_zshrc "zsh-autosuggestions"

# --- Helpful hints ------------------------------------------------------------
log "If icons look wrong, set your terminal font to a Nerd Font:"
log "  iTerm2 → Preferences → Profiles → Text → Font → MesloLGS Nerd Font (Mono)"
log "  Apple Terminal → Preferences → Profiles → Text → Change… → MesloLGS Nerd Font"
log "Reload your shell when done:  exec zsh -l"

log "terminal_defaults.sh completed."
